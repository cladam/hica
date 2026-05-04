/*
 * hica – parser unit tests
 * 
 * This source file is part of the hica open source project
 * Copyright (C) 2026 Claes Adamsson <claes.adamsson@gmail.com>
 *
 * See https://github.com/cladam/hica/blob/main/LICENSE for license information
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

    itest("parse modulo")
      assert/is-true(parse-show("10 % 3") == "(10 % 3)")

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
      assert/is-true(parse-show("(x) => x + 1") == "fun(x) => (x + 1)")

    itest("parse multi-param function")
      assert/is-true(parse-show("(a, b) => a + b") == "fun(a, b) => (a + b)")

    itest("parse zero-param function")
      assert/is-true(parse-show("() => 42") == "fun() => 42")

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

    // --- String literal patterns ---
    itest("parse match with string patterns")
      val result = parse-show("match x { \"yes\" => 1, \"no\" => 0, _ => -1 }")
      assert/is-true(result.contains("match"))
      assert/is-true(result.contains("\"yes\""))
      assert/is-true(result.contains("\"no\""))

    // --- String interpolation ---
    itest("parse string interpolation with variable")
      val result = parse-show("\"hello {name}\"")
      assert/is-true(result.contains("hello"))
      assert/is-true(result.contains("name"))

    itest("parse string interpolation with expression")
      val result = parse-show("\"sum: {a + b}\"")
      assert/is-true(result.contains("sum:"))
      assert/is-true(result.contains("+"))

    itest("parse string interpolation multiple holes")
      val result = parse-show("\"{x} and {y}\"")
      assert/is-true(result.contains("and"))

    itest("parse plain string still works")
      val result = parse-show("\"hello\"")
      assert/is-true(result == "\"hello\"")

    // --- Pipe operator ---
    itest("parse pipe operator desugars to call")
      val result = parse-show("42 |> f")
      assert/is-true(result == "f(42)")

    itest("parse chained pipe operators")
      val result = parse-show("1 |> f |> g")
      assert/is-true(result == "g(f(1))")

    itest("parse pipe with expression")
      val result = parse-show("1 + 2 |> f")
      assert/is-true(result == "f((1 + 2))")

    // --- Float literals ---
    itest("parse float literal")
      val result = parse-show("3.14")
      assert/is-true(result == "3.14")

    itest("parse float arithmetic")
      val result = parse-show("1.5 + 2.5")
      assert/is-true(result == "(1.5 + 2.5)")

    itest("parse negative float")
      val result = parse-show("-3.14")
      assert/is-true(result == "-3.14")

    // --- Tuples ---
    itest("parse tuple literal")
      val result = parse-show("(1, 2)")
      assert/is-true(result == "(1, 2)")

    itest("parse triple")
      val result = parse-show("(1, 2, 3)")
      assert/is-true(result == "(1, 2, 3)")

    itest("parse tuple index")
      val result = parse-show("x.0")
      assert/is-true(result == "x.0")

    itest("parse tuple index .1")
      val result = parse-show("x.1")
      assert/is-true(result == "x.1")

    itest("parse tuple literal then index")
      val result = parse-show("(1, 2).0")
      assert/is-true(result == "(1, 2).0")

    itest("parse let tuple destructuring")
      val result = parse-show("let (a, b) = (1, 2); a")
      assert/is-true(result == "let (a, b) = (1, 2); a")

    itest("parse parenthesised expr not tuple")
      val result = parse-show("(42)")
      assert/is-true(result == "42")

    // --- Tuple patterns in match ---
    itest("parse match with tuple pattern")
      val result = parse-show("match t { (a, b) => a }")
      assert/is-true(result.contains("(a, b)"))

    itest("parse match with triple pattern")
      val result = parse-show("match t { (a, b, c) => a }")
      assert/is-true(result.contains("(a, b, c)"))

    itest("parse match with tuple wildcard")
      val result = parse-show("match t { (_, b) => b }")
      assert/is-true(result.contains("(_, b)"))

    // --- Lists ---
    itest("parse empty list")
      assert/is-true(parse-show("[]") == "[]")

    itest("parse list literal")
      assert/is-true(parse-show("[1, 2, 3]") == "[1, 2, 3]")

    itest("parse single element list")
      assert/is-true(parse-show("[42]") == "[42]")

    itest("parse list with expressions")
      assert/is-true(parse-show("[1 + 2, 3 * 4]") == "[(1 + 2), (3 * 4)]")

    // --- List indexing ---
    itest("parse list index")
      assert/is-true(parse-show("[1, 2, 3][0]") == "[1, 2, 3][0]")

    itest("parse variable list index")
      assert/is-true(parse-show("xs[1]") == "xs[1]")

    itest("parse list index with expression")
      assert/is-true(parse-show("xs[i + 1]") == "xs[(i + 1)]")

    // --- List slicing ---
    itest("parse list slice start:end")
      assert/is-true(parse-show("xs[1:3]") == "xs[1:3]")

    itest("parse list slice :end")
      assert/is-true(parse-show("xs[:2]") == "xs[:2]")

    itest("parse list slice start:")
      assert/is-true(parse-show("xs[2:]") == "xs[2:]")

    // --- For loop ---
    itest("parse for-in loop")
      val result = parse-show("for i in 0..10 { println(i) }")
      assert/is-true(result == "for i in 0..10 { println(i) }")

    itest("parse for-in with expressions")
      val result = parse-show("for x in 1..n { x }")
      assert/is-true(result == "for x in 1..n { x }")

    // --- While loop ---
    itest("parse while loop")
      val result = parse-show("while true { 42 }")
      assert/is-true(result == "while True { 42 }")

    itest("parse while with comparison")
      val result = parse-show("while x > 0 { x }")
      assert/is-true(result.contains("while"))
      assert/is-true(result.contains(">"))

    // --- In operator ---
    itest("parse in operator")
      assert/is-true(parse-show("3 in xs") == "(3 in xs)")

    itest("parse in with list literal")
      assert/is-true(parse-show("x in [1, 2, 3]") == "(x in [1, 2, 3])")

    // --- Char literals ---
    itest("parse char literal")
      assert/is-true(parse-show("'a'") == "'a'")

    itest("parse char in list")
      assert/is-true(parse-show("['a', 'b', 'c']") == "['a', 'b', 'c']")

    itest("parse char equality")
      assert/is-true(parse-show("'x' == 'y'") == "('x' == 'y')")

    // --- Maybe: Some / None ---
    itest("parse Some expression")
      assert/is-true(parse-show("Some(42)") == "Some(42)")

    itest("parse None expression")
      assert/is-true(parse-show("None") == "None")

    itest("parse Some with variable")
      assert/is-true(parse-show("Some(x)") == "Some(x)")

    itest("parse match with Some/None patterns")
      val result = parse-show("match x { Some(n) => n, None => 0 }")
      assert/is-true(result.contains("Some(n)"))
      assert/is-true(result.contains("None"))

    // --- Result: Ok / Err ---
    itest("parse Ok expression")
      assert/is-true(parse-show("Ok(42)") == "Ok(42)")

    itest("parse Err expression")
      assert/is-true(parse-show("Err(\"oops\")") == "Err(\"oops\")")

    itest("parse match with Ok/Err patterns")
      val result = parse-show("match x { Ok(n) => n, Err(e) => 0 }")
      assert/is-true(result.contains("Ok(n)"))
      assert/is-true(result.contains("Err(e)"))

    // --- Structs ---
    itest("parse struct declaration")
      val result = parse-program-show("struct Point { x: int, y: int } fun main() => 0")
      assert/is-true(result.contains("struct Point"))

    // --- Match guards ---
    itest("parse match guard")
      val result = parse-show("match n { x if x > 0 => x, _ => 0 }")
      assert/is-true(result.contains("if"))
      assert/is-true(result.contains("x"))

    itest("parse match guard with constructor")
      val result = parse-show("match v { Some(n) if n < 0 => 0, _ => 1 }")
      assert/is-true(result.contains("Some(n)"))
      assert/is-true(result.contains("if"))

    itest("parse match without guard unchanged")
      val result = parse-show("match x { 0 => 1, _ => 2 }")
      assert/is-true(!result.contains("if"))

    itest("parse struct literal")
      val result = parse-program-show("struct Point { x: int, y: int } fun main() => Point { x: 1, y: 2 }")
      assert/is-true(result.contains("Point"))

    itest("parse field access")
      val result = parse-program-show("struct Point { x: int, y: int } fun main() { let p = Point { x: 1, y: 2 }; p.x }")
      assert/is-true(result.contains(".x"))
