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
import transform/desugar
import format/formatter
import klap

val version = "0.22.0" 

// Clean process exit without throwing exceptions
extern hica-exit( code : int ) : a
  c inline "(exit(kk_integer_clamp32(#1, kk_context())), kk_box_null())"

// Write .kk only if content changed — preserves Koka's build cache
fun write-kk-if-changed( out-kk : path, koka-code : string, hc-file : string )
  if is-file(out-kk) then
    val existing = read-text-file(out-kk)
    if existing == koka-code then
      println("compiled " ++ hc-file ++ " -> " ++ out-kk.show ++ " (unchanged)")
    else
      write-text-file(out-kk, koka-code)
      println("compiled " ++ hc-file ++ " -> " ++ out-kk.show)
  else
    write-text-file(out-kk, koka-code)
    println("compiled " ++ hc-file ++ " -> " ++ out-kk.show)

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
    .arg(option("target").help("Output target: koka (default) or js"))
    .subcommand("build, b", "Compile a .hc file and build a binary")
    .subcommand("run, r", "Compile and run a .hc file")
    .subcommand("check, c", "Analyse a .hc file and report errors")
    .subcommand("fmt, f", "Format a .hc file")
    .subcommand("clean", "Remove generated build artifacts")
    .subcommand("test, t", "Run tests in a .hc file")
    .subcommand("new", "Create a new hica project")
    .subcommand("init", "Initialise a hica project in the current directory")
    .subcommand("repl", "Start an interactive REPL")
    .subcommand("help", "Show help for a command")

fun build-cli() : command
  command("hica build")
    .about("Compile a .hc file and build a binary")
    .arg(positional("FILE").help("Source .hc file").required)

fun run-cli() : command
  command("hica run")
    .about("Compile and run a .hc file")
    .arg(positional("FILE").help("Source .hc file").required)

fun check-cli() : command
  command("hica check")
    .about("Analyse a .hc file and report errors")
    .arg(positional("FILE").help("Source .hc file").required)

fun clean-cli() : command
  command("hica clean")
    .about("Remove generated build artifacts")
    .arg(positional("FILE").help("Source .hc file").required)

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

// Split a list at the first "--" element. Returns (before, after).
fun split-at-double-dash( args : list<string> ) : (list<string>, list<string>)
  match args
    Nil -> ([], [])
    Cons("--", rest) -> ([], rest)
    Cons(a, rest) ->
      val (before, after) = split-at-double-dash(rest)
      (Cons(a, before), after)

fun main()
  val (hica-args, user-args) = split-at-double-dash(get-args())
  val m = hica-cli().parse-or-exit(hica-args)
  val cmd  = m.get-one-or("COMMAND", "")
  val file = m.get-one("FILE")
  match cmd
    "help"  -> cmd-help(file)
    "new"   -> cmd-new(file)
    "init"  -> cmd-init()
    "repl"  -> cmd-repl-with-file(file)
    _ ->
      val resolved = match file
        Just(f) -> Just(f)
        Nothing -> resolve-entry()
      match resolved
        Just(f) ->
          val target = m.get-one-or("target", "koka")
          match cmd
            "build" -> cmd-build(f, target)
            "b"     -> cmd-build(f, target)
            "run"   -> cmd-run(f, user-args)
            "r"     -> cmd-run(f, user-args)
            "check" -> cmd-check(f)
            "c"     -> cmd-check(f)
            "fmt"   -> cmd-fmt(f, m.get-flag("check"))
            "f"     -> cmd-fmt(f, m.get-flag("check"))
            "clean" -> cmd-clean(f)
            "test"  -> cmd-test(f)
            "t"     -> cmd-test(f)
            other   ->
              println("error: no such command: `" ++ other ++ "`\n")
              println(hica-cli().format-help)
        Nothing ->
          println("error: missing file argument (no hica.ini found)")
          println("Usage: hica " ++ cmd ++ " <FILE>")

// ---------------------------------------------------------------------------
// Commands
// ---------------------------------------------------------------------------

fun cmd-build( file : string, target : string = "koka" )
  if target == "js" then
    build-js(file)
  else
    val (extra-includes, koka-flags) = read-manifest-koka()
    build(file, extra-includes=extra-includes, koka-flags=koka-flags)

// Build to JavaScript: lex → parse → check → emit JS
fun build-js( file : string )
  val stem = file.path.stemname
  val mod-name = safe-module-name(stem)
  val dir  = file.path.dirname
  val source = read-text-file(file.path)
  val tokens = lex(source)
  val prog   = run-parser-program(tokens, source)
  val prelude = load-prelude()
  val (imported-decls, imported-structs, imported-types, _) = compile-imports(prog.imports, dir.path, [file])
  val merged = Program(prelude.structs ++ imported-structs ++ prog.structs,
                       types = prelude.types ++ imported-types ++ prog.types,
                       decls = prelude.decls ++ imported-decls ++ prog.decls,
                       imports = prog.imports)
  val desugared = desugar-program(merged)
  val (typed-prog, diags) = collect-diagnostics
    run-fresh
      check-program(desugared)
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

fun cmd-run( file : string, user-args : list<string> )
  val (extra-includes, koka-flags) = read-manifest-koka()
  build(file, opt-level="0", extra-includes=extra-includes, koka-flags=koka-flags)
  run-koka(file, user-args)

fun cmd-check( file : string )
  val source = read-text-file(file.path)
  val tokens = lex(source)
  val prog   = run-parser-program(tokens, source)
  val dir    = file.path.dirname
  val prelude = load-prelude()
  val (imported-decls, imported-structs, imported-types, _) = compile-imports(prog.imports, dir.path, [file])
  val merged = Program(prelude.structs ++ imported-structs ++ prog.structs,
                       types = prelude.types ++ imported-types ++ prog.types,
                       decls = prelude.decls ++ imported-decls ++ prog.decls)
  val desugared = desugar-program(merged)
  val (_typed-prog, diags) = collect-diagnostics
    run-fresh
      check-program(desugared)
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
  val (extra-includes, koka-flags) = read-manifest-koka()
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
    val (imported-decls, imported-structs, imported-types, imported-names) = compile-imports(prog.imports, dir.path, [file])
    val merged = Program(prelude.structs ++ imported-structs ++ prog.structs,
                         types = prelude.types ++ imported-types ++ prog.types,
                         decls = prelude.decls ++ imported-decls ++ prog.decls,
                         tests = prog.tests)
    // Desugar
    val desugared = desugar-program(merged)
    // Type check
    val (typed-prog, diags) = collect-diagnostics
      run-fresh
        check-program(desugared)
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
      val koka-code = emit-test-program(user-prog, mod-name, imported-names = imported-names)
      val out-kk  = dir.path / (mod-name ++ ".kk").path
      write-kk-if-changed(out-kk, koka-code, file)
      val inc-dirs = import-dirs(prog.imports, dir.path) ++ extra-includes
      compile-koka(file, mod-name, inc-dirs, "0", koka-flags)
      run-tests(file)

fun cmd-clean( file : string )
  val stem = file.path.stemname
  val mod-name = safe-module-name(stem)
  val dir  = file.path.dirname
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
  val manifest = "hica.ini".path
  if is-file(manifest) then
    println("error: hica.ini already exists in this directory")
  else
    val name = cwd().stemname
    scaffold-project(".".path, name)

fun scaffold-project( project-dir : path, name : string )
  val main-file  = project-dir / "main.hc".path
  val manifest   = project-dir / "hica.ini".path
  val readme     = project-dir / "README.md".path
  val main-content = [
    "fun main() {",
    "  println(\"hello from " ++ name ++ "\")",
    "}"
  ].join("\n") ++ "\n"
  val manifest-content = [
    "[project]",
    "name = \"" ++ name ++ "\"",
    "version = \"0.1.0\"",
    "license = \"MIT\"",
    "entry = \"main.hc\"",
    "",
    "[description]",
    "summary = \"A hica project\"",
    "author = \"\"",
    "homepage = \"\"",
    "repository = \"\""
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

fun cmd-repl-with-file( file : maybe<string> )
  println("hica " ++ version ++ " REPL (exit with Ctrl-D or :quit)")
  println("Type expressions, declarations (fun, let, struct, type), or :help")
  println("Tip: use 'rlwrap hica repl' for history navigation and tab completion")
  println("")
  val prelude = load-prelude()
  // Load startup file (~/.hicarc) if it exists
  val state0 = repl-load-startup(prelude, empty-repl-state)
  // Load preloaded file (-i flag) if provided
  val state1 = match file
    Just(f) -> repl-load-file(f, prelude, state0)
    Nothing -> state0
  repl-loop(prelude, state1)

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
    val (typed-prog, _diags) = collect-diagnostics
      run-fresh
        check-program(desugared)
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
  val input = readline()
  if input == "" then  // EOF (Ctrl-D)
    println("\nBye!")
  else
    val line = input.trim
    if line == ":quit" || line == ":q" then
      println("Bye!")
    elif line == ":help" || line == ":h" then
      repl-help()
      repl-loop(prelude, state)
    elif line == ":defs" then
      repl-show-defs(state)
      repl-loop(prelude, state)
    elif line == ":reset" then
      println("  state cleared")
      repl-loop(prelude, empty-repl-state)
    elif line == ":history" then
      repl-show-history()
      repl-loop(prelude, state)
    elif line.starts-with(":load ").bool then
      val filepath = line.slice.drop(6).string.trim
      val new-state = repl-load-file(filepath, prelude, state)
      repl-loop(prelude, new-state)
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
  println("  :defs          Show current definitions")
  println("  :reset         Clear all definitions")
  println("  :load FILE     Load definitions from a .hc file")
  println("  :history       Show recent input history")
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
  val fragment = run-parser-repl(tokens, input)
  match fragment
    ReplDecl(d) ->
      // Type check with accumulated context
      val merged = Program(prelude.structs ++ state.structs,
                           types = prelude.types ++ state.types,
                           decls = prelude.decls ++ state.decls ++ [d])
      val desugared = desugar-program(merged)
      val (typed-prog, diags) = collect-diagnostics
        run-fresh
          check-program(desugared)
      val errors = diags.filter(fn(dia) match dia.severity { Error -> True; _ -> False })
      if !errors.is-empty then
        errors.foreach(fn(dia) println(render-diagnostic(input, "<repl>", dia)))
        state
      else
        // Emit JS and accumulate
        val typed-decl = typed-prog.decls.last.default(d)
        val js = emit-js-repl-decl(typed-decl)
        if !silent then println("  defined: " ++ d.name)
        state(decls = state.decls ++ [typed-decl], js-defs = state.js-defs ++ js ++ "\n")

    ReplStruct(sd) ->
      val js = emit-js-repl-struct(sd)
      if !silent then println("  defined: struct " ++ sd.name)
      state(structs = state.structs ++ [sd], js-defs = state.js-defs ++ js ++ "\n")

    ReplType(td) ->
      val js = emit-js-repl-type(td)
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
  val (typed-prog, diags) = collect-diagnostics
    run-fresh
      check-program(desugared)
  val errors = diags.filter(fn(dia) match dia.severity { Error -> True; _ -> False })
  if !errors.is-empty then
    errors.foreach(fn(dia) println(render-diagnostic(init.show, "<repl>", dia)))
    state
  else
    val typed-body = typed-prog.decls.last.default(wrapper).body
    val typed-init = unwrap-vals(state.vals, typed-body)
    val init-type = typed-init.typ
    val js = "var " ++ binding-name ++ " = " ++ emit-js-expr(typed-init) ++ ";\n"
    val show-js = js ++ "if (" ++ binding-name ++ " !== undefined && " ++ binding-name ++ " !== null) println(show(" ++ binding-name ++ "));\n"
    val full-js = emit-js-repl-preamble() ++ state.js-defs ++ show-js
    if !silent then repl-run-js(full-js)
    // Store binding and update _ to hold the let's init value
    val js-underscore = "_ = " ++ binding-name ++ ";\n"
    val new-vals = state.vals.filter(fn((n, _v, _t)) n != binding-name && n != "_") ++ [(binding-name, init, init-type), ("_", init, init-type)]
    state(vals = new-vals, js-defs = state.js-defs ++ js ++ js-underscore)

// Evaluate a bare expression in the REPL
fun repl-eval-expr( expr : node, prelude : program, state : repl-state )
  val wrapped = wrap-with-vals(state.vals, expr)
  val wrapper = Fun-decl(no-span, "__repl_expr", [], wrapped)
  val merged = Program(prelude.structs ++ state.structs,
                       types = prelude.types ++ state.types,
                       decls = prelude.decls ++ state.decls ++ [wrapper])
  val desugared = desugar-program(merged)
  val (typed-prog, diags) = collect-diagnostics
    run-fresh
      check-program(desugared)
  val errors = diags.filter(fn(dia) match dia.severity { Error -> True; _ -> False })
  if !errors.is-empty then
    errors.foreach(fn(dia) println(render-diagnostic(expr.show, "<repl>", dia)))
    state
  else
    val typed-body = typed-prog.decls.last.default(wrapper).body
    val typed-expr = unwrap-vals(state.vals, typed-body)
    val expr-type = typed-expr.typ
    val js-snippet = emit-js-repl-expr(typed-expr)
    val full-js = emit-js-repl-preamble() ++ state.js-defs ++ js-snippet
    repl-run-js(full-js)
    // Store _ with TYPE (use dummy init since _ may self-reference)
    val js-assign = "_ = " ++ emit-js-expr(typed-expr) ++ ";\n"
    val new-vals = state.vals.filter(fn((n, _v, _t)) n != "_") ++ [("_", expr, expr-type)]
    state(vals = new-vals, js-defs = state.js-defs ++ js-assign)

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

fun repl-run-js( js-code : string )
  // Write to a temp file and run with node, capturing output
  val tmp-js = "/tmp/hica-repl-eval.js".path
  val tmp-out = "/tmp/hica-repl-out.txt".path
  write-text-file(tmp-js, js-code)
  val exit-code = run-system("node " ++ tmp-js.show ++ " > " ++ tmp-out.show ++ " 2>&1")
  if exit-code == 0 then
    if is-file(tmp-out) then
      val output = read-text-file(tmp-out)
      if !output.trim.is-empty then
        output.trim.lines.foreach(fn(l) println(l))
  else
    if is-file(tmp-out) then
      val output = read-text-file(tmp-out)
      println("  error: " ++ output.trim)

// ---------------------------------------------------------------------------
// Prelude: load .hc library files written in Hica
// ---------------------------------------------------------------------------

val prelude-files = ["prelude/math.hc", "prelude/operators.hc", "prelude/glob.hc", "prelude/lists.hc", "prelude/strings.hc", "prelude/datetime.hc", "prelude/cli.hc", "prelude/io.hc", "prelude/actors.hc"]

fun load-prelude()
  var decl-result : list<fun-decl> := []
  var struct-result : list<struct-def> := []
  var type-result : list<type-def> := []
  val base = app-path().nobase
  prelude-files.foreach fn(f)
    val fp = (base / f).string
    if is-file(fp.path) then
      val source = read-text-file(fp.path)
      val tokens = lex(source)
      val prog = run-parser-program(tokens, source)
      decl-result := decl-result ++ prog.decls
      struct-result := struct-result ++ prog.structs
      type-result := type-result ++ prog.types
  Program(struct-result, type-result, decl-result)

// ---------------------------------------------------------------------------
// Build pipeline: read .hc → lex → parse → emit → write .kk
// ---------------------------------------------------------------------------

fun build( file : string, opt-level : string = "2", extra-includes : list<string> = [], koka-flags : string = "" )
  val stem = file.path.stemname
  val mod-name = safe-module-name(stem)
  val dir  = file.path.dirname
  val source = read-text-file(file.path)
  val tokens = lex(source)
  val prog   = run-parser-program(tokens, source)
  // Load prelude .hc files and merge with user program
  val prelude = load-prelude()
  // Compile imported modules and collect pub declarations
  val (imported-decls, imported-structs, imported-types, imported-names) = compile-imports(prog.imports, dir.path, [file])
  val merged = Program(prelude.structs ++ imported-structs ++ prog.structs,
                       types = prelude.types ++ imported-types ++ prog.types,
                       decls = prelude.decls ++ imported-decls ++ prog.decls,
                       imports = prog.imports)
  // Desugar
  val desugared = desugar-program(merged)
  // Type check
  val (typed-prog, diags) = collect-diagnostics
    run-fresh
      check-program(desugared)
  val warnings = diags.filter(fn(d) match d.severity { Warning -> True; _ -> False })
  val errors = diags.filter(fn(d) match d.severity { Error -> True; _ -> False })
  warnings.foreach(fn(d) println(render-diagnostic(source, file, d)))
  if !errors.is-empty then
    errors.foreach(fn(d) println(render-diagnostic(source, file, d)))
    println("build: " ++ errors.length.show ++ " type error(s)")
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
  val koka-code = emit-program(user-prog, mod-name, imported-names = imported-names, source = source, prelude-count = prelude-count)
  val out-kk  = dir.path / (mod-name ++ ".kk").path
  write-kk-if-changed(out-kk, koka-code, file)
  val inc-dirs = import-dirs(prog.imports, dir.path) ++ extra-includes
  compile-koka(file, mod-name, inc-dirs, opt-level, koka-flags)

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
fun resolve-import( imp-path : string, base-dir : path ) : path
  base-dir / (imp-path ++ ".hc").path

// Compile all imports and return (pub-decls, pub-structs, pub-types, pub-names)
fun compile-imports( imp-list : list<import-decl>, base-dir : path, visited : list<string> )
  imp-list.foldl(([], [], [], []), fn(acc, imp)
    val (prev-decls, prev-structs, prev-types, prev-names) = acc
    // Extern imports pass through to Koka — skip .hc resolution
    if imp.is-extern then acc
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
        // Compile the imported module to .kk
        compile-module(imp-file, visited)
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
        val (re-decls, re-structs, re-types, re-names) = compile-imports(pub-reimports, imp-dir, Cons(imp-path-str, visited))
        (prev-decls ++ filtered-decls ++ re-decls, prev-structs ++ mod-prog.structs ++ re-structs, prev-types ++ mod-prog.types ++ re-types, prev-names ++ filtered-names ++ re-names)
  )

// Compile a single imported module to a .kk file
fun compile-module( imp-file : path, visited : list<string> )
  val stem = imp-file.stemname
  val mod-name = safe-module-name(stem)
  val dir = imp-file.dirname
  val source = read-text-file(imp-file)
  val tokens = lex(source)
  val prog = run-parser-program(tokens, source)
  // Load prelude for this module
  val prelude = load-prelude()
  // Recursively compile this module's imports
  val imp-path-str = imp-file.show
  val (imp-decls, imp-structs, imp-types, imp-names) = compile-imports(prog.imports, dir.path, Cons(imp-path-str, visited))
  val merged = Program(prelude.structs ++ imp-structs ++ prog.structs,
                       types = prelude.types ++ imp-types ++ prog.types,
                       decls = prelude.decls ++ imp-decls ++ prog.decls,
                       imports = prog.imports)
  // Desugar
  val desugared = desugar-program(merged)
  // Type check
  val (typed-prog, diags) = collect-diagnostics
    run-fresh
      check-program(desugared)
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
  val koka-code = emit-program(user-prog, mod-name, imported-names = imp-names, source = source, prelude-count = prelude-count)
  val out-kk = dir.path / (mod-name ++ ".kk").path
  write-kk-if-changed(out-kk, koka-code, imp-file.show)

// ---------------------------------------------------------------------------
// Compile: invoke koka to compile the generated file into a binary
// ---------------------------------------------------------------------------

fun compile-koka( file : string, mod-name : string, include-dirs : list<string> = [], opt-level : string = "2", koka-flags : string = "" )
  val dir  = file.path.dirname
  val kk-file = (dir.path / (mod-name ++ ".kk").path).show
  val out-bin = (dir.path / (mod-name ++ exe-ext()).path).show
  val inc-flags = include-dirs.map(fn(d) " -i" ++ d).join("")
  val opt-flag = "-O" ++ opt-level
  val extra = if koka-flags.is-empty then "" else " " ++ koka-flags
  val exit-code = run-system("koka " ++ opt-flag ++ " -v0 -o " ++ out-bin ++ inc-flags ++ extra ++ " " ++ kk-file ++ dev-null())
  if exit-code != 0 then
    // Re-run with output visible so the user sees the error
    val _ = run-system("koka " ++ opt-flag ++ " -v0 -o " ++ out-bin ++ inc-flags ++ extra ++ " " ++ kk-file)
    println("error: koka failed with exit code " ++ exit-code.show)
  else
    if !is-windows() then
      val _ = run-system("chmod 0755 " ++ out-bin)
      ()

// ---------------------------------------------------------------------------
// Run: execute the compiled binary
// ---------------------------------------------------------------------------

fun run-koka( file : string, user-args : list<string> = [] )
  val stem = file.path.stemname
  val mod-name = safe-module-name(stem)
  val dir  = file.path.dirname
  val bin-file = (dir.path / (mod-name ++ exe-ext()).path).show
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
  val bin-file = (dir.path / (mod-name ++ exe-ext()).path).show
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

val manifest-name = "hica.ini"

fun resolve-entry() : <fsys,exn,div> maybe<string>
  if is-file(manifest-name.path) then
    val content = read-text-file(manifest-name.path)
    ini-field(content, "entry")
  else Nothing

// Read [description] section from hica.ini
fun read-manifest-description() : <fsys,exn,div> (string, string, string, string)
  if is-file(manifest-name.path) then
    val content = read-text-file(manifest-name.path)
    val summary    = match ini-field(content, "summary")    { Just(s) -> s; Nothing -> "" }
    val author     = match ini-field(content, "author")     { Just(s) -> s; Nothing -> "" }
    val homepage   = match ini-field(content, "homepage")   { Just(s) -> s; Nothing -> "" }
    val repository = match ini-field(content, "repository") { Just(s) -> s; Nothing -> "" }
    (summary, author, homepage, repository)
  else ("", "", "", "")

// Read [koka] section from hica.ini: include dirs and extra flags
fun read-manifest-koka() : <fsys,exn,div> (list<string>, string)
  if is-file(manifest-name.path) then
    val content = read-text-file(manifest-name.path)
    val includes = match ini-field(content, "include")
      Just(s) -> s.split(";").map(fn(p) p.trim).filter(fn(p) !p.is-empty)
      Nothing -> []
    val flags = match ini-field(content, "flags")
      Just(s) -> s
      Nothing -> ""
    (includes, flags)
  else ([], "")

fun ini-field( content : string, key : string ) : div maybe<string>
  // Parse "key = value" or 'key = "value"' lines in a simple ini/toml file
  var result := Nothing
  content.lines.foreach fn(line)
    val trimmed = line.trim
    if trimmed.starts-with(key).bool then
      val rest = trimmed.slice.sslice/drop(key.count).string.trim-left
      if rest.starts-with("=").bool then
        result := Just(rest.slice.sslice/drop(1).string.trim.unquote)
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
  println("    help        Print this message\n")
  println("See 'hica help <command>' for more information on a specific command.")

// ---------------------------------------------------------------------------
// Effect discovery: scan user program for effectful operations
// ---------------------------------------------------------------------------

// Known effectful function → effect name mapping.
val console-fns = ["println", "eprintln"]
val fsys-fns    = ["read_file", "write_file", "read_lines", "write_lines"]
val io-fns      = ["input", "get_args", "get_env"]
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
