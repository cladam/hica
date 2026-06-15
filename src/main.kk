/*
 * hica – compiler entry point
 * 
 * This source file is part of the hica open source project
 * Copyright (C) 2026 Claes Adamsson <claes.adamsson@gmail.com>
 *
 * See https://github.com/cladam/hica/blob/main/LICENSE for license information
*/
module main

import std/os/env
import std/os/dir
import std/os/file
import std/os/path
import std/os/process
import std/os/readline

import syntax/ast
import syntax/lexer
import syntax/parser
import diagnostics/diagnostics
import semantics/checker
import emit/codegen
import emit/codegen-js
import emit/codegen-js-repl
import repl-docs
import transform/desugar
import format/formatter
import klap
import prelude-bundle
import stdlib-bundle
import deps

val version = "0.36.0" 

// Clean process exit without throwing exceptions
extern hica-exit( code : int ) : a
  c inline "(exit(kk_integer_clamp32(#1, kk_context())), kk_box_null())"

// Flush stdout immediately — needed so Koka's buffered print() calls
// appear before subsequent run-system() writes to the same fd.
extern flush-stdout() : io ()
  c inline "fflush(stdout)"

// Check if stdin is a terminal (not piped/redirected)
fun stdin-isatty()
  if is-windows() then False
  else run-system("test -t 0" ++ dev-null()) == 0

// ---------------------------------------------------------------------------
// Persistent Node.js subprocess for REPL evaluation
// ---------------------------------------------------------------------------
extern import
  c file "node-subprocess-inline.c"

extern node-start( script : string ) : io int
  c "kk_hica_node_start"

extern node-send-line( line : string ) : io ()
  c "kk_hica_node_send_line"

extern node-read-line() : io string
  c "kk_hica_node_read_line"

extern node-stop() : io ()
  c "kk_hica_node_stop"

extern node-alive() : io bool
  c "kk_hica_node_alive"

// Pipe mode flag: true when persistent subprocess is available
extern repl-pipe-mode() : io bool
  c "kk_hica_pipe_mode"

extern set-pipe-mode( v : bool ) : io ()
  c "kk_hica_set_pipe_mode"

// Fallback JS accumulator (preamble + defs for file-based REPL)
extern fallback-js() : io string
  c "kk_hica_fallback_js"

extern fallback-js-clear() : io ()
  c "kk_hica_fallback_js_clear"

extern fallback-js-append( s : string ) : io ()
  c "kk_hica_fallback_js_append"

// Node.js server script: persistent evaluation context using vm module
val node-repl-script = "const vm=require('vm');" ++
  "const ctx=vm.createContext({console,process,require,setTimeout,clearTimeout,Buffer,global:globalThis});" ++
  "const rl=require('readline').createInterface({input:process.stdin,terminal:false});" ++
  "let buf='';" ++
  "rl.on('line',(ln)=>{" ++
    "if(ln==='__HICA_EVAL_END__'){" ++
      "try{vm.runInContext(buf,ctx)}catch(e){process.stdout.write('__HICA_ERROR__'+e.message+'\\n')}" ++
      "process.stdout.write('__HICA_EVAL_DONE__\\n');" ++
      "buf=''}" ++
    "else{buf+=ln+'\\n'}" ++
  "});"

// Write .kk only if content changed — preserves Koka's build cache.
// Silent: callers emit their own progress.
fun write-kk-if-changed( out-kk : path, koka-code : string, _hc-file : string )
  if is-file(out-kk) then
    val existing = read-text-file(out-kk)
    if existing != koka-code then
      write-text-file(out-kk, koka-code)
    elif !is-windows() then
      // Content unchanged — touch the file to update its timestamp so that
      // kk-is-fresh (test -nt) passes on subsequent runs and the module is skipped.
      val _ = run-system("touch " ++ out-kk.show)
      ()
  else
    write-text-file(out-kk, koka-code)

// Delete a generated .kk file (silently, idempotent) and invalidate koka's .kki cache.
// Koka stores interface files in .koka/v*/<hash>/ and encodes underscores as __ in filenames.
fun delete-kk( p : path ) : io ()
  if is-file(p) then
    val _ = run-system((if is-windows() then "del " else "rm -f ") ++ p.show)
    if !is-windows() then
      // Remove matching .kki from all koka cache hash dirs so stale interfaces don't
      // cause "unable to read" / "no corresponding source module" errors on next run.
      val stem = p.stemname
      val koka-stem = stem.replace-all("_", "__")  // koka encodes _ as __ in cache names
      val _ = run-system("rm -f .koka/v*/*/" ++ stem ++ ".kki .koka/v*/*/" ++ koka-stem ++ ".kki 2>/dev/null")
      ()

// Detect Windows via the OS environment variable (set to "Windows_NT" on Windows)
fun is-windows()
  get-env-value("OS").default("").starts-with("Windows").bool

// OS-appropriate binary extension
fun exe-ext()
  if is-windows() then ".exe" else ""

// OS-appropriate null redirection
fun dev-null()
  if is-windows() then " >NUL 2>&1" else " >/dev/null 2>&1"

fun hica-cli() : command
  command("hica")
    .version(version)
    .about("The hica compiler")
    .arg(positional("COMMAND").help("Command to run").required)
    .arg(positional("FILE").help("Source .hc file"))
    .arg(flag("check").help("Check formatting without modifying the file"))
    .arg(flag("cache").help("Remove the stdlib cache (~/.hica/stdlib)"))
    .arg(flag("generate").help("Keep generated .kk files after compilation"))
    .arg(option("target").help("Output target: koka (default) or js"))
    .arg(option-short("output", 'o').help("Output binary name (build only)"))
    .subcommand("build, b", "Compile a .hc file and build a binary")
    .subcommand("run, r", "Compile and run a .hc file")
    .subcommand("check, c", "Analyse a .hc file and report errors")
    .subcommand("fmt, f", "Format a .hc file")
    .subcommand("clean", "Remove generated build artifacts")
    .subcommand("test, t", "Run tests in a .hc file")
    .subcommand("new", "Create a new hica project")
    .subcommand("init", "Initialise a hica project in the current directory")
    .subcommand("add", "Add a dependency")
    .subcommand("remove", "Remove a dependency")
    .subcommand("fetch", "Fetch all dependencies")
    .subcommand("repl", "Start an interactive REPL")
    .subcommand("help", "Show help for a command")

fun build-cli() : command
  command("hica build")
    .about("Compile a .hc file and build a binary")
    .arg(positional("FILE").help("Source .hc file").required)
    .arg(option-short("output", 'o').help("Output binary name"))
    .arg(flag("generate").help("Keep generated .kk files after compilation"))

fun run-cli() : command
  command("hica run")
    .about("Compile and run a .hc file")
    .arg(positional("FILE").help("Source .hc file").required)
    .arg(flag("generate").help("Keep generated .kk files after compilation"))

fun check-cli() : command
  command("hica check")
    .about("Analyse a .hc file and report errors")
    .arg(positional("FILE").help("Source .hc file").required)

fun clean-cli() : command
  command("hica clean")
    .about("Remove generated build artifacts")
    .arg(positional("FILE").help("Source .hc file"))
    .arg(flag("cache").help("Remove the stdlib cache (~/.hica/stdlib)"))

fun fmt-cli() : command
  command("hica fmt")
    .about("Format a .hc file")
    .arg(positional("FILE").help("Source .hc file").required)
    .arg(flag("check").help("Check formatting without modifying the file"))

fun test-cli() : command
  command("hica test")
    .about("Run tests in a .hc file")
    .arg(positional("FILE").help("Source .hc file").required)

fun new-cli() : command
  command("hica new")
    .about("Create a new hica project")
    .arg(positional("NAME").help("Project name").required)

fun init-cli() : command
  command("hica init")
    .about("Initialise a hica project in the current directory")

fun add-cli() : command
  command("hica add")
    .about("Add a dependency")
    .arg(positional("SPEC").help("Dependency: host/owner/repo@tag or path:../dir").required)

fun remove-cli() : command
  command("hica remove")
    .about("Remove a dependency")
    .arg(positional("NAME").help("Dependency name to remove").required)

fun fetch-cli() : command
  command("hica fetch")
    .about("Fetch all dependencies")

// Split a list at the first "--" element. Returns (before, after).
fun split-at-double-dash( args : list<string> ) : (list<string>, list<string>)
  match args
    Nil -> ([], [])
    Cons("--", rest) -> ([], rest)
    Cons(a, rest) ->
      val (before, after) = split-at-double-dash(rest)
      (Cons(a, before), after)

fun main()
  main-cli(get-args())

fun main-cli( raw-args : list<string> )
  val (hica-args, user-args) = split-at-double-dash(raw-args)
  val m = hica-cli().parse-or-exit(hica-args)
  val cmd  = m.get-one-or("COMMAND", "")
  val file = m.get-one("FILE")
  match cmd
    "help"  -> cmd-help(file)
    "new"   -> cmd-new(file)
    "init"  -> cmd-init()
    "add"   -> cmd-add(file)
    "remove" -> cmd-remove(file)
    "fetch" -> cmd-fetch()
    "repl"  -> cmd-repl-with-file(file)
    "clean" -> cmd-clean(file, m.get-flag("cache"))
    _ ->
      val resolved = match file
        Just(f) -> Just(f)
        Nothing -> resolve-entry()
      match resolved
        Just(f) ->
          val target = m.get-one-or("target", "koka")
          val output = m.get-one("output")
          match cmd
            "build" -> cmd-build(f, target, output, m.get-flag("generate"))
            "b"     -> cmd-build(f, target, output, m.get-flag("generate"))
            "run"   -> cmd-run(f, user-args, m.get-flag("generate"))
            "r"     -> cmd-run(f, user-args, m.get-flag("generate"))
            "check" -> cmd-check(f)
            "c"     -> cmd-check(f)
            "fmt"   -> cmd-fmt(f, m.get-flag("check"))
            "f"     -> cmd-fmt(f, m.get-flag("check"))
            "test"  -> cmd-test(f)
            "t"     -> cmd-test(f)
            other   ->
              println("error: no such command: `" ++ other ++ "`\n")
              println(hica-cli().format-help)
        Nothing ->
          println("error: missing file argument (no hica.hml found)")
          println("Usage: hica " ++ cmd ++ " <FILE>")

// ---------------------------------------------------------------------------
// Commands
// ---------------------------------------------------------------------------

fun cmd-build( file : string, target : string = "koka", output : maybe<string> = Nothing, generate : bool = False )
  if target == "js" then
    build-js(file)
  else
    val (extra-includes, koka-flags) = read-manifest-koka(file.path.dirname)
    val dep-includes = resolve-dep-includes()
    val _ = build(file, extra-includes=dep-includes ++ extra-includes, koka-flags=koka-flags, output=output, generate=generate)
    ()

// Build to JavaScript: lex → parse → check → emit JS
fun build-js( file : string )
  val stem = file.path.stemname
  val mod-name = safe-module-name(stem)
  val dir  = file.path.dirname
  val source = read-text-file(file.path)
  val tokens = lex(source)
  val prog   = run-parser-program(tokens, source)
  val prelude = load-prelude()
  val (imported-decls, imported-structs, imported-types, _, _) = compile-imports(prog.imports, dir.path, [file])
  val ext-env = collect-extern-env(prog.imports, dir.path)
  val merged = Program(prelude.structs ++ imported-structs ++ prog.structs,
                       types = prelude.types ++ imported-types ++ prog.types,
                       decls = prelude.decls ++ imported-decls ++ prog.decls,
                       globals = prog.globals,
                       imports = prog.imports)
  val desugared = desugar-program(merged)
  val skip-decls = prelude.decls.length + imported-decls.length
  val skip-structs = prelude.structs.length + imported-structs.length
  val skip-types = prelude.types.length + imported-types.length
  val (typed-prog, diags) = collect-diagnostics
    run-fresh
      check-program(desugared, skip-decls, skip-structs, skip-types, extra-extern = ext-env)
  val errors = diags.filter(fn(d) match d.severity { Error -> True; _ -> False })
  if !errors.is-empty then
    errors.foreach(fn(d) println(render-diagnostic(source, file, d)))
    println("build: " ++ errors.length.show ++ " type error(s)")
  else
    // Strip imported decls/structs/types (same as build)
    val prelude-count = prelude.decls.length
    val imported-count = imported-decls.length
    val user-typed-decls = typed-prog.decls.drop(prelude-count + imported-count)
    val prelude-struct-count = prelude.structs.length
    val imported-struct-count = imported-structs.length
    val user-structs = typed-prog.structs.drop(prelude-struct-count + imported-struct-count)
    val prelude-type-count = prelude.types.length
    val imported-type-count = imported-types.length
    val user-types = typed-prog.types.drop(prelude-type-count + imported-type-count)
    val user-prog = typed-prog(decls = user-typed-decls, structs = user-structs, types = user-types, imports = prog.imports)
    val js-code = emit-js-program(user-prog, mod-name)
    val out-js = dir.path / (mod-name ++ ".js").path
    write-text-file(out-js, js-code)
    println("compiled " ++ file ++ " -> " ++ out-js.show ++ " (js)")

fun cmd-run( file : string, user-args : list<string>, generate : bool = False )
  val (extra-includes, koka-flags) = read-manifest-koka(file.path.dirname)
  val dep-includes = resolve-dep-includes()
  val ok = build(file, opt-level="0", extra-includes=dep-includes ++ extra-includes, koka-flags=koka-flags, generate=generate)
  if ok then
    run-koka(file, user-args)
  else
    println("aborted: not running stale executable because compilation failed")

fun cmd-check( file : string )
  val source = read-text-file(file.path)
  val tokens = lex(source)
  val prog   = run-parser-program(tokens, source)
  val dir    = file.path.dirname
  val prelude = load-prelude()
  val (imported-decls, imported-structs, imported-types, _, _) = compile-imports(prog.imports, dir.path, [file])
  val ext-env = collect-extern-env(prog.imports, dir.path)
  val merged = Program(prelude.structs ++ imported-structs ++ prog.structs,
                       types = prelude.types ++ imported-types ++ prog.types,
                       decls = prelude.decls ++ imported-decls ++ prog.decls,
                       globals = prog.globals)
  val desugared = desugar-program(merged)
  val skip-decls = prelude.decls.length + imported-decls.length
  val skip-structs = prelude.structs.length + imported-structs.length
  val skip-types = prelude.types.length + imported-types.length
  val (_typed-prog, diags) = collect-diagnostics
    run-fresh
      check-program(desugared, skip-decls, skip-structs, skip-types, extra-extern = ext-env)
  val warnings = diags.filter(fn(d) match d.severity { Warning -> True; _ -> False })
  val errors = diags.filter(fn(d) match d.severity { Error -> True; _ -> False })
  warnings.foreach(fn(d) println(render-diagnostic(source, file, d)))
  if errors.is-empty then
    val effects = discover-effects(prog)
    val effect-str = if effects.is-empty then "pure"
                     else "<" ++ effects.join(", ") ++ ">"
    println("check: " ++ file ++ " — ok (" ++ prog.decls.length.show ++ " declarations, 0 errors) [" ++ effect-str ++ "]")
  else
    errors.foreach(fn(d) println(render-diagnostic(source, file, d)))
    println("check: " ++ file ++ " — " ++ errors.length.show ++ " error(s)")

fun cmd-fmt( file : string, check-only : bool )
  val source    = read-text-file(file.path)
  val formatted = format-source(source)
  if check-only then
    if source == formatted then
      println("fmt: " ++ file ++ " — ok")
    else
      println("fmt: " ++ file ++ " — needs formatting")
      hica-exit(1)
  else
    if source == formatted then
      println("fmt: " ++ file ++ " — unchanged")
    else
      write-text-file(file.path, formatted)
      println("fmt: " ++ file ++ " — formatted")

fun cmd-test( file : string )
  val (extra-includes, koka-flags) = read-manifest-koka(file.path.dirname)
  val dep-includes = resolve-dep-includes()
  val stem = file.path.stemname
  val mod-name = safe-module-name(stem)
  val dir  = file.path.dirname
  val source = read-text-file(file.path)
  val tokens = lex(source)
  val prog   = run-parser-program(tokens, source)
  if prog.tests.is-empty then
    println("no tests found in " ++ file)
  else
    // Load prelude and merge
    val prelude = load-prelude()
    val (imported-decls, imported-structs, imported-types, imported-names, _) = compile-imports(prog.imports, dir.path, [file])
    val ext-env = collect-extern-env(prog.imports, dir.path)
    val merged = Program(prelude.structs ++ imported-structs ++ prog.structs,
                         types = prelude.types ++ imported-types ++ prog.types,
                         decls = prelude.decls ++ imported-decls ++ prog.decls,
                         globals = prog.globals,
                         tests = prog.tests)
    // Desugar
    val desugared = desugar-program(merged)
    // Type check
    val skip-decls = prelude.decls.length + imported-decls.length
    val skip-structs = prelude.structs.length + imported-structs.length
    val skip-types = prelude.types.length + imported-types.length
    val (typed-prog, diags) = collect-diagnostics
      run-fresh
        check-program(desugared, skip-decls, skip-structs, skip-types, extra-extern = ext-env)
    val warnings = diags.filter(fn(d) match d.severity { Warning -> True; _ -> False })
    val errors = diags.filter(fn(d) match d.severity { Error -> True; _ -> False })
    warnings.foreach(fn(d) println(render-diagnostic(source, file, d)))
    if !errors.is-empty then
      errors.foreach(fn(d) println(render-diagnostic(source, file, d)))
      println("test: " ++ errors.length.show ++ " type error(s)")
    else
      // Strip imported types/structs from the program before emission
      val prelude-count = prelude.decls.length
      val imported-count = imported-decls.length
      val user-typed-decls = typed-prog.decls.take(prelude-count) ++ typed-prog.decls.drop(prelude-count + imported-count)
      val prelude-struct-count = prelude.structs.length
      val imported-struct-count = imported-structs.length
      val user-structs = typed-prog.structs.take(prelude-struct-count) ++ typed-prog.structs.drop(prelude-struct-count + imported-struct-count)
      val prelude-type-count = prelude.types.length
      val imported-type-count = imported-types.length
      val user-types = typed-prog.types.take(prelude-type-count) ++ typed-prog.types.drop(prelude-type-count + imported-type-count)
      val user-prog = typed-prog(decls = user-typed-decls, structs = user-structs, types = user-types, imports = prog.imports, tests = prog.tests)
      val koka-code = emit-test-program(user-prog, mod-name, imported-names = imported-names, extra-effectful = collect-extern-effectful(prog.imports, dir.path), extra-imports = collect-extern-kk-modules(prog.imports, dir.path))
      val out-kk  = dir.path / (mod-name ++ ".kk").path
      write-kk-if-changed(out-kk, koka-code, file)
      val inc-dirs = import-dirs(prog.imports, dir.path) ++ dep-includes ++ extra-includes
      val ok = compile-koka(file, mod-name, inc-dirs, "0", koka-flags)
      if ok then
        run-tests(file)
      else
        println("aborted: not running stale test executable because compilation failed")

fun cmd-clean( file : maybe<string>, cache : bool = False )
  if cache then
    val stdlib-dir = hica-stdlib-dir()
    if is-directory(stdlib-dir) then
      val rm-cmd = if is-windows() then "rd /s /q " else "rm -rf "
      val _ = run-system(rm-cmd ++ stdlib-dir.show)
      println("removed " ++ stdlib-dir.show)
    else
      println("nothing to clean (stdlib cache not present)")
  else
    val resolved = match file
      Just(_) -> file
      Nothing -> resolve-entry()
    match resolved
      Nothing ->
        println("error: missing file argument (no hica.hml found)")
        println("Usage: hica clean [--cache] <FILE>")
      Just(f) ->
        val stem = f.path.stemname
        val mod-name = safe-module-name(stem)
        val dir  = f.path.dirname
        val kk-file = dir.path / (mod-name ++ ".kk").path
        val bin-file = dir.path / (mod-name ++ exe-ext()).path
        var cleaned := False
        if is-file(kk-file) then
          val contents = read-text-file(kk-file)
          if contents.starts-with("// Generated by hica").bool then
            val rm-cmd = if is-windows() then "del " else "rm -f "
            val _ = run-system(rm-cmd ++ kk-file.show)
            println("removed " ++ kk-file.show)
            cleaned := True
          else
            println("skipping " ++ kk-file.show ++ " (not generated by hica)")
        if is-file(bin-file) && cleaned then
          val rm-cmd = if is-windows() then "del " else "rm -f "
          val _ = run-system(rm-cmd ++ bin-file.show)
          println("removed " ++ bin-file.show)
        if !cleaned then
          println("nothing to clean")

fun cmd-new( name-arg : maybe<string> )
  match name-arg
    Nothing ->
      println("error: missing project name")
      println(new-cli().format-help)
    Just(name) ->
      val project-dir = name.path
      if is-directory(project-dir) then
        println("error: directory '" ++ name ++ "' already exists")
      else
        ensure-dir(project-dir)
        scaffold-project(project-dir, project-dir.stemname)

fun cmd-init()
  val manifest = "hica.hml".path
  if is-file(manifest) then
    println("error: hica.hml already exists in this directory")
  else
    val name = cwd().stemname
    scaffold-project(".".path, name)

fun cmd-add( spec-arg : maybe<string> )
  match spec-arg
    Nothing ->
      println("error: missing dependency spec")
      println(add-cli().format-help)
    Just(spec) ->
      if !is-file(manifest-name.path) then
        println("error: no hica.hml found (run 'hica init' first)")
      else
        val dep = parse-dep-spec(spec)
        val content = read-text-file(manifest-name.path)
        val existing = parse-deps-section(content)
        if existing.any(fn(d) d.name == dep.name) then
          println("error: dependency '" ++ dep.name ++ "' already exists (remove it first)")
        else
          val new-content = add-dep-to-hml(content, dep)
          write-text-file(manifest-name.path, new-content)
          println("added " ++ format-dep(dep).trim)
          match fetch-dep(dep, ".".path)
            Just(_) -> ()
            Nothing -> ()

fun cmd-remove( name-arg : maybe<string> )
  match name-arg
    Nothing ->
      println("error: missing dependency name")
      println(remove-cli().format-help)
    Just(dep-name) ->
      if !is-file(manifest-name.path) then
        println("error: no hica.hml found")
      else
        val content = read-text-file(manifest-name.path)
        val existing = parse-deps-section(content)
        if !existing.any(fn(d) d.name == dep-name) then
          println("error: dependency '" ++ dep-name ++ "' not found")
        else
          val new-content = remove-dep-from-hml(content, dep-name)
          write-text-file(manifest-name.path, new-content)
          println("removed " ++ dep-name)

fun cmd-fetch()
  if !is-file(manifest-name.path) then
    println("error: no hica.hml found")
  else
    val content = read-text-file(manifest-name.path)
    val dep-list = parse-deps-section(content)
    if dep-list.is-nil then
      println("no dependencies")
    else
      val paths = fetch-all-deps(dep-list, ".".path)
      println("fetched " ++ paths.length.show ++ " dependencies")

// Resolve dependency include paths from hica.ini [dependencies] section
fun resolve-dep-includes()
  if is-file(manifest-name.path) then
    val content = read-text-file(manifest-name.path)
    val dep-list = parse-deps-section(content)
    if dep-list.is-nil then []
    else fetch-all-deps(dep-list, ".".path)
  else []

fun scaffold-project( project-dir : path, name : string )
  val main-file  = project-dir / "main.hc".path
  val manifest   = project-dir / "hica.hml".path
  val readme     = project-dir / "README.md".path
  val main-content = [
    "fun main() {",
    "  println(\"hello from " ++ name ++ "\")",
    "}"
  ].join("\n") ++ "\n"
  val manifest-content = [
    "@project {",
    "    name: \"" ++ name ++ "\"",
    "    version: \"0.1.0\"",
    "    license: \"MIT\"",
    "    entry: \"main.hc\"",
    "}",
    "",
    "@dependencies {",
    "}",
    "",
    "@description {",
    "    summary: \"A hica project\"",
    "    author: \"\"",
    "    homepage: \"\"",
    "    repository: \"\"",
    "}"
  ].join("\n") ++ "\n"
  val readme-content = [
    "# " ++ name,
    "",
    "## Usage",
    "",
    "```sh",
    "hica build   # compile to binary",
    "hica run     # compile and run",
    "hica fmt     # format according to hica style guide",
    "hica check   # type-check without emitting",
    "hica clean   # remove generated files",
    "```"
  ].join("\n") ++ "\n"
  write-text-file(main-file, main-content)
  write-text-file(manifest, manifest-content)
  write-text-file(readme, readme-content)
  println("created project '" ++ name ++ "'")
  println("  " ++ manifest.show)
  println("  " ++ main-file.show)
  println("  " ++ readme.show)

fun cmd-help( sub : maybe<string> )
  match sub
    Just("build") -> println(build-cli().format-help)
    Just("b")     -> println(build-cli().format-help)
    Just("run")   -> println(run-cli().format-help)
    Just("r")     -> println(run-cli().format-help)
    Just("check") -> println(check-cli().format-help)
    Just("c")     -> println(check-cli().format-help)
    Just("fmt")   -> println(fmt-cli().format-help)
    Just("f")     -> println(fmt-cli().format-help)
    Just("clean") -> println(clean-cli().format-help)
    Just("test")  -> println(test-cli().format-help)
    Just("t")     -> println(test-cli().format-help)
    Just("new")   -> println(new-cli().format-help)
    Just("init")  -> println(init-cli().format-help)
    Just("add")   -> println(add-cli().format-help)
    Just("remove") -> println(remove-cli().format-help)
    Just("fetch") -> println(fetch-cli().format-help)
    _             -> print-usage()

// ---------------------------------------------------------------------------
// REPL: interactive Read-Eval-Print Loop using JS codegen + Node.js
// ---------------------------------------------------------------------------

struct repl-state
  decls   : list<fun-decl>
  structs : list<struct-def>
  types   : list<type-def>
  js-defs : string
  vals    : list<(string, node, maybe<hica-type>)>  // value bindings: (name, init-expr, type)

val empty-repl-state = Repl-state([], [], [], "", [])

// History file path
fun history-path() : io path
  homedir() / ".hica_history".path

// Startup file path
fun startup-path() : io path
  homedir() / ".hicarc".path

// Append a line to history file
fun history-append( line : string )
  val hp = history-path()
  val existing = if is-file(hp) then read-text-file(hp) else ""
  write-text-file(hp, existing ++ line ++ "\n")

fun cmd-repl()
  cmd-repl-with-file(Nothing)

// Completions file path for rlwrap (default location: ~/.rlwrap/hica_completions)
// rlwrap automatically reads this when wrapping a command named "hica"
fun completions-path() : io path
  val home = get-env-value("HOME").default("~")
  val rlwrap-dir = (home ++ "/.rlwrap").path
  ensure-dir(rlwrap-dir)
  (home ++ "/.rlwrap/hica_completions").path

// Write completions file with prelude names and REPL commands
fun write-completions( prelude : program )
  val prelude-names = prelude.decls.map(fn(d) d.name)
  val commands = [":help", ":h", ":doc", ":defs", ":reset", ":load", ":history", ":type", ":t", ":quit", ":q"]
  val keywords = ["fun", "let", "var", "if", "else", "match", "while", "for", "in", "repeat", "loop",
                  "break", "continue", "struct", "type", "true", "false", "None", "Some", "Ok", "Err",
                  "import", "pub", "return"]
  val topics = doc-topic-names()
  val all-words = commands ++ keywords ++ topics ++ prelude-names
  write-text-file(completions-path(), all-words.join("\n") ++ "\n")

// Auto-wrap with rlwrap for tab completion and history
fun try-rlwrap( file : maybe<string> )
  // Don't wrap if: not a tty, already wrapped, or rlwrap not available
  if !stdin-isatty() then return ()
  if get-env-value("HICA_RLWRAP").default("") != "" then return ()
  val check = run-system("which rlwrap" ++ dev-null())
  if check != 0 then return ()
  // Write completions file before launching rlwrap so it can read it
  val prelude = load-prelude()
  write-completions(prelude)
  val cp = completions-path()
  // Build rlwrap command with explicit -f and env guard to prevent re-entry
  val file-arg = match file
    Just(f) -> " " ++ f
    Nothing -> ""
  val exe = get-argv().head.default("hica")
  val rlwrap-cmd = "export HICA_RLWRAP=1 && rlwrap --always-readline --no-children -n -f " ++ cp.show ++ " " ++ exe ++ " repl" ++ file-arg
  val exit-code = run-system(rlwrap-cmd)
  if exit-code == 0 then hica-exit(0)
  // rlwrap failed — fall through to plain REPL

// ---------------------------------------------------------------------------
// REPL subprocess mode tracking
// ---------------------------------------------------------------------------

fun cmd-repl-with-file( file : maybe<string> )
  try-rlwrap(file)
  val is-wrapped = get-env-value("HICA_RLWRAP").default("") != ""
  println("hica " ++ version ++ " REPL (exit with Ctrl-D or :quit)")
  println("Type expressions, declarations (fun, let, struct, type), or :help")
  if !is-wrapped && stdin-isatty() then
    println("Tip: install rlwrap for tab completion and history")
  println("")
  // Start persistent Node.js subprocess
  val res = node-start(node-repl-script)
  if res != 0 then
    set-pipe-mode(False)
    fallback-js-clear()
  else
    set-pipe-mode(True)
  // Send runtime preamble
  repl-send-js(js-runtime-preamble() ++ "var _ = undefined;\n")
  val prelude = load-prelude()
  // Write completions file for manual rlwrap usage
  write-completions(prelude)
  // Load startup file (~/.hicarc) if it exists
  val state0 = repl-load-startup(prelude, empty-repl-state)
  // Load preloaded file (-i flag) if provided
  val state1 = match file
    Just(f) -> repl-load-file(f, prelude, state0)
    Nothing -> state0
  repl-loop(prelude, state1)
  if repl-pipe-mode() then node-stop()

// Load definitions from startup file
fun repl-load-startup( prelude : program, state : repl-state )
  val sp = startup-path()
  if is-file(sp) then
    println("  loading " ++ sp.show)
    val source = read-text-file(sp)
    val file-lines = source.lines.filter(fn(l) !l.trim.is-empty && !l.trim.starts-with("//").bool)
    repl-eval-lines(file-lines, prelude, state, silent = True)
  else
    state

// Load definitions from a .hc file
fun repl-load-file( filepath : string, prelude : program, state : repl-state )
  if is-file(filepath.path) then
    println("  loading " ++ filepath)
    val source = read-text-file(filepath.path)
    // Parse as full program, extract definitions
    val tokens = lex(source)
    val parsed = run-parser-program(tokens, source)
    val merged-prog = Program(prelude.structs ++ state.structs ++ parsed.structs,
                              types = prelude.types ++ state.types ++ parsed.types,
                              decls = prelude.decls ++ state.decls ++ parsed.decls)
    val desugared = desugar-program(merged-prog)
    val skip-n = prelude.decls.length + state.decls.length
    val (typed-prog, _diags) = collect-diagnostics
      run-fresh
        check-program(desugared, skip-n, prelude.structs.length + state.structs.length, prelude.types.length + state.types.length)
    // Emit JS for the file's declarations (skip main)
    val prelude-n = prelude.decls.length + state.decls.length
    val file-decls = typed-prog.decls.drop(prelude-n).filter(fn(d) d.name != "main")
    val file-structs = parsed.structs
    val file-types = parsed.types
    val js-structs = file-structs.map(fn(sd) emit-js-repl-struct(sd)).join("\n")
    val js-types = file-types.map(fn(td) emit-js-repl-type(td)).join("\n")
    val js-decls = file-decls.map(fn(d) emit-js-repl-decl(d)).join("\n")
    val js = js-structs ++ "\n" ++ js-types ++ "\n" ++ js-decls ++ "\n"
    val names = file-decls.map(fn(d) d.name)
    if !names.is-empty then
      println("  loaded: " ++ names.join(", "))
    // Send to persistent subprocess
    repl-send-js(js)
    state(decls = state.decls ++ file-decls,
          structs = state.structs ++ file-structs,
          types = state.types ++ file-types,
          js-defs = state.js-defs ++ js)
  else
    println("  error: file not found: " ++ filepath)
    state

// Evaluate multiple lines silently (for startup file)
fun repl-eval-lines( file-lines : list<string>, prelude : program, state : repl-state, silent : bool = False )
  match file-lines
    Nil -> state
    Cons(l, rest) ->
      val new-state = repl-eval(l, prelude, state, silent)
      repl-eval-lines(rest, prelude, new-state, silent)

fun repl-loop( prelude : program, state : repl-state )
  print("hica=> ")
  val result = try({ Just(readline()) }) fn(_exn) { Nothing }
  match result
    Nothing -> println("\nBye!")  // EOF (Ctrl-D or end of pipe)
    Just(input) ->
      val line = input.trim
      if line == ":quit" || line == ":q" then
        println("Bye!")
      elif line == ":help" || line == ":h" then
        repl-help()
        repl-loop(prelude, state)
      elif line == ":doc" then
        println(doc-topic-list())
        repl-loop(prelude, state)
      elif line.starts-with(":doc ").bool then
        val topic = line.slice.drop(5).string.trim
        match lookup-doc(topic)
          Just(text) -> println(text)
          Nothing -> println("  Unknown topic: " ++ topic ++ ". Type :doc for a list.")
        repl-loop(prelude, state)
      elif line == ":defs" then
        repl-show-defs(state)
        repl-loop(prelude, state)
      elif line == ":reset" then
        println("  state cleared")
        if repl-pipe-mode() then
          node-stop()
          val _res = node-start(node-repl-script)
          ()
        else
          fallback-js-clear()
        repl-send-js(js-runtime-preamble() ++ "var _ = undefined;\n")
        repl-loop(prelude, empty-repl-state)
      elif line == ":history" then
        repl-show-history()
        repl-loop(prelude, state)
      elif line.starts-with(":load ").bool then
        val filepath = line.slice.drop(6).string.trim
        val new-state = repl-load-file(filepath, prelude, state)
        repl-loop(prelude, new-state)
      elif line.starts-with(":type ").bool || line.starts-with(":t ").bool then
        val expr-str = if line.starts-with(":type ").bool then line.slice.drop(6).string.trim
                       else line.slice.drop(3).string.trim
        repl-type(expr-str, prelude, state)
        repl-loop(prelude, state)
      elif line.is-empty then
        repl-loop(prelude, state)
      else
        // Check for multiline (unbalanced braces/parens)
        val full-input = repl-read-multiline(line)
        history-append(full-input)
        val new-state = repl-eval(full-input, prelude, state)
        repl-loop(prelude, new-state)

// Multiline: if braces/parens/brackets are unbalanced, keep reading
fun repl-read-multiline( acc : string ) : <div,console,exn> string
  val balance = brace-balance(acc)
  if balance <= 0 then acc
  else
    print("...> ")
    val next = readline()
    if next == "" then acc  // EOF ends input
    else repl-read-multiline(acc ++ "\n" ++ next)

// Count unbalanced opening braces/parens/brackets
fun brace-balance( s : string ) : int
  var depth := 0
  s.list.foreach fn(c)
    if c == '{' || c == '(' || c == '[' then depth := depth + 1
    elif c == '}' || c == ')' || c == ']' then depth := depth - 1
  depth

fun repl-show-history()
  val hp = history-path()
  if is-file(hp) then
    val content = read-text-file(hp)
    val hist-lines = content.lines
    val recent = hist-lines.drop(max(0, hist-lines.length - 20))
    recent.foreach(fn(l) println("  " ++ l))
  else
    println("  (no history)")

fun repl-help()
  println("  :help, :h      Show this help")
  println("  :doc [TOPIC]   Browse language docs (topics, functions)")
  println("  :defs          Show current definitions")
  println("  :reset         Clear all definitions")
  println("  :load FILE     Load definitions from a .hc file")
  println("  :history       Show recent input history")
  println("  :type, :t EXPR Show the type of an expression")
  println("  :quit, :q      Exit the REPL")
  println("")
  println("  Expressions are evaluated and the result is printed:")
  println("    hica=> 1 + 2")
  println("    3")
  println("")
  println("  The _ variable holds the last expression result:")
  println("    hica=> 6 * 7")
  println("    42")
  println("    hica=> _ + 1")
  println("    43")
  println("")
  println("  Multiline input: open braces continue on the next line:")
  println("    hica=> fun fib(n: int) : int {")
  println("    ...>   if n <= 1 { n } else { fib(n - 1) + fib(n - 2) }")
  println("    ...>  }")
  println("    defined: fib")

fun repl-show-defs( state : repl-state )
  if state.decls.is-empty && state.structs.is-empty && state.types.is-empty then
    println("  (no definitions)")
  else
    state.structs.foreach(fn(s) println("  struct " ++ s.name))
    state.types.foreach(fn(t) println("  type " ++ t.name))
    state.decls.foreach(fn(d) println("  fun " ++ d.name ++ "(" ++ d.params.join(", ") ++ ")"))

fun repl-eval( input : string, prelude : program, state : repl-state, silent : bool = False )
  // Lex and parse as a REPL fragment
  val tokens = lex(input)
  val (fragment, parse-errors) = run-parser-repl-tracked(tokens, input)
  if parse-errors then return state
  match fragment
    ReplDecl(d) ->
      // Type check with accumulated context
      val merged = Program(prelude.structs ++ state.structs,
                           types = prelude.types ++ state.types,
                           decls = prelude.decls ++ state.decls ++ [d])
      val desugared = desugar-program(merged)
      val repl-skip = prelude.decls.length + state.decls.length
      val (typed-prog, diags) = collect-diagnostics
        run-fresh
          check-program(desugared, repl-skip)
      val errors = diags.filter(fn(dia) match dia.severity { Error -> True; _ -> False })
      if !errors.is-empty then
        errors.foreach(fn(dia) println(render-diagnostic(input, "<repl>", dia)))
        state
      else
        // Emit JS, send to subprocess, and accumulate
        val typed-decl = typed-prog.decls.last.default(d)
        val js = emit-js-repl-decl(typed-decl)
        repl-send-js(js)
        if !silent then println("  defined: " ++ d.name)
        state(decls = state.decls ++ [typed-decl], js-defs = state.js-defs ++ js ++ "\n")

    ReplStruct(sd) ->
      val js = emit-js-repl-struct(sd)
      repl-send-js(js)
      if !silent then println("  defined: struct " ++ sd.name)
      state(structs = state.structs ++ [sd], js-defs = state.js-defs ++ js ++ "\n")

    ReplType(td) ->
      val js = emit-js-repl-type(td)
      repl-send-js(js)
      if !silent then println("  defined: type " ++ td.name)
      state(types = state.types ++ [td], js-defs = state.js-defs ++ js ++ "\n")

    ReplImport(_id) ->
      println("  imports not yet supported in REPL")
      state

    ReplExpr(enode) ->
      // Detect top-level let binding → store as value decl
      match enode.expr
        Let(name, _ann, init, _body) ->
          repl-eval-let(name, init, prelude, state, silent)
        _ ->
          repl-eval-expr(enode, prelude, state)

// Evaluate a let binding in the REPL: store as a persistent value
fun repl-eval-let( binding-name : string, init : node, prelude : program, state : repl-state, silent : bool = False )
  // Type check init in context using a Let-chain wrapper
  val wrapped = wrap-with-vals(state.vals, init)
  val wrapper = Fun-decl(no-span, "__repl_expr", [], wrapped)
  val merged = Program(prelude.structs ++ state.structs,
                       types = prelude.types ++ state.types,
                       decls = prelude.decls ++ state.decls ++ [wrapper])
  val desugared = desugar-program(merged)
  val repl-skip = prelude.decls.length + state.decls.length
  val (typed-prog, diags) = collect-diagnostics
    run-fresh
      check-program(desugared, repl-skip)
  val errors = diags.filter(fn(dia) match dia.severity { Error -> True; _ -> False })
  if !errors.is-empty then
    errors.foreach(fn(dia) println(render-diagnostic(init.show, "<repl>", dia)))
    state
  else
    val typed-body = typed-prog.decls.last.default(wrapper).body
    val typed-init = unwrap-vals(state.vals, typed-body)
    val init-type = typed-init.typ
    val js = "var " ++ binding-name ++ " = " ++ emit-js-expr(typed-init) ++ ";\n"
    val show-js = js ++ "if (" ++ binding-name ++ " !== undefined && " ++ binding-name ++ " !== null) { println(show(" ++ binding-name ++ ")); _ = " ++ binding-name ++ "; }\n"
    if !silent then repl-run-js(show-js)
    // Store binding and update _ to hold the let's init value
    val new-vals = state.vals.filter(fn((n, _v, _t)) n != binding-name && n != "_") ++ [(binding-name, init, init-type), ("_", init, init-type)]
    state(vals = new-vals, js-defs = state.js-defs ++ js)

// Show the type of an expression without evaluating it
fun repl-type( input : string, prelude : program, state : repl-state )
  val tokens = lex(input)
  val (fragment, parse-errors) = run-parser-repl-tracked(tokens, input)
  if parse-errors then return ()
  match fragment
    ReplExpr(enode) ->
      val expr = match enode.expr
        Let(_name, _ann, init, _body) -> init
        _ -> enode
      val wrapped = wrap-with-vals(state.vals, expr)
      val wrapper = Fun-decl(no-span, "__repl_expr", [], wrapped)
      val merged = Program(prelude.structs ++ state.structs,
                           types = prelude.types ++ state.types,
                           decls = prelude.decls ++ state.decls ++ [wrapper])
      val desugared = desugar-program(merged)
      val repl-skip = prelude.decls.length + state.decls.length
      val (typed-prog, diags) = collect-diagnostics
        run-fresh
          check-program(desugared, repl-skip)
      val errors = diags.filter(fn(dia) match dia.severity { Error -> True; _ -> False })
      if !errors.is-empty then
        errors.foreach(fn(dia) println(render-diagnostic(input, "<repl>", dia)))
      else
        val typed-body = typed-prog.decls.last.default(wrapper).body
        val typed-expr = unwrap-vals(state.vals, typed-body)
        match typed-expr.typ
          Just(t) -> println("  " ++ t.show)
          Nothing -> println("  (unknown type)")
    ReplDecl(d) ->
      // Type check to get inferred types
      val merged = Program(prelude.structs ++ state.structs,
                           types = prelude.types ++ state.types,
                           decls = prelude.decls ++ state.decls ++ [d])
      val desugared = desugar-program(merged)
      val repl-skip = prelude.decls.length + state.decls.length
      val (typed-prog, diags) = collect-diagnostics
        run-fresh
          check-program(desugared, repl-skip)
      val errors = diags.filter(fn(dia) match dia.severity { Error -> True; _ -> False })
      if !errors.is-empty then
        errors.foreach(fn(dia) println(render-diagnostic(input, "<repl>", dia)))
      else
        val typed-decl = typed-prog.decls.last.default(d)
        val param-strs = typed-decl.params.zip(typed-decl.param-types).map(fn((n, t)) n ++ ": " ++ t.show)
        val param-str = if param-strs.is-empty then typed-decl.params.join(", ") else param-strs.join(", ")
        val ret-str = match typed-decl.ret-type { Just(t) -> " : " ++ t.show; Nothing -> "" }
        println("  (" ++ param-str ++ ")" ++ ret-str)
    ReplStruct(sd) ->
      println("  struct " ++ sd.name)
    ReplType(td) ->
      println("  type " ++ td.name)
    ReplImport(_) ->
      println("  (import — no type info)")

// Evaluate a bare expression in the REPL
fun repl-eval-expr( expr : node, prelude : program, state : repl-state )
  val wrapped = wrap-with-vals(state.vals, expr)
  val wrapper = Fun-decl(no-span, "__repl_expr", [], wrapped)
  val merged = Program(prelude.structs ++ state.structs,
                       types = prelude.types ++ state.types,
                       decls = prelude.decls ++ state.decls ++ [wrapper])
  val desugared = desugar-program(merged)
  val repl-skip = prelude.decls.length + state.decls.length
  val (typed-prog, diags) = collect-diagnostics
    run-fresh
      check-program(desugared, repl-skip)
  val errors = diags.filter(fn(dia) match dia.severity { Error -> True; _ -> False })
  if !errors.is-empty then
    errors.foreach(fn(dia) println(render-diagnostic(expr.show, "<repl>", dia)))
    state
  else
    val typed-body = typed-prog.decls.last.default(wrapper).body
    val typed-expr = unwrap-vals(state.vals, typed-body)
    val expr-type = typed-expr.typ
    val js-snippet = emit-js-repl-expr(typed-expr)
    repl-run-js(js-snippet)
    // Store _ with TYPE for type checking; _ persists in subprocess
    val new-vals = state.vals.filter(fn((n, _v, _t)) n != "_") ++ [("_", expr, expr-type)]
    state(vals = new-vals)

// Wrap an expression in a chain of let bindings from value state
// For "_", use the stored init directly if it doesn't self-reference;
// otherwise use a type-appropriate dummy literal
fun wrap-with-vals( bindings : list<(string, node, maybe<hica-type>)>, body : node ) : div node
  match bindings
    Nil -> body
    Cons(("_", init, typ), rest) ->
      val safe-init = if contains-var(init, "_") then dummy-for-type(typ) else init
      Node(no-span, Let("_", Nothing, safe-init, wrap-with-vals(rest, body)))
    Cons((bname, init, _typ), rest) ->
      Node(no-span, Let(bname, Nothing, init, wrap-with-vals(rest, body)))

// Check if a node contains a reference to a given variable
fun contains-var( n : node, vname : string ) : div bool
  match n.expr
    Var(nm) -> nm == vname
    Binary(_op, l, r) -> contains-var(l, vname) || contains-var(r, vname)
    Unary(_op, e) -> contains-var(e, vname)
    Call(callee, args) -> contains-var(callee, vname) || args.any(fn(a) contains-var(a, vname))
    Let(_nm, _ann, init, bdy) -> contains-var(init, vname) || contains-var(bdy, vname)
    _ -> False

// Create a dummy literal for a given type
fun dummy-for-type( typ : maybe<hica-type> ) : node
  match typ
    Just(TInt) -> Node(no-span, Literal(LitInt(0)))
    Just(TFloat) -> Node(no-span, Literal(LitFloat("0.0")))
    Just(TString) -> Node(no-span, Literal(LitString("")))
    Just(TBool) -> Node(no-span, Literal(LitBool(False)))
    Just(TChar) -> Node(no-span, Literal(LitChar(" ")))
    _ -> Node(no-span, Literal(LitInt(0)))

// Unwrap a let-chain to get the innermost body
fun unwrap-vals( bindings : list<(string, node, maybe<hica-type>)>, wrapped : node ) : node
  match bindings
    Nil -> wrapped
    Cons(_, rest) ->
      match wrapped.expr
        Let(_n, _a, _i, inner) -> unwrap-vals(rest, inner)
        _ -> wrapped

// Send JS code to the persistent Node.js subprocess and print output
// Falls back to file-based execution when subprocess is not available (Windows)
fun repl-run-js( js-code : string )
  if repl-pipe-mode() then
    // Send each line, then the eval sentinel
    js-code.lines.foreach(fn(l) node-send-line(l))
    node-send-line("__HICA_EVAL_END__")
    // Read output lines until done sentinel
    repl-read-node-output()
  else
    // Fallback: write full JS (preamble + defs + snippet) to temp file and run node
    val full = fallback-js() ++ js-code
    val tmp-dir = if is-windows() then get-env-value("TEMP").default(".")
                  else "/tmp"
    val tmp-js = (tmp-dir ++ "/hica-repl-eval.js").path
    val tmp-out = (tmp-dir ++ "/hica-repl-out.txt").path
    write-text-file(tmp-js, full)
    val exit-code = run-system("node " ++ tmp-js.show ++ " > " ++ tmp-out.show ++ " 2>&1")
    if is-file(tmp-out) then
      val output = read-text-file(tmp-out).trim
      if !output.is-empty then println(output)

fun repl-read-node-output()
  val line = node-read-line()
  if line == "__HICA_EVAL_DONE__" then ()
  elif line == "" then ()  // EOF — subprocess died
  elif line.starts-with("__HICA_ERROR__").bool then
    println("  error: " ++ line.slice.drop(14).string)
    repl-read-node-output()
  else
    println(line)
    repl-read-node-output()

// Send JS code silently (no output reading — for preamble/defs sent at startup)
fun repl-send-js( js-code : string )
  if repl-pipe-mode() then
    js-code.lines.foreach(fn(l) node-send-line(l))
    node-send-line("__HICA_EVAL_END__")
    // Drain the DONE sentinel
    repl-drain-sentinel()
  else
    // Fallback: accumulate JS for file-based execution
    fallback-js-append(js-code ++ "\n")

fun repl-drain-sentinel()
  val line = node-read-line()
  if line == "__HICA_EVAL_DONE__" then ()
  elif line == "" then ()  // EOF
  else repl-drain-sentinel()

// ---------------------------------------------------------------------------
// Prelude: parse embedded .hc sources (bundled into the binary)
// ---------------------------------------------------------------------------

fun load-prelude()
  var decl-result : list<fun-decl> := []
  var struct-result : list<struct-def> := []
  var type-result : list<type-def> := []
  embedded-prelude-sources().foreach fn(source)
    val tokens = lex(source)
    val prog = run-parser-program(tokens, source)
    decl-result := decl-result ++ prog.decls
    struct-result := struct-result ++ prog.structs
    type-result := type-result ++ prog.types
  Program(struct-result, type-result, decl-result)

// ---------------------------------------------------------------------------
// Stdlib path: ~/.hica/stdlib — bundled modules extracted on demand
// ---------------------------------------------------------------------------

fun hica-stdlib-dir() : io path
  val home = if is-windows()
    then get-env-value("USERPROFILE").default(".")
    else get-env-value("HOME").default(".")
  (home ++ "/.hica/stdlib").path

fun find-stdlib-source( mod-path : string ) : maybe<string>
  match embedded-stdlib-sources().find(fn(pair) pair.fst == mod-path)
    Just(pair) -> Just(pair.snd)
    Nothing    -> Nothing

fun compile-stdlib-import( mod-path : string ) : io (list<fun-decl>, list<struct-def>, list<type-def>, list<string>)
  match find-stdlib-source(mod-path)
    Nothing ->
      println("error: unknown stdlib module: " ++ mod-path)
      ([], [], [], [])
    Just(source) ->
      val stdlib-dir = hica-stdlib-dir()
      ensure-dir(stdlib-dir)
      // Flatten: std/term → term.hc in stdlib-dir
      val stem = mod-path.path.stemname
      val hc-file = stdlib-dir / (stem ++ ".hc").path
      val kk-file = stdlib-dir / (stem ++ ".kk").path
      // Write .hc only if content changed (auto-invalidates stale .kk on binary update)
      val existing = if is-file(hc-file) then read-text-file(hc-file) else ""
      if existing != source then
        write-text-file(hc-file, source)
        if is-file(kk-file) then
          val rm-cmd = if is-windows() then "del " else "rm -f "
          val _ = run-system(rm-cmd ++ kk-file.show)
          ()
      // Compile stdlib module to .kk in stdlib-dir
      compile-module(hc-file, [hc-file.show])
      // Parse to collect pub declarations for the type checker
      val tokens = lex(source)
      val prog = run-parser-program(tokens, source)
      val pub-decls = prog.decls.filter(fn(d) d.is-pub)
      val pub-names = pub-decls.map(fn(d) d.name)
      (pub-decls, prog.structs, prog.types, pub-names)

// ---------------------------------------------------------------------------
// Build pipeline: read .hc → lex → parse → emit → write .kk
// ---------------------------------------------------------------------------

fun build( file : string, opt-level : string = "2", extra-includes : list<string> = [], koka-flags : string = "", output : maybe<string> = Nothing, generate : bool = False )
  val stem = file.path.stemname
  val mod-name = safe-module-name(stem)
  val dir  = file.path.dirname
  val out-kk = dir.path / (mod-name ++ ".kk").path
  println("building " ++ file)
  // Always parse the main .hc (fast) to get imports for inc-dirs and the freshness check.
  val source = read-text-file(file.path)
  val tokens = lex(source)
  val prog   = run-parser-program(tokens, source)
  val inc-dirs = import-dirs(prog.imports, dir.path) ++ extra-includes
  val out-bin-path = match output
    Just(name) -> name.path
    Nothing    -> dir.path / (mod-name ++ exe-ext()).path
  val out-bin = out-bin-path.string
  // Fast path: if the main .kk and all direct imports are up to date, skip the entire
  // hica pipeline (prelude load, import processing, type check, emit) and go to koka.
  // Transitive-dep changes are not checked here — run `hica clean` to force a full rebuild.
  if !generate && main-kk-is-up-to-date(out-kk, file.path, prog.imports, dir.path) then
    println("  => up to date")
    print("  => compiling...")
    flush-stdout()
    val ok = compile-koka(file, mod-name, inc-dirs, opt-level, koka-flags, output)
    if ok then
      println(" done")
      println("generated: " ++ out-bin)
    ok
  else
    // Full pipeline: load prelude .hc files and merge with user program
    print("  => loading prelude...")
    flush-stdout()
    val prelude = load-prelude()
    println(" done")
    // Compile imported modules and collect pub declarations
    print("  => processing imports...")
    flush-stdout()
    val (imported-decls, imported-structs, imported-types, imported-names, _) = compile-imports(prog.imports, dir.path, [file])
    val ext-env = collect-extern-env(prog.imports, dir.path)
    println(" done")
    val merged = Program(prelude.structs ++ imported-structs ++ prog.structs,
                         types = prelude.types ++ imported-types ++ prog.types,
                         decls = prelude.decls ++ imported-decls ++ prog.decls,
                         globals = prog.globals,
                         imports = prog.imports)
    // Desugar
    val desugared = desugar-program(merged)
    // Type check
    val skip-decls = prelude.decls.length + imported-decls.length
    val skip-structs = prelude.structs.length + imported-structs.length
    val skip-types = prelude.types.length + imported-types.length
    print("  => checking...")
    flush-stdout()
    val (typed-prog, diags) = collect-diagnostics
      run-fresh
        check-program(desugared, skip-decls, skip-structs, skip-types, extra-extern = ext-env)
    println(" done")
    val warnings = diags.filter(fn(d) match d.severity { Warning -> True; _ -> False })
    val errors = diags.filter(fn(d) match d.severity { Error -> True; _ -> False })
    warnings.foreach(fn(d) println(render-diagnostic(source, file, d)))
    if !errors.is-empty then
      errors.foreach(fn(d) println(render-diagnostic(source, file, d)))
      println("build: " ++ errors.length.show ++ " type error(s)")
      False
    else
      // Emit main module — keep prelude + user decls/types/structs, skip imported ones
      val prelude-count = prelude.decls.length
      val imported-count = imported-decls.length
      val user-typed-decls = typed-prog.decls.take(prelude-count) ++ typed-prog.decls.drop(prelude-count + imported-count)
      val prelude-struct-count = prelude.structs.length
      val imported-struct-count = imported-structs.length
      val user-structs = typed-prog.structs.take(prelude-struct-count) ++ typed-prog.structs.drop(prelude-struct-count + imported-struct-count)
      val prelude-type-count = prelude.types.length
      val imported-type-count = imported-types.length
      val user-types = typed-prog.types.take(prelude-type-count) ++ typed-prog.types.drop(prelude-type-count + imported-type-count)
      val user-prog = typed-prog(decls = user-typed-decls, structs = user-structs, types = user-types, imports = prog.imports)
      val koka-code = emit-program(user-prog, mod-name, imported-names = imported-names, source = source, prelude-count = prelude-count, extra-effectful = collect-extern-effectful(prog.imports, dir.path), extra-imports = collect-extern-kk-modules(prog.imports, dir.path))
      write-kk-if-changed(out-kk, koka-code, file)
      print("  => compiling...")
      flush-stdout()
      val ok = compile-koka(file, mod-name, inc-dirs, opt-level, koka-flags, output)
      if ok then
        println(" done")
        println("generated: " ++ out-bin)
      ok

// Collect unique directories that imported modules live in (for Koka -i flags)
fun import-dirs( imports : list<import-decl>, base-dir : path ) : list<string>
  imports.map(fn(imp)
    val imp-file = resolve-import(imp.path, base-dir)
    imp-file.dirname.show
  ).foldl([], fn(acc : list<string>, d)
    if acc.any(fn(a) a == d) then acc else Cons(d, acc)
  ).reverse

// ---------------------------------------------------------------------------
// Import resolution: compile imported modules, collect pub declarations
// ---------------------------------------------------------------------------

// Resolve an import path relative to a directory → absolute .hc file path
// NOTE: Must use string concatenation before converting to path — same reason as resolve-kk-extern.
fun resolve-import( imp-path : string, base-dir : path ) : path
  (base-dir.string ++ "/" ++ imp-path ++ ".hc").path

// Resolve an extern import path to its .kk file.
// NOTE: Must use string concatenation before converting to path — Koka's path / path
// operator normalizes each operand independently, which eliminates leading ".." components
// before they can traverse into the base-dir. String concat lets the OS normalise together.
fun resolve-kk-extern( imp-path : string, base-dir : path ) : path
  if imp-path.starts-with("/").bool then (imp-path ++ ".kk").path
  else (base-dir.string ++ "/" ++ imp-path ++ ".kk").path

// Parse `pub extern` declarations from a Koka .kk file and return
// a type-env usable by the hica checker.
fun parse-kk-extern-env( kk-file : path )
  if !is-file(kk-file) then []
  else
    val content = read-text-file(kk-file)
    content.lines.foldl([], fn(acc, raw-line)
      val line = raw-line.trim
      if !line.starts-with("pub extern ").bool then acc
      else
        val rest = line.slice.sslice/drop(11).string.trim   // after "pub extern "
        val name = rest.split("(").head-or("").trim
        if name.is-empty then acc
        else
          val after-open = match rest.split("(")
            Cons(_, Cons(s, _)) -> s
            _ -> ""
          val params-str = after-open.split(")").head-or("")
          val param-types = parse-kk-param-types(params-str)
          val after-close = match after-open.split(")")
            Cons(_, Cons(s, _)) -> s.trim
            _ -> ""
          val ret-str = kk-parse-ret(after-close)
          val ret-type = kk-type-to-hica(ret-str)
          Cons((name, TFun(param-types, ret-type)), acc)
    )

// Resolve return type word from the suffix after ")" e.g. " : io ()" → "()"
fun kk-parse-ret( after-close : string ) : string
  val stripped = if after-close.starts-with(":").bool
    then after-close.slice.sslice/drop(1).string.trim else after-close.trim
  val words = stripped.split(" ").filter(fn(w) !w.is-empty)
  match words
    Cons(w, Cons(r, _)) ->
      if w == "io" || w == "div" || w == "ndet" || w == "exn" then r else w
    Cons(w, _) -> w
    _ -> ""

// Parse a Koka param list "label : string, min : int" → list of hica types.
// Each unknown type gets a unique TVar so the checker doesn't over-unify.
fun parse-kk-param-types( params-str : string ) : list<hica-type>
  if params-str.trim.is-empty then []
  else
    val params = params-str.split(",").filter(fn(p) !p.trim.is-empty)
    val (_, result) = params.foldl((0, []), fn((idx, acc), p)
      val parts = p.trim.split(":").map(fn(s) s.trim)
      val type-str = match parts
        Cons(_, Cons(t, _)) -> t.trim
        _ -> p.trim   // no colon → treat the whole thing as a type (e.g. "@hica:" style)
      val tp = if type-str == "fun" || type-str == "any"
        then TVar("_a" ++ idx.show)
        else kk-type-to-hica(type-str)
      (idx + 1, Cons(tp, acc))
    )
    result.reverse

// Map a Koka type keyword to a hica-type.
fun kk-type-to-hica( t : string ) : hica-type
  match t.trim.split(" ").head-or("")
    "string"  -> TString
    "int"     -> TInt
    "bool"    -> TBool
    "float64" -> TFloat
    "()"      -> TUnit
    _         -> TVar("_a")

fun head-or( xs : list<string>, default : string ) : string
  match xs
    Cons(h, _) -> h
    _ -> default

// Infer which extern function names are effectful (have an `io` effect row)
// by re-scanning the .kk file for the `io` keyword.
fun parse-kk-effectful-names( kk-file : path )
  if !is-file(kk-file) then []
  else
    val content = read-text-file(kk-file)
    content.lines.foldl([], fn(acc, raw-line)
      val line = raw-line.trim
      if !line.starts-with("pub extern ").bool then acc
      else
        val rest = line.slice.sslice/drop(11).string.trim
        val name = rest.split("(").head-or("").trim
        if name.is-empty then acc
        else
          val after-open = match rest.split("(")
            Cons(_, Cons(s, _)) -> s
            _ -> ""
          val after-close = match after-open.split(")")
            Cons(_, Cons(s, _)) -> s.trim
            _ -> ""
          val is-io = after-close.starts-with(": io").bool
          if is-io then Cons(name, acc) else acc
    )

// Collect extra-effectful names from all extern imports, recursively following regular .hc imports.
fun collect-extern-effectful-rec( imp-list : list<import-decl>, base-dir : path, visited : list<string> )
  imp-list.foldl([], fn(acc, imp)
    if imp.is-extern then
      val kk-path = resolve-kk-extern(imp.path, base-dir)
      acc ++ parse-kk-effectful-names(kk-path)
    elif imp.path.starts-with("std/").bool then acc
    else
      val hc-path = resolve-import(imp.path, base-dir)
      val hc-str  = hc-path.string
      if visited.any(fn(v) v == hc-str) || !is-file(hc-path) then acc
      else
        val sub-source = read-text-file(hc-path)
        val sub-tokens = lex(sub-source)
        val sub-prog   = run-parser-program(sub-tokens, sub-source)
        val sub-dir    = hc-path.dirname.path
        acc ++ collect-extern-effectful-rec(sub-prog.imports, sub-dir, Cons(hc-str, visited))
  )

fun collect-extern-effectful( imports : list<import-decl>, base-dir : path )
  collect-extern-effectful-rec(imports, base-dir, [])

// Collect type-env entries from all extern imports, recursively following regular .hc imports.
fun collect-extern-env-rec( imp-list : list<import-decl>, base-dir : path, visited : list<string> )
  imp-list.foldl([], fn(acc, imp)
    if imp.is-extern then
      val kk-path = resolve-kk-extern(imp.path, base-dir)
      acc ++ parse-kk-extern-env(kk-path)
    elif imp.path.starts-with("std/").bool then acc
    else
      val hc-path = resolve-import(imp.path, base-dir)
      val hc-str  = hc-path.string
      if visited.any(fn(v) v == hc-str) || !is-file(hc-path) then acc
      else
        val sub-source = read-text-file(hc-path)
        val sub-tokens = lex(sub-source)
        val sub-prog   = run-parser-program(sub-tokens, sub-source)
        val sub-dir    = hc-path.dirname.path
        acc ++ collect-extern-env-rec(sub-prog.imports, sub-dir, Cons(hc-str, visited))
  )

fun collect-extern-env( imports : list<import-decl>, base-dir : path )
  collect-extern-env-rec(imports, base-dir, [])

// Collect Koka module names for all extern imports (transitively), for injection into
// the generated .kk header as `import X` statements. Deduplicates by module name.
fun collect-extern-kk-modules-rec( imp-list : list<import-decl>, base-dir : path, visited : list<string> )
  imp-list.foldl([], fn(acc, imp)
    if imp.is-extern then
      val mod-name-str = safe-module-name(imp.path.path.stemname)
      if acc.any(fn(m) m == mod-name-str) then acc else Cons(mod-name-str, acc)
    elif imp.path.starts-with("std/").bool then acc
    else
      val hc-path = resolve-import(imp.path, base-dir)
      val hc-str  = hc-path.string
      if visited.any(fn(v) v == hc-str) || !is-file(hc-path) then acc
      else
        val sub-source = read-text-file(hc-path)
        val sub-tokens = lex(sub-source)
        val sub-prog   = run-parser-program(sub-tokens, sub-source)
        val sub-dir    = hc-path.dirname.path
        acc ++ collect-extern-kk-modules-rec(sub-prog.imports, sub-dir, Cons(hc-str, visited))
  )

fun collect-extern-kk-modules( imports : list<import-decl>, base-dir : path )
  collect-extern-kk-modules-rec(imports, base-dir, [])

// Compile all imports and return (pub-decls, pub-structs, pub-types, pub-names, generated-kk-paths)
fun compile-imports( imp-list : list<import-decl>, base-dir : path, visited : list<string> )
  imp-list.foldl(([], [], [], [], []), fn(acc, imp)
    val (prev-decls, prev-structs, prev-types, prev-names, prev-kk-paths) = acc
    // Extern imports: just record the path for Koka; type info collected separately
    if imp.is-extern then acc
    // Stdlib imports: resolved from embedded sources, extracted to ~/.hica/stdlib
    elif imp.path.starts-with("std/").bool then
      val (sd, ss, st, sn) = compile-stdlib-import(imp.path)
      (prev-decls ++ sd, prev-structs ++ ss, prev-types ++ st, prev-names ++ sn, prev-kk-paths)
    else
      val imp-file = resolve-import(imp.path, base-dir)
      val imp-path-str = imp-file.show
      // Cycle detection
      if visited.any(fn(v) v == imp-path-str) then
        println("error: circular import detected: " ++ imp-path-str)
        acc
      elif !is-file(imp-file) then
        println("error: imported file not found: " ++ imp-path-str)
        acc
      else
        // Compile the imported module to .kk; collect generated .kk paths for later cleanup
        val mod-kk-paths = compile-module(imp-file, visited)
        // Parse the module to collect pub declarations for the checker
        val mod-source = read-text-file(imp-file)
        val mod-tokens = lex(mod-source)
        val mod-prog = run-parser-program(mod-tokens)
        // Collect pub declarations (for selective imports, filter by name)
        val pub-decls = mod-prog.decls.filter(fn(d) d.is-pub)
        val pub-names-all = pub-decls.map(fn(d) d.name)
        val filtered-decls = match imp.names
          Nothing  -> pub-decls
          Just(ns) -> pub-decls.filter(fn(d) ns.any(fn(n) n == d.name))
        val filtered-names = match imp.names
          Nothing  -> pub-names-all
          Just(ns) -> ns
        // Collect re-exported symbols from the module's pub imports
        val pub-reimports = mod-prog.imports.filter(fn(i) i.is-pub)
        val imp-dir = imp-file.dirname.path
        val (re-decls, re-structs, re-types, re-names, re-kk-paths) = compile-imports(pub-reimports, imp-dir, Cons(imp-path-str, visited))
        // Also pull in stdlib symbols from this module's private imports so the checker
        // can resolve references inside pub-decls (e.g. datetime_kind called from
        // parser.hc's pub funs when basic.hc imports hml.hc which pub-imports parser).
        // These are added to the checker env but NOT to imp-names, so they are never
        // treated as user-re-exported symbols.
        val mod-priv-stdlib = mod-prog.imports.filter(fn(i) !i.is-pub && i.path.starts-with("std/").bool)
        val (stdlib-decls, stdlib-structs, stdlib-types, _, _) = compile-imports(mod-priv-stdlib, imp-dir, Cons(imp-path-str, visited))
        (prev-decls ++ filtered-decls ++ re-decls ++ stdlib-decls, prev-structs ++ mod-prog.structs ++ re-structs ++ stdlib-structs, prev-types ++ mod-prog.types ++ re-types ++ stdlib-types, prev-names ++ filtered-names ++ re-names, prev-kk-paths ++ mod-kk-paths ++ re-kk-paths)
  )

// Compile a single imported module to a .kk file.
// True if the generated .kk is strictly newer than the .hc source — no recompilation needed.
fun kk-is-fresh( kk-file : path, hc-file : path ) : io bool
  if is-windows() then False
  else run-system("test " ++ kk-file.show ++ " -nt " ++ hc-file.show ++ dev-null()) == 0

// True if the main .kk is newer than the main .hc AND newer than every direct
// user-import's .hc, AND every direct import's .kk exists on disk.
// Shallow check — transitive-dep changes require `hica clean` to invalidate.
fun main-kk-is-up-to-date( out-kk : path, hc-file : path, imports : list<import-decl>, base-dir : path ) : io bool
  if !kk-is-fresh(out-kk, hc-file) then False
  else
    // Reject .kk files written in test mode (they include the test harness, not main()).
    // Test-mode files start with "// Generated by hica (test mode)" instead of "// Generated by hica\n".
    val header = read-text-file(out-kk).first(40).string
    if !header.starts-with("// Generated by hica\n").bool then False
    else
      val stdlib-dir = hica-stdlib-dir()
      imports.foldl(True, fn(ok, imp)
        if !ok then False
        elif imp.is-extern then True
        elif imp.path.starts-with("std/").bool then
          val stem = imp.path.path.stemname
          is-file(stdlib-dir / (stem ++ ".kk").path)
        else
          val hc = resolve-import(imp.path, base-dir)
          if !is-file(hc) then False
          else
            val lib-kk = hc.dirname.path / (safe-module-name(hc.stemname) ++ ".kk").path
            is-file(lib-kk) && kk-is-fresh(out-kk, hc)
      )

// Returns all generated .kk paths in this subtree (for post-compile cleanup).
fun compile-module( imp-file : path, visited : list<string> ) : io list<path>
  val stem = imp-file.stemname
  val mod-name = safe-module-name(stem)
  val dir = imp-file.dirname
  val out-kk = dir.path / (mod-name ++ ".kk").path
  // Timestamp cache: if .kk is already newer than .hc, skip the entire pipeline
  if is-file(out-kk) && kk-is-fresh(out-kk, imp-file) then
    [out-kk]
  else
    print("#")
    flush-stdout()
    val source = read-text-file(imp-file)
    val tokens = lex(source)
    val prog = run-parser-program(tokens, source)
    // Load prelude for this module
    val prelude = load-prelude()
    // Recursively compile this module's imports
    val imp-path-str = imp-file.show
    val (imp-decls, imp-structs, imp-types, imp-names, sub-kk-paths) = compile-imports(prog.imports, dir.path, Cons(imp-path-str, visited))
    val ext-env = collect-extern-env(prog.imports, dir.path)
    val merged = Program(prelude.structs ++ imp-structs ++ prog.structs,
                         types = prelude.types ++ imp-types ++ prog.types,
                         decls = prelude.decls ++ imp-decls ++ prog.decls,
                         globals = prog.globals,
                         imports = prog.imports)
    // Desugar
    val desugared = desugar-program(merged)
    // Type check
    val skip-decls = prelude.decls.length + imp-decls.length
    val skip-structs = prelude.structs.length + imp-structs.length
    val skip-types = prelude.types.length + imp-types.length
    val (typed-prog, diags) = collect-diagnostics
      run-fresh
        check-program(desugared, skip-decls, skip-structs, skip-types, extra-extern = ext-env)
    val errors = diags.filter(fn(d) match d.severity { Error -> True; _ -> False })
    if !errors.is-empty then
      errors.foreach(fn(d) println(render-diagnostic(source, imp-file.show, d)))
      println("error: " ++ errors.length.show ++ " type error(s) in " ++ imp-file.show)
    // Emit module .kk — keep prelude + user decls/types/structs, skip imported ones
    val prelude-count = prelude.decls.length
    val imp-imported-count = imp-decls.length
    val user-typed-decls = typed-prog.decls.take(prelude-count) ++ typed-prog.decls.drop(prelude-count + imp-imported-count)
    val prelude-struct-count = prelude.structs.length
    val imp-struct-count = imp-structs.length
    val user-structs = typed-prog.structs.take(prelude-struct-count) ++ typed-prog.structs.drop(prelude-struct-count + imp-struct-count)
    val prelude-type-count = prelude.types.length
    val imp-type-count = imp-types.length
    val user-types = typed-prog.types.take(prelude-type-count) ++ typed-prog.types.drop(prelude-type-count + imp-type-count)
    val user-prog = typed-prog(decls = user-typed-decls, structs = user-structs, types = user-types, imports = prog.imports)
    val koka-code = emit-program(user-prog, mod-name, imported-names = imp-names, source = source, prelude-count = prelude-count, extra-effectful = collect-extern-effectful(prog.imports, dir.path), extra-imports = collect-extern-kk-modules(prog.imports, dir.path))
    // Write to source dir — stable path lets koka reuse its .kki cache on unchanged runs
    write-kk-if-changed(out-kk, koka-code, imp-file.show)
    Cons(out-kk, sub-kk-paths)

// ---------------------------------------------------------------------------
// Koka error line rewriting: translate .kk line numbers back to .hc lines
// ---------------------------------------------------------------------------

// Given a .kk file's content as a list of lines (1-indexed by position),
// find the nearest "// .hc:N" comment at or before line `kk-line`.
// Returns the .hc line number, or Nothing if no comment found.
fun find-hc-line( kk-lines : list<string>, kk-line : int ) : maybe<int>
  // Take lines 1..kk-line, reverse so we scan backward
  val before = kk-lines.take(kk-line).reverse
  fun scan(ls : list<string>) : maybe<int>
    match ls
      Nil -> Nothing
      Cons(l, rest) ->
        val t = l.trim
        if t.starts-with("// .hc:").bool then
          val n-str = t.slice.drop(7).string.trim
          n-str.parse-int
        else
          scan(rest)
  scan(before)

// Rewrite a single line of Koka error output.
// Replaces `<path>.kk(<line>, <col>):` with `<stem>.hc(<hc-line>, <col>):`.
// `kk-lines` is the split content of the generated .kk file.
// `hc-file` is the original .hc file path string.
fun rewrite-koka-error-line( line : string, kk-lines : list<string>, kk-file : string, hc-file : string ) : string
  // Split on ".kk(" to locate the position
  match line.split(".kk(")
    Cons(_, Nil) -> line  // no match
    Cons(_, Cons(after-paren, _)) ->
      // Split after-paren on ")" to get coords and the rest
      match after-paren.split(")")
        Cons(coords-str, Cons(rest-after, _)) ->
          // Must start with ":"
          if !rest-after.starts-with(":").bool then line
          else
            // Parse coords: "line, col" or "line,col"
            val parts = coords-str.split(",")
            match parts
              Cons(line-part, Cons(col-part, _)) ->
                match line-part.trim.split("-")
                  Cons(ln-str, _) ->
                    match ln-str.trim.parse-int
                      Nothing -> line
                      Just(kk-ln) ->
                        match find-hc-line(kk-lines, kk-ln)
                          Nothing -> line
                          Just(hc-ln) ->
                            hc-file ++ "(" ++ hc-ln.show ++ ", " ++ col-part.trim ++ ")" ++ rest-after
                  Nil -> line
              _ -> line
        _ -> line
    Nil -> line

// Rewrite all Koka error output lines, translating .kk locations to .hc locations.
fun rewrite-koka-errors( output : string, kk-file-raw : string, hc-file : string )
  val kk-content = if is-file(kk-file-raw.path) then read-text-file(kk-file-raw.path) else ""
  val kk-lines = kk-content.lines
  output.lines.map(fn(l) rewrite-koka-error-line(l, kk-lines, kk-file-raw, hc-file)).join("\n")

// ---------------------------------------------------------------------------
// Compile: invoke koka to compile the generated file into a binary
// ---------------------------------------------------------------------------

fun compile-koka( file : string, mod-name : string, include-dirs : list<string> = [], opt-level : string = "2", koka-flags : string = "", output : maybe<string> = Nothing )
  val dir  = file.path.dirname
  val kk-path = dir.path / (mod-name ++ ".kk").path
  val kk-file-raw = kk-path.string  // raw path for Koka file I/O
  val kk-file = kk-path.show        // shell-quoted for subprocess commands
  val out-bin = match output
    Just(name) -> name
    Nothing    -> (dir.path / (mod-name ++ exe-ext()).path).show
  // Always include ~/.hica/stdlib so stdlib imports (std/term etc.) resolve
  val stdlib-dir = hica-stdlib-dir()
  ensure-dir(stdlib-dir)
  val inc-flags = include-dirs.map(fn(d) " -i" ++ d).join("") ++ " -i" ++ stdlib-dir.show
  val opt-flag = "-O" ++ opt-level
  val extra = if koka-flags.is-empty then "" else " " ++ koka-flags
  val koka-cmd = "koka " ++ opt-flag ++ " -v0 -o " ++ out-bin ++ inc-flags ++ extra ++ " " ++ kk-file
  // On Unix: run koka silently in background and print '#' every 0.5s as a progress indicator
  val exit-code = if is-windows() then
    run-system(koka-cmd ++ dev-null())
  else
    run-system(koka-cmd ++ " >/dev/null 2>&1 & hica_p=$!; while kill -0 $hica_p 2>/dev/null; do printf '#'; sleep 0.5; done; wait $hica_p")
  if exit-code != 0 then
    // Re-run, capturing output to a temp file so we can rewrite .kk line numbers → .hc lines
    println("")
    val err-tmp = (hica-stdlib-dir().string ++ "/__koka_err.txt").path
    val capture-cmd = "koka " ++ opt-flag ++ " -v0 -o " ++ out-bin ++ inc-flags ++ extra ++ " " ++ kk-file ++ " > " ++ err-tmp.show ++ " 2>&1"
    val _ = run-system(capture-cmd)
    val raw-output = if is-file(err-tmp) then read-text-file(err-tmp) else ""
    val _ = if is-file(err-tmp) then run-system((if is-windows() then "del " else "rm -f ") ++ err-tmp.show) else 0
    val rewritten = rewrite-koka-errors(raw-output, kk-file-raw, file)
    println(rewritten)
    println("error: koka failed with exit code " ++ exit-code.show)
    False
  else
    if !is-windows() then
      val _ = run-system("chmod 0755 " ++ out-bin)
      ()
    True

// ---------------------------------------------------------------------------
// Run: execute the compiled binary
// ---------------------------------------------------------------------------

fun run-koka( file : string, user-args : list<string> = [] )
  val stem = file.path.stemname
  val mod-name = safe-module-name(stem)
  val dir  = file.path.dirname
  val bin-path = (dir.path / (mod-name ++ exe-ext()).path).string
  val bin-file = if bin-path.starts-with("/").bool || bin-path.starts-with("./").bool || bin-path.starts-with("../").bool then bin-path else "./" ++ bin-path
  val args-str = if user-args.is-nil then "" else " " ++ user-args.map(shell-escape).join(" ")
  val exit-code = run-system(bin-file ++ args-str)
  if exit-code != 0 then
    println("error: process exited with code " ++ exit-code.show)

// Run compiled test binary — non-zero exit is expected on failure (no extra error message).
// Propagates the test binary's exit code to the parent process.
fun run-tests( file : string )
  val stem = file.path.stemname
  val mod-name = safe-module-name(stem)
  val dir  = file.path.dirname
  val bin-path = (dir.path / (mod-name ++ exe-ext()).path).string
  val bin-file = if bin-path.starts-with("/").bool || bin-path.starts-with("./").bool || bin-path.starts-with("../").bool then bin-path else "./" ++ bin-path
  val exit-code = run-system(bin-file)
  if exit-code != 0 then
    val code = exit-code / 256
    hica-exit(if code > 0 then code else 1)
  ()

// Escape a shell argument: wrap in single quotes, escaping any inner single quotes.
fun shell-escape( s : string ) : string
  "'" ++ s.replace-all("'", "'\\''") ++ "'"

// ---------------------------------------------------------------------------
// Help
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Manifest: read hica.ini to resolve entry file
// ---------------------------------------------------------------------------

val manifest-name = "hica.hml"

fun resolve-entry() : <fsys,exn,div> maybe<string>
  if is-file(manifest-name.path) then
    val content = read-text-file(manifest-name.path)
    hml-field(content, "project", "entry")
  else Nothing

// Read @description block from hica.hml
fun read-manifest-description() : <fsys,exn,div> (string, string, string, string)
  if is-file(manifest-name.path) then
    val content = read-text-file(manifest-name.path)
    val summary    = match hml-field(content, "description", "summary")    { Just(s) -> s; Nothing -> "" }
    val author     = match hml-field(content, "description", "author")     { Just(s) -> s; Nothing -> "" }
    val homepage   = match hml-field(content, "description", "homepage")   { Just(s) -> s; Nothing -> "" }
    val repository = match hml-field(content, "description", "repository") { Just(s) -> s; Nothing -> "" }
    (summary, author, homepage, repository)
  else ("", "", "", "")

// Read @koka block from hica.hml: include dirs and extra flags.
// Searches `dir` first (the source file's directory), then CWD.
// Paths in include: and -L flags are resolved relative to the manifest's own directory.
fun read-manifest-koka( dir : string = "." ) : <fsys,exn,div> (list<string>, string)
  val candidate  = dir ++ "/" ++ manifest-name
  val has-local  = is-file(candidate.path)
  val has-cwd    = is-file(manifest-name.path)
  if has-local || has-cwd then
    val manifest-path = if has-local then candidate else manifest-name
    val manifest-dir  = if has-local then dir else "."
    val content = read-text-file(manifest-path.path)
    val includes = match hml-field(content, "koka", "include")
      Just(s) -> s.split(";").map(fn(p) p.trim).filter(fn(p) !p.is-empty)
                .map(fn(p) if p.starts-with("/").bool then p else manifest-dir ++ "/" ++ p)
      Nothing -> []
    val flags = match hml-field(content, "koka", "flags")
      Just(s) -> resolve-flags-paths(s, manifest-dir)
      Nothing -> ""
    (includes, flags)
  else
    ([], "")

// Resolve relative -L / --cclibdir paths in the raw koka flags string
// relative to the manifest's directory so that `hica run path/to/file.hc`
// from the repo root finds the same libraries as `hica build file.hc` from
// the file's own directory.
fun resolve-flags-paths( flags : string, mdir : string ) : string
  if mdir == "." || mdir.is-empty then flags
  else
    flags.split(" ").filter(fn(t) !t.is-empty).map(fn(tok)
      val pfx-l = "--cclinkopts=-L"
      val pfx-d = "--cclibdir="
      if tok.starts-with(pfx-l).bool then
        val p = tok.slice.sslice/drop(pfx-l.count).string
        if p.starts-with("/").bool then tok else pfx-l ++ mdir ++ "/" ++ p
      elif tok.starts-with(pfx-d).bool then
        val p = tok.slice.sslice/drop(pfx-d.count).string
        if p.starts-with("/").bool then tok else pfx-d ++ mdir ++ "/" ++ p
      else tok
    ).join(" ")

fun hml-field( content : string, element : string, key : string ) : div maybe<string>
  // Parse "key: value" within @element { ... } blocks in hica.hml
  val all-lines = content.lines
  var in-element := False
  var result := Nothing
  all-lines.foreach fn(line)
    val trimmed = line.trim
    if trimmed.starts-with("//").bool then ()
    elif !in-element then
      if trimmed.starts-with("@" ++ element).bool then in-element := True
    else
      if trimmed == "}" then in-element := False
      else
        if trimmed.starts-with(key).bool then
          val after-key = trimmed.slice.sslice/drop(key.count).string.trim-left
          if after-key.starts-with(":").bool then
            result := Just(after-key.slice.sslice/drop(1).string.trim.unquote)
  result

fun unquote( s : string ) : string
  if s.count >= 2 && s.starts-with("\"").bool && s.ends-with("\"").bool then
    s.slice.sslice/drop(1).sslice/extend(0 - 1).string
  else s

fun print-usage()
  println(hica-cli().format-help)
  println("\nCommands:")
  println("    build, b    Compile a .hc file and build a binary")
  println("    run, r      Compile and run a .hc file")
  println("    check, c    Analyse a .hc file and report errors")
  println("    fmt, f      Format a .hc file")
  println("    clean       Remove generated build artifacts")
  println("    test, t     Run tests in a .hc file")
  println("    new         Create a new hica project")
  println("    init        Initialise a project in the current directory")
  println("    add         Add a dependency")
  println("    remove      Remove a dependency")
  println("    fetch       Fetch all dependencies")
  println("    help        Print this message\n")
  println("See 'hica help <command>' for more information on a specific command.")

// ---------------------------------------------------------------------------
// Effect discovery: scan user program for effectful operations
// ---------------------------------------------------------------------------

// Known effectful function → effect name mapping.
val console-fns = ["println", "eprintln"]
val fsys-fns    = ["read_file", "write_file", "read_lines", "write_lines"]
val io-fns      = ["input", "get_args", "get_env", "set_env", "set_env_nooverwrite"]
val ndet-fns    = ["random"]

fun discover-effects( prog : program ) : div list<string>
  // Collect all called function names and recursion info
  val info = prog.decls.map(fn(d) (collect-calls(d.body), d.is-recursive))
  val all-calls = info.map(fst).concat
  val any-recursive = info.any(fn((_, r)) r)
  var effects : list<string> := []
  if all-calls.any(fn(name) console-fns.any(fn(f) f == name)) then
    effects := effects ++ ["console"]
  if all-calls.any(fn(name) fsys-fns.any(fn(f) f == name)) then
    effects := effects ++ ["fsys"]
  if all-calls.any(fn(name) io-fns.any(fn(f) f == name)) then
    effects := effects ++ ["io"]
  if all-calls.any(fn(name) ndet-fns.any(fn(f) f == name)) then
    effects := effects ++ ["ndet"]
  if any-recursive then
    effects := effects ++ ["div"]
  effects

// Collect all function names called in a node (recursively)
fun collect-calls( n : node ) : div list<string>
  match n.expr
    Call(callee, args) ->
      val callee-names = match callee.expr
        Var(name) -> [name]
        _         -> collect-calls(callee)
      callee-names ++ args.map(fn(a) collect-calls(a)).concat
    Let(_, _, init, body) -> collect-calls(init) ++ collect-calls(body)
    VarDecl(_, _, init, body) -> collect-calls(init) ++ collect-calls(body)
    Assign(_, v) -> collect-calls(v)
    Fun(_, body) -> collect-calls(body)
    Binary(_, lhs, rhs) -> collect-calls(lhs) ++ collect-calls(rhs)
    Unary(_, operand) -> collect-calls(operand)
    If(cond, then-e, else-e) -> collect-calls(cond) ++ collect-calls(then-e) ++ collect-calls(else-e)
    Block(stmts) -> stmts.map(fn(s) collect-calls(s)).concat
    Match(scrut, arms) ->
      val guard-calls = arms.map fn(a)
        match a.guard
          Just(g) -> collect-calls(g)
          Nothing -> []
      collect-calls(scrut) ++ guard-calls.concat ++ arms.map(fn(a) collect-calls(a.body)).concat
    Repeat(count, body) -> collect-calls(count) ++ collect-calls(body)
    ForIn(_, start-e, end-e, body) -> collect-calls(start-e) ++ collect-calls(end-e) ++ collect-calls(body)
    ForEach(_, coll, body) -> collect-calls(coll) ++ collect-calls(body)
    While(cond, body) -> collect-calls(cond) ++ collect-calls(body)
    Loop(body) -> collect-calls(body)
    StringInterp(parts) -> parts.map(fn(p) collect-calls(p)).concat
    Tuple(elems) -> elems.map(fn(e) collect-calls(e)).concat
    EList(elems) -> elems.map(fn(e) collect-calls(e)).concat
    ListIndex(lst, idx) -> collect-calls(lst) ++ collect-calls(idx)
    ListSlice(lst, s, e) ->
      val s-calls = match s { Just(n') -> collect-calls(n'); Nothing -> [] }
      val e-calls = match e { Just(n') -> collect-calls(n'); Nothing -> [] }
      collect-calls(lst) ++ s-calls ++ e-calls
    TupleIndex(tup, _) -> collect-calls(tup)
    LetTuple(_, init, body) -> collect-calls(init) ++ collect-calls(body)
    ESome(v)  -> collect-calls(v)
    EOk(v)    -> collect-calls(v)
    EErr(v)   -> collect-calls(v)
    FieldAccess(o, _) -> collect-calls(o)
    StructLit(_, fields) -> fields.map(fn((_, v)) collect-calls(v)).concat
    _ -> []
