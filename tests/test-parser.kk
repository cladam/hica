/*
 * hica – parser unit tests
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
import syntax/parser

// Helper: parse a source string and return the AST as a string
fun parse-show( source : string ) : <div,console> string
  val tokens = lex(source)
  val ast = run-parser(tokens) { parse-expr() }
  ast.show

pub fun main() : io ()
  println(bold("Parser tests"))
  println("")
  defaultKDivHandler
    // --- Literals ---
    dtest("parse integer literal")
      assert/is-true(parse-show("42") == "42")

    dtest("parse boolean literal")
      assert/is-true(parse-show("true") == "True")

    dtest("parse string literal")
      assert/is-true(parse-show("\"hello\"") == "\"hello\"")

    dtest("parse identifier")
      assert/is-true(parse-show("x") == "x")

    // --- Binary expressions ---
    dtest("parse addition")
      assert/is-true(parse-show("1 + 2") == "(1 + 2)")

    dtest("parse multiplication")
      assert/is-true(parse-show("3 * 4") == "(3 * 4)")

    dtest("parse operator precedence: mul binds tighter than add")
      assert/is-true(parse-show("1 + 2 * 3") == "(1 + (2 * 3))")

    dtest("parse left associativity")
      assert/is-true(parse-show("1 + 2 + 3") == "((1 + 2) + 3)")

    dtest("parse comparison")
      assert/is-true(parse-show("1 == 2") == "(1 == 2)")

    dtest("parse logical and")
      assert/is-true(parse-show("true && false") == "(True && False)")

    // --- Unary expressions ---
    dtest("parse negation")
      assert/is-true(parse-show("-5") == "-5")

    dtest("parse not")
      assert/is-true(parse-show("!true") == "!True")

    // --- Let bindings ---
    dtest("parse let binding")
      assert/is-true(parse-show("let x = 42; x") == "let x = 42; x")

    dtest("parse let with expression")
      assert/is-true(parse-show("let x = 1 + 2; x") == "let x = (1 + 2); x")

    // --- Functions ---
    dtest("parse arrow function")
      assert/is-true(parse-show("fn(x) => x + 1") == "fun(x) => (x + 1)")

    dtest("parse multi-param function")
      assert/is-true(parse-show("fn(a, b) => a + b") == "fun(a, b) => (a + b)")

    // --- Parenthesised expressions ---
    dtest("parse parenthesised expression")
      assert/is-true(parse-show("(1 + 2)") == "(1 + 2)")

    dtest("parse parentheses override precedence")
      assert/is-true(parse-show("(1 + 2) * 3") == "((1 + 2) * 3)")
