/*
 * hica – lexer unit tests
 * Copyright (C) 2026 Claes Adamsson <claes.adamsson@gmail.com>
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE 
 * SOFTWARE.
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
      assert/is-true(token-string("let fn fun if else match") == "let fn fun if else match <eof>")

    // --- Identifiers ---
    dtest("lex identifier")
      assert/is-true(token-string("foo") == "foo <eof>")

    dtest("lex identifier with underscore")
      assert/is-true(token-string("my_var") == "my_var <eof>")

    // --- Operators ---
    dtest("lex arithmetic operators")
      assert/is-true(token-string("+ - * /") == "+ - * / <eof>")

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
