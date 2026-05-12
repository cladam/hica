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

import syntax/ast
import syntax/lexer
import syntax/parser
import diagnostics/diagnostics
import semantics/checker
import emit/codegen
import transform/desugar
import format/formatter
import klap

val version = "0.11.0" 

// Clean process exit without throwing exceptions
extern hica-exit( code : int ) : a
  c inline "(exit(kk_integer_clamp32(#1, kk_context())), kk_box_null())"

fun hica-cli() : command
  command("hica")
    .version(version)
    .about("The hica compiler")
    .arg(positional("COMMAND").help("Command to run").required)
    .arg(positional("FILE").help("Source .hc file"))
    .arg(flag("check").help("Check formatting without modifying the file"))
    .subcommand("build, b", "Compile a .hc file and build a binary")
    .subcommand("run, r", "Compile and run a .hc file")
    .subcommand("check, c", "Analyse a .hc file and report errors")
    .subcommand("fmt, f", "Format a .hc file")
    .subcommand("clean", "Remove generated build artifacts")
    .subcommand("test, t", "Run tests in a .hc file")
    .subcommand("new", "Create a new hica project")
    .subcommand("init", "Initialise a hica project in the current directory")
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
    _ ->
      val resolved = match file
        Just(f) -> Just(f)
        Nothing -> resolve-entry()
      match resolved
        Just(f) ->
          match cmd
            "build" -> cmd-build(f)
            "b"     -> cmd-build(f)
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

fun cmd-build( file : string )
  build(file)

fun cmd-run( file : string, user-args : list<string> )
  build(file)
  run-koka(file, user-args)

fun cmd-check( file : string )
  val source = read-text-file(file.path)
  val tokens = lex(source)
  val prog   = run-parser-program(tokens)
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
  val stem = file.path.stemname
  val mod-name = safe-module-name(stem)
  val dir  = file.path.dirname
  val source = read-text-file(file.path)
  val tokens = lex(source)
  val prog   = run-parser-program(tokens)
  if prog.tests.is-empty then
    println("no tests found in " ++ file)
  else
    // Load prelude and merge
    val prelude = load-prelude()
    val (imported-decls, imported-structs, imported-types, _) = compile-imports(prog.imports, dir.path, [file])
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
      val koka-code = emit-test-program(typed-prog, mod-name)
      val out-kk  = dir.path / (mod-name ++ ".kk").path
      write-text-file(out-kk, koka-code)
      compile-koka(file, mod-name)
      run-tests(file)

fun cmd-clean( file : string )
  val stem = file.path.stemname
  val mod-name = safe-module-name(stem)
  val dir  = file.path.dirname
  val kk-file = dir.path / (mod-name ++ ".kk").path
  val bin-file = dir.path / mod-name.path
  var cleaned := False
  if is-file(kk-file) then
    val contents = read-text-file(kk-file)
    if contents.starts-with("// Generated by hica").bool then
      val _ = run-system("rm -f " ++ kk-file.show)
      println("removed " ++ kk-file.show)
      cleaned := True
    else
      println("skipping " ++ kk-file.show ++ " (not generated by hica)")
  if is-file(bin-file) && cleaned then
    val _ = run-system("rm -f " ++ bin-file.show)
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
    "entry = \"main.hc\""
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
// Prelude: load .hc library files written in Hica
// ---------------------------------------------------------------------------

val prelude-files = ["prelude/math.hc", "prelude/operators.hc", "prelude/strings.hc", "prelude/cli.hc", "prelude/io.hc"]

fun load-prelude()
  var decl-result : list<fun-decl> := []
  var struct-result : list<struct-def> := []
  var type-result : list<type-def> := []
  prelude-files.foreach fn(f)
    if is-file(f.path) then
      val source = read-text-file(f.path)
      val tokens = lex(source)
      val prog = run-parser-program(tokens)
      decl-result := decl-result ++ prog.decls
      struct-result := struct-result ++ prog.structs
      type-result := type-result ++ prog.types
  Program(struct-result, type-result, decl-result)

// ---------------------------------------------------------------------------
// Build pipeline: read .hc → lex → parse → emit → write .kk
// ---------------------------------------------------------------------------

fun build( file : string )
  val stem = file.path.stemname
  val mod-name = safe-module-name(stem)
  val dir  = file.path.dirname
  val source = read-text-file(file.path)
  val tokens = lex(source)
  val prog   = run-parser-program(tokens)
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
  // Emit main module — keep prelude + user decls, skip imported decl definitions
  val prelude-count = prelude.decls.length
  val imported-count = imported-decls.length
  val user-typed-decls = typed-prog.decls.take(prelude-count) ++ typed-prog.decls.drop(prelude-count + imported-count)
  val user-prog = typed-prog(decls = user-typed-decls, imports = prog.imports)
  val koka-code = emit-program(user-prog, mod-name, imported-names = imported-names)
  val out-kk  = dir.path / (mod-name ++ ".kk").path
  write-text-file(out-kk, koka-code)
  println("compiled " ++ file ++ " -> " ++ out-kk.show)
  compile-koka(file, mod-name)

// ---------------------------------------------------------------------------
// Import resolution: compile imported modules, collect pub declarations
// ---------------------------------------------------------------------------

// Resolve an import path relative to a directory → absolute .hc file path
fun resolve-import( imp-path : string, base-dir : path ) : path
  base-dir / (imp-path ++ ".hc").path

// Compile all imports and return (pub-decls, pub-structs, pub-types, pub-names)
fun compile-imports( imports : list<import-decl>, base-dir : path, visited : list<string> )
  imports.foldl(([], [], [], []), fn(acc, imp)
    val (prev-decls, prev-structs, prev-types, prev-names) = acc
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
      (prev-decls ++ filtered-decls, prev-structs ++ mod-prog.structs, prev-types ++ mod-prog.types, prev-names ++ filtered-names)
  )

// Compile a single imported module to a .kk file
fun compile-module( imp-file : path, visited : list<string> )
  val stem = imp-file.stemname
  val mod-name = safe-module-name(stem)
  val dir = imp-file.dirname
  val source = read-text-file(imp-file)
  val tokens = lex(source)
  val prog = run-parser-program(tokens)
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
  // Emit module .kk — keep prelude + user decls, skip imported decl definitions
  val prelude-count = prelude.decls.length
  val imp-imported-count = imp-decls.length
  val user-typed-decls = typed-prog.decls.take(prelude-count) ++ typed-prog.decls.drop(prelude-count + imp-imported-count)
  val user-prog = typed-prog(decls = user-typed-decls, imports = prog.imports)
  val koka-code = emit-program(user-prog, mod-name, imported-names = imp-names)
  val out-kk = dir.path / (mod-name ++ ".kk").path
  write-text-file(out-kk, koka-code)
  println("compiled " ++ imp-file.show ++ " -> " ++ out-kk.show)

// ---------------------------------------------------------------------------
// Compile: invoke koka to compile the generated file into a binary
// ---------------------------------------------------------------------------

fun compile-koka( file : string, mod-name : string )
  val dir  = file.path.dirname
  val kk-file = (dir.path / (mod-name ++ ".kk").path).show
  val out-bin = (dir.path / mod-name.path).show
  val exit-code = run-system("koka -O2 -v0 -o " ++ out-bin ++ " " ++ kk-file ++ " >/dev/null 2>&1")
  if exit-code != 0 then
    // Re-run with output visible so the user sees the error
    val _ = run-system("koka -O2 -v0 -o " ++ out-bin ++ " " ++ kk-file)
    println("error: koka failed with exit code " ++ exit-code.show)
  else
    val _ = run-system("chmod 0755 " ++ out-bin)
    ()

// ---------------------------------------------------------------------------
// Run: execute the compiled binary
// ---------------------------------------------------------------------------

fun run-koka( file : string, user-args : list<string> = [] )
  val stem = file.path.stemname
  val mod-name = safe-module-name(stem)
  val dir  = file.path.dirname
  val bin-file = (dir.path / mod-name.path).show
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
  val bin-file = (dir.path / mod-name.path).show
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
