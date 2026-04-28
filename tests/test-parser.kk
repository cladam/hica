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

// Helper: parse a program and return its AST as a string
fun parse-program-show( source : string ) : <div,console> string
  val tokens = lex(source)
  val prog = run-parser-program(tokens)
  prog.show

pub fun main() : io ()
  println(bold("Parser tests"))
  println("")
  defaultKIntegrationHandler
    // --- Literals ---
    itest("parse integer literal")
      assert/is-true(parse-show("42") == "42")

    itest("parse boolean literal")
      assert/is-true(parse-show("true") == "True")

    itest("parse string literal")
      assert/is-true(parse-show("\"hello\"") == "\"hello\"")

    itest("parse identifier")
      assert/is-true(parse-show("x") == "x")

    // --- Binary expressions ---
    itest("parse addition")
      assert/is-true(parse-show("1 + 2") == "(1 + 2)")

    itest("parse subtraction")
      assert/is-true(parse-show("10 - 5") == "(10 - 5)")

    itest("parse multiplication")
      assert/is-true(parse-show("3 * 4") == "(3 * 4)")

    itest("parse division")
      assert/is-true(parse-show("20 / 4") == "(20 / 4)")

    itest("parse equality")
      assert/is-true(parse-show("a == b") == "(a == b)")

    itest("parse inequality")
      assert/is-true(parse-show("a != b") == "(a != b)")

    itest("parse less than")
      assert/is-true(parse-show("a < b") == "(a < b)")

    itest("parse greater than")
      assert/is-true(parse-show("a > b") == "(a > b)")

    itest("parse less than or equal")
      assert/is-true(parse-show("a <= b") == "(a <= b)")

    itest("parse greater than or equal")
      assert/is-true(parse-show("a >= b") == "(a >= b)")

    itest("parse logical and")
      assert/is-true(parse-show("true && false") == "(True && False)")

    itest("parse logical or")
      assert/is-true(parse-show("true || false") == "(True || False)")

    // --- Operator precedence (from lisette patterns) ---
    itest("precedence: mul binds tighter than add")
      assert/is-true(parse-show("1 + 2 * 3") == "(1 + (2 * 3))")

    itest("precedence: mul before add (reversed)")
      assert/is-true(parse-show("a * b + c") == "((a * b) + c)")

    itest("precedence: add before eq")
      assert/is-true(parse-show("a + b == c") == "((a + b) == c)")

    itest("precedence: eq before and")
      assert/is-true(parse-show("a == b && c") == "((a == b) && c)")

    itest("precedence: and before or")
      assert/is-true(parse-show("a && b || c") == "((a && b) || c)")

    // --- Associativity (from lisette patterns) ---
    itest("left assoc: addition")
      assert/is-true(parse-show("1 + 2 + 3") == "((1 + 2) + 3)")

    itest("left assoc: add-sub chain")
      assert/is-true(parse-show("a + b - c") == "((a + b) - c)")

    itest("left assoc: mul-div chain")
      assert/is-true(parse-show("a * b / c") == "((a * b) / c)")

    // --- Unary expressions ---
    itest("parse negation")
      assert/is-true(parse-show("-5") == "-5")

    itest("parse not")
      assert/is-true(parse-show("!true") == "!True")

    itest("precedence: unary before binary")
      assert/is-true(parse-show("!a && b") == "(!a && b)")

    // --- Parenthesised expressions ---
    itest("parse parenthesised expression")
      assert/is-true(parse-show("(1 + 2)") == "(1 + 2)")

    itest("parens override precedence: add before mul")
      assert/is-true(parse-show("(1 + 2) * 3") == "((1 + 2) * 3)")

    itest("parens override precedence: or before and")
      assert/is-true(parse-show("a && (b || c)") == "(a && (b || c))")

    // --- Let bindings ---
    itest("parse let binding")
      assert/is-true(parse-show("let x = 42; x") == "let x = 42; x")

    itest("parse let with expression")
      assert/is-true(parse-show("let x = 1 + 2; x") == "let x = (1 + 2); x")

    // --- Functions ---
    itest("parse arrow function")
      assert/is-true(parse-show("fn(x) => x + 1") == "fun(x) => (x + 1)")

    itest("parse multi-param function")
      assert/is-true(parse-show("fn(a, b) => a + b") == "fun(a, b) => (a + b)")

    itest("parse zero-param function")
      assert/is-true(parse-show("fn() => 42") == "fun() => 42")

    // --- Function calls (new!) ---
    itest("parse function call no args")
      assert/is-true(parse-show("f()") == "f()")

    itest("parse function call one arg")
      assert/is-true(parse-show("f(42)") == "f(42)")

    itest("parse function call two args")
      assert/is-true(parse-show("f(1, 2)") == "f(1, 2)")

    itest("parse function call with expression arg")
      assert/is-true(parse-show("f(1 + 2)") == "f((1 + 2))")

    itest("parse chained function calls")
      assert/is-true(parse-show("f(1)(2)") == "f(1)(2)")

    itest("parse function call in binary expr")
      assert/is-true(parse-show("f(1) + g(2)") == "(f(1) + g(2))")

    // --- If expressions ---
    itest("parse if-else returning value")
      val result = parse-show("if x { 1 } else { 2 }")
      assert/is-true(result.contains("if"))
      assert/is-true(result.contains("else"))

    itest("parse if-else-if chain")
      val result = parse-show("if x { 1 } else if y { 2 } else { 3 }")
      assert/is-true(result.contains("if"))

    itest("parse if expression in let")
      val result = parse-show("let r = if x { 1 } else { 2 }; r")
      assert/is-true(result.contains("let"))

    // --- Match expressions (new!) ---
    itest("parse match with literals")
      val result = parse-show("match x { 1 => true, 2 => false }")
      assert/is-true(result.contains("match"))

    itest("parse match with wildcard")
      val result = parse-show("match x { 1 => 10, _ => 0 }")
      assert/is-true(result.contains("_"))

    itest("parse match with variable patterns")
      val result = parse-show("match x { n => n }")
      assert/is-true(result.contains("match"))

    // --- Repeat expressions ---
    itest("parse repeat")
      val result = parse-show("repeat(3) { 42 }")
      assert/is-true(result.contains("repeat"))

    itest("parse repeat with expression count")
      val result = parse-show("repeat(1 + 2) { 42 }")
      assert/is-true(result.contains("repeat"))
      assert/is-true(result.contains("+"))

    // --- Block expressions ---
    itest("parse block expression")
      val result = parse-show("{ 1; 2; 3 }")
      assert/is-true(result.contains("{"))

    // --- Top-level fun declarations (new!) ---
    itest("parse simple fun declaration")
      val result = parse-program-show("fun main() { 42 }")
      assert/is-true(result.contains("fun main()"))

    itest("parse arrow fun declaration")
      val result = parse-program-show("fun double(x) => x * 2")
      assert/is-true(result.contains("fun double(x)"))

    itest("parse multiple fun declarations")
      val result = parse-program-show("fun f(x) => x\nfun g(y) => y")
      assert/is-true(result.contains("fun f(x)"))
      assert/is-true(result.contains("fun g(y)"))

    itest("parse fun with function call in body")
      val result = parse-program-show("fun double(x) => x * 2\nfun main() { double(21) }")
      assert/is-true(result.contains("fun double"))
      assert/is-true(result.contains("fun main"))
