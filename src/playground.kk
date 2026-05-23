/*
 * hica – playground compiler (browser target)
 * 
 * This source file is part of the hica open source project
 * Copyright (C) 2026 Claes Adamsson <claes.adamsson@gmail.com>
 *
 * See https://github.com/cladam/hica/blob/main/LICENSE for license information
 *
 * Compiles hica source to standalone JavaScript entirely in-memory.
 * No file I/O — designed to run in the browser via Koka's JS backend.
 * The JS runtime preamble provides all prelude functions at runtime;
 * the prelude .hc sources are passed in so the type checker knows signatures.
*/
module playground

import syntax/ast
import syntax/lexer
import syntax/parser
import diagnostics/diagnostics
import semantics/checker
import transform/desugar
import emit/codegen-js

// Parse prelude source strings into a merged Program (structs + types + decls)
fun parse-prelude-sources( sources : list<string> ) : <div,console> program
  var decl-result : list<fun-decl> := []
  var struct-result : list<struct-def> := []
  var type-result : list<type-def> := []
  sources.foreach fn(src)
    val tokens = lex(src)
    val prog = run-parser-program(tokens, src)
    decl-result := decl-result ++ prog.decls
    struct-result := struct-result ++ prog.structs
    type-result := type-result ++ prog.types
  Program(struct-result, type-result, decl-result)

// Find a stdlib source by module path (e.g. "std/string")
fun find-stdlib-source( path : string, stdlib-sources : list<(string,string)> ) : maybe<string>
  match stdlib-sources
    [] -> Nothing
    Cons((p, s), rest) -> if p == path then Just(s) else find-stdlib-source(path, rest)

// Parse stdlib imports referenced in a program into a single merged Program
fun resolve-stdlib-imports( imports : list<import-decl>, stdlib-sources : list<(string,string)> ) : <div,console> program
  var decl-result : list<fun-decl> := []
  var struct-result : list<struct-def> := []
  var type-result : list<type-def> := []
  imports.foreach fn(imp)
    if imp.path.starts-with("std/").bool then
      match find-stdlib-source(imp.path, stdlib-sources)
        Nothing -> ()
        Just(src) ->
          val tokens = lex(src)
          val prog = run-parser-program(tokens, src)
          decl-result := decl-result ++ prog.decls
          struct-result := struct-result ++ prog.structs
          type-result := type-result ++ prog.types
  Program(struct-result, type-result, decl-result)

// Compile hica source code to JavaScript.
// Returns Right(js-code) on success, Left(error-messages) on failure.
// `prelude-sources` is a list of prelude .hc file contents (for type checking).
// `stdlib-sources` is a list of (module-path, source) pairs for std/ imports.
pub fun compile-to-js( source : string, prelude-sources : list<string> = [], stdlib-sources : list<(string,string)> = [] ) : <div,console> either<string, string>
  val tokens = lex(source)
  val prog = run-parser-program(tokens, source)
  val prelude = parse-prelude-sources(prelude-sources)
  val stdlib  = resolve-stdlib-imports(prog.imports, stdlib-sources)
  val merged = Program(prelude.structs ++ stdlib.structs ++ prog.structs,
                       types = prelude.types ++ stdlib.types ++ prog.types,
                       decls = prelude.decls ++ stdlib.decls ++ prog.decls)
  val desugared = desugar-program(merged)
  val (typed-prog, diags) = collect-diagnostics
    run-fresh
      check-program(desugared, prelude.decls.length, prelude.structs.length, prelude.types.length)
  val errors = diags.filter(fn(d) match d.severity { Error -> True; _ -> False })
  if !errors.is-empty then
    val msgs = errors.map(fn(d) render-diagnostic(source, "<playground>", d))
    Left(msgs.join("\n"))
  else
    // stdlib decls are emitted as part of user output (not in JS preamble)
    val prelude-count = prelude.decls.length
    val user-typed-decls = typed-prog.decls.drop(prelude-count)
    val prelude-struct-count = prelude.structs.length
    val user-structs = typed-prog.structs.drop(prelude-struct-count)
    val prelude-type-count = prelude.types.length
    val user-types = typed-prog.types.drop(prelude-type-count)
    val user-prog = typed-prog(decls = user-typed-decls, structs = user-structs, types = user-types)
    Right(emit-js-program(user-prog))

fun main()
  val source = "fun main() {\n  println(\"Hello from the hica playground!\")\n}\n"
  match compile-to-js(source)
    Right(js) -> println(js)
    Left(err) -> println("ERROR:\n" ++ err)
