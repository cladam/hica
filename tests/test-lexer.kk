/*
 * hica – lexer unit tests
 * 
 * This source file is part of the hica open source project
 * Copyright (C) 2026 Claes Adamsson <claes.adamsson@gmail.com>
 *
 * See https://github.com/cladam/hica/blob/main/LICENSE for license information
*/
import kunit
import syntax/ast
import syntax/lexer

// Helper: lex source and join token strings with spaces for easy comparison
fun token-string( source : string ) : div string
  lex(source).map(fn(t) t.kind.show).join(" ")

pub fun main() : io ()
  println(bold("Lexer tests"))
  println("")
  defaultKDivHandler
    // --- Literals ---
    dtest("lex integer literal")
      assert/is-true(token-string("42") == "42 <eof>")

    dtest("lex boolean true")
      assert/is-true(token-string("true") == "True <eof>")

    dtest("lex boolean false")
      assert/is-true(token-string("false") == "False <eof>")

    dtest("lex string literal")
      assert/is-true(token-string("\"hello\"") == "\"hello\" <eof>")

    // --- Keywords ---
    dtest("lex keywords")
      assert/is-true(token-string("let fn fun if else match repeat") == "let fn fun if else match repeat <eof>")

    // --- Identifiers ---
    dtest("lex identifier")
      assert/is-true(token-string("foo") == "foo <eof>")

    dtest("lex identifier with underscore")
      assert/is-true(token-string("my_var") == "my_var <eof>")

    // --- Operators ---
    dtest("lex arithmetic operators")
      assert/is-true(token-string("+ - * / %") == "+ - * / % <eof>")

    dtest("lex comparison operators")
      assert/is-true(token-string("== != < > <= >=") == "== != < > <= >= <eof>")

    dtest("lex logical operators")
      assert/is-true(token-string("&& ||") == "&& || <eof>")

    dtest("lex arrow operators")
      assert/is-true(token-string("=> ->") == "=> -> <eof>")

    // --- Punctuation ---
    dtest("lex punctuation")
      assert/is-true(token-string("( ) { } , ; :") == "( ) { } , ; : <eof>")

    // --- Compound expressions ---
    dtest("lex let binding")
      assert/is-true(token-string("let x = 42") == "let x = 42 <eof>")

    dtest("lex function definition")
      assert/is-true(token-string("fn(a, b) => a + b") == "fn ( a , b ) => a + b <eof>")

    // --- Whitespace and comments ---
    dtest("lex ignores whitespace")
      assert/is-true(token-string("  42  ") == "42 <eof>")

    dtest("lex ignores line comments")
      assert/is-true(token-string("42 // this is a comment\n7") == "42 7 <eof>")

    // --- Edge cases ---
    dtest("lex empty input")
      assert/is-true(token-string("") == "<eof>")

    dtest("lex unexpected character")
      assert/is-true(token-string("@").contains("error"))

    // --- String interpolation ---
    dtest("lex plain string unchanged")
      assert/is-true(token-string("\"hello\"") == "\"hello\" <eof>")

    dtest("lex interpolated string with variable")
      val result = token-string("\"hello {name}!\"")
      assert/is-true(result == "<interp-start> <part:\"hello \"> <interp-expr> name } <part:\"!\"> <interp-end> <eof>")

    dtest("lex interpolated string at start")
      val result = token-string("\"{x} done\"")
      assert/is-true(result == "<interp-start> <interp-expr> x } <part:\" done\"> <interp-end> <eof>")

    dtest("lex interpolated string at end")
      val result = token-string("\"value: {x}\"")
      assert/is-true(result == "<interp-start> <part:\"value: \"> <interp-expr> x } <interp-end> <eof>")

    dtest("lex interpolated string with expression")
      val result = token-string("\"sum: {a + b}\"")
      assert/is-true(result == "<interp-start> <part:\"sum: \"> <interp-expr> a + b } <interp-end> <eof>")

    dtest("lex interpolated string multiple holes")
      val result = token-string("\"{a} and {b}\"")
      assert/is-true(result == "<interp-start> <interp-expr> a } <part:\" and \"> <interp-expr> b } <interp-end> <eof>")

    // --- Pipe operator ---
    dtest("lex pipe operator")
      assert/is-true(token-string("a |> f") == "a |> f <eof>")

    dtest("lex pipe vs or")
      assert/is-true(token-string("a || b |> f") == "a || b |> f <eof>")

    // --- Float literals ---
    dtest("lex float literal")
      assert/is-true(token-string("3.14") == "3.14 <eof>")

    dtest("lex integer vs float")
      assert/is-true(token-string("42 3.14") == "42 3.14 <eof>")

    dtest("lex float in expression")
      assert/is-true(token-string("1.5 + 2.5") == "1.5 + 2.5 <eof>")

    // --- Dot token ---
    dtest("lex dot")
      assert/is-true(token-string("x.0") == "x . 0 <eof>")

    dtest("lex tuple with dot")
      assert/is-true(token-string("(1, 2).0") == "( 1 , 2 ) . 0 <eof>")

    // --- Lists ---
    dtest("lex list literal")
      assert/is-true(token-string("[1, 2, 3]") == "[ 1 , 2 , 3 ] <eof>")

    dtest("lex empty list")
      assert/is-true(token-string("[]") == "[ ] <eof>")

    // --- For loop ---
    dtest("lex for-in with range")
      assert/is-true(token-string("for i in 0..10") == "for i in 0 .. 10 <eof>")

    dtest("lex dotdot vs dot")
      assert/is-true(token-string("x.0 0..5") == "x . 0 0 .. 5 <eof>")

    // --- Char literals ---
    dtest("lex char literal")
      assert/is-true(token-string("'a'") == "'a' <eof>")

    dtest("lex char in expression")
      assert/is-true(token-string("'x' == 'y'") == "'x' == 'y' <eof>")

    dtest("lex char in list")
      assert/is-true(token-string("['a', 'b']") == "[ 'a' , 'b' ] <eof>")

    // --- Structs ---
    dtest("lex struct keyword")
      assert/is-true(token-string("struct") == "struct <eof>")

    dtest("lex struct declaration")
      assert/is-true(token-string("struct Point { x: int }") == "struct Point { x : int } <eof>")

    // --- Pipe token ---
    dtest("lex bare pipe")
      assert/is-true(token-string("1 | 2") == "1 | 2 <eof>")

    dtest("lex pipe vs pipe-pipe")
      assert/is-true(token-string("a || b | c") == "a || b | c <eof>")
