// Hica — Compiler Entry Point
// Lexes, parses, checks, and emits Koka from .hc source files.
module main

import syntax/ast
import syntax/lexer
import syntax/parser
import semantics/checker
import emit/codegen

fun main()
  val source = "let x = 2 + 3; x"
  println("hica compiler v0.1.0\n")
  println("source: " ++ source)

  // Lex
  val tokens = lex(source)
  println("\ntokens: " ++ tokens.map(show).join(" "))

  // Parse
  val ast = run-parser(tokens) { parse-expr() }
  println("\nAST: " ++ ast.show)

  // Check (stub)
  val checked = check(ast)

  // Emit Koka
  val koka-code = emit(checked)
  println("\n--- Koka output ---")
  println(koka-code)
