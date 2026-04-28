/*
 * hica – syntax parser
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
module syntax/parser

import syntax/ast
import syntax/lexer

// ---------------------------------------------------------------------------
// Parser state — effect-based
// ---------------------------------------------------------------------------

pub effect parser
  fun peek() : token-kind
  fun advance() : token
  fun current-span() : span
  fun parse-error( msg : string ) : node

// Expect a specific token kind, or emit a parse error.
pub fun expect( expected : string, pred : (token-kind) -> bool ) : <div,parser> token
  val tk = peek()
  if pred(tk) then advance()
  else
    parse-error("expected " ++ expected ++ ", got " ++ tk.show)
    advance()

// ---------------------------------------------------------------------------
// Top-level parsing
// ---------------------------------------------------------------------------

pub fun parse-expr() : <div,parser> node
  parse-binary(0)

// ---------------------------------------------------------------------------
// Pratt expression parsing
// ---------------------------------------------------------------------------

fun parse-prefix() : <div,parser> node
  val tk = peek()
  match tk
    TkInt(n) ->
      val t = advance()
      Node(t.span, Literal(LitInt(n)))
    TkBool(b) ->
      val t = advance()
      Node(t.span, Literal(LitBool(b)))
    TkString(s) ->
      val t = advance()
      Node(t.span, Literal(LitString(s)))
    TkIdent(name) ->
      val t = advance()
      Node(t.span, Var(name))
    TkLParen ->
      advance()
      val e = parse-expr()
      expect(")", fn(k) match k { TkRParen -> True; _ -> False })
      e
    TkLBrace ->
      parse-block()
    TkIf ->
      parse-if()
    TkFn ->
      parse-fn()
    TkLet ->
      parse-let()
    TkMatch ->
      parse-match()
    TkMinus ->
      val t = advance()
      val operand = parse-prefix()
      Node(Span(t.span.start, operand.span.end), Unary(Neg, operand))
    TkBang ->
      val t = advance()
      val operand = parse-prefix()
      Node(Span(t.span.start, operand.span.end), Unary(Not, operand))
    _ ->
      parse-error("unexpected token: " ++ tk.show)

fun infix-bp( tk : token-kind ) : maybe<(int, int, binop)>
  match tk
    TkPipePipe -> Just((1, 2, Or))
    TkAmpAmp   -> Just((3, 4, And))
    TkEqEq     -> Just((5, 6, Eq))
    TkBangEq   -> Just((5, 6, Neq))
    TkLt       -> Just((7, 8, Lt))
    TkGt       -> Just((7, 8, Gt))
    TkLe       -> Just((7, 8, Le))
    TkGe       -> Just((7, 8, Ge))
    TkPlus     -> Just((9, 10, Add))
    TkMinus    -> Just((9, 10, Sub))
    TkStar     -> Just((11, 12, Mul))
    TkSlash    -> Just((11, 12, Div))
    _          -> Nothing

// Pratt parser: parse binary expressions with binding power.
fun parse-binary( min-bp : int ) : <div,parser> node
  val lhs = parse-postfix()
  parse-binary-loop(lhs, min-bp)

// Parse postfix operations: function calls f(args)
fun parse-postfix() : <div,parser> node
  var result := parse-prefix()
  while { match peek() { TkLParen -> True; _ -> False } }
    advance()
    val args = parse-args()
    val end-tok = expect(")", fn(k) match k { TkRParen -> True; _ -> False })
    result := Node(Span(result.span.start, end-tok.span.end), Call(result, args))
  result

fun parse-args() : <div,parser> list<node>
  match peek()
    TkRParen -> []
    _ ->
      val first = parse-expr()
      match peek()
        TkComma -> { advance(); Cons(first, parse-args()) }
        _       -> [first]

fun parse-binary-loop( lhs : node, min-bp : int ) : <div,parser> node
  val tk = peek()
  match infix-bp(tk)
    Nothing -> lhs
    Just((l-bp, r-bp, op)) ->
      if l-bp < min-bp then lhs
      else
        advance()
        val rhs = parse-binary(r-bp)
        val combined = Node(Span(lhs.span.start, rhs.span.end), Binary(op, lhs, rhs))
        parse-binary-loop(combined, min-bp)

// ---------------------------------------------------------------------------
// Compound expressions
// ---------------------------------------------------------------------------

fun parse-block() : <div,parser> node
  val t = expect("{", fn(k) match k { TkLBrace -> True; _ -> False })
  var stmts := []
  while { match peek() { TkRBrace -> False; TkEof -> False; _ -> True } }
    stmts := Cons(parse-expr(), stmts)
    // optional semicolons
    match peek()
      TkSemicolon -> { advance(); () }
      _           -> ()
  val end-tok = expect("}", fn(k) match k { TkRBrace -> True; _ -> False })
  Node(Span(t.span.start, end-tok.span.end), Block(stmts.reverse))

fun parse-if() : <div,parser> node
  val t = expect("if", fn(k) match k { TkIf -> True; _ -> False })
  val cond = parse-expr()
  val then-e = parse-block()
  val else-e = match peek()
    TkElse ->
      advance()
      match peek()
        TkIf  -> parse-if()
        _     -> parse-block()
    _ -> Node(current-span(), Block([])) // no else → unit
  Node(Span(t.span.start, else-e.span.end), If(cond, then-e, else-e))

fun parse-fn() : <div,parser> node
  val t = expect("fn", fn(k) match k { TkFn -> True; _ -> False })
  expect("(", fn(k) match k { TkLParen -> True; _ -> False })
  val params = parse-params()
  expect(")", fn(k) match k { TkRParen -> True; _ -> False })
  val body = match peek()
    TkArrow ->
      advance()
      parse-expr()
    _ ->
      parse-block()
  Node(Span(t.span.start, body.span.end), Fun(params, body))

fun parse-params() : <div,parser> list<string>
  match peek()
    TkRParen -> []
    TkIdent(name) ->
      advance()
      match peek()
        TkComma -> { advance(); Cons(name, parse-params()) }
        _       -> [name]
    _ -> []

fun parse-let() : <div,parser> node
  val t = expect("let", fn(k) match k { TkLet -> True; _ -> False })
  val name = match peek()
    TkIdent(n) -> { advance(); n }
    _          -> { parse-error("expected identifier"); "_" }
  expect("=", fn(k) match k { TkEq -> True; _ -> False })
  val init = parse-expr()
  // optional semicolon before body
  match peek()
    TkSemicolon -> { advance(); () }
    _           -> ()
  val body = parse-expr()
  Node(Span(t.span.start, body.span.end), Let(name, Nothing, init, body))

fun parse-match() : <div,parser> node
  val t = expect("match", fn(k) match k { TkMatch -> True; _ -> False })
  val scrut = parse-expr()
  expect("{", fn(k) match k { TkLBrace -> True; _ -> False })
  val arms = parse-match-arms()
  val end-tok = expect("}", fn(k) match k { TkRBrace -> True; _ -> False })
  Node(Span(t.span.start, end-tok.span.end), Match(scrut, arms))

fun parse-match-arms() : <div,parser> list<match-arm>
  match peek()
    TkRBrace -> []
    _ ->
      val pat = parse-pattern()
      expect("=>", fn(k) match k { TkArrow -> True; _ -> False })
      val body = parse-expr()
      // optional comma between arms
      match peek()
        TkComma -> { advance(); () }
        _       -> ()
      Cons(Match-arm(pat, body), parse-match-arms())

fun parse-pattern() : <div,parser> pattern
  match peek()
    TkIdent("_") -> { advance(); PWild }
    TkIdent(n)   -> { advance(); PVar(n) }
    TkInt(i)     -> { advance(); PLit(LitInt(i)) }
    TkBool(b)    -> { advance(); PLit(LitBool(b)) }
    TkString(s)  -> { advance(); PLit(LitString(s)) }
    _ -> { parse-error("expected pattern"); PWild }

// ---------------------------------------------------------------------------
// Top-level declarations: fun name(params) { body } or fun name(params) => expr
// ---------------------------------------------------------------------------

pub fun parse-fun-decl() : <div,parser> fun-decl
  val t = expect("fun", fn(k) match k { TkFun -> True; _ -> False })
  val name = match peek()
    TkIdent(n) -> { advance(); n }
    _          -> { parse-error("expected function name"); "_" }
  expect("(", fn(k) match k { TkLParen -> True; _ -> False })
  val params = parse-params()
  expect(")", fn(k) match k { TkRParen -> True; _ -> False })
  val body = match peek()
    TkArrow ->
      advance()
      parse-expr()
    _ ->
      parse-block()
  Fun-decl(Span(t.span.start, body.span.end), name, params, body)

pub fun parse-program() : <div,parser> program
  var decls := []
  while { match peek() { TkEof -> False; _ -> True } }
    decls := Cons(parse-fun-decl(), decls)
  Program(decls.reverse)

// ---------------------------------------------------------------------------
// Runner: handle the parser effect over a token list
// ---------------------------------------------------------------------------

pub fun run-parser( tokens : list<token>, action : () -> <div,parser,console> node ) : <div,console> node
  var toks := tokens
  with handler
    fun peek()
      match toks
        Cons(t, _) -> t.kind
        Nil        -> TkEof
    fun advance()
      match toks
        Cons(t, rest) -> { toks := rest; t }
        Nil           -> Token(TkEof, Span(0, 0))
    fun current-span()
      match toks
        Cons(t, _) -> t.span
        Nil        -> Span(0, 0)
    fun parse-error( msg )
      val sp = match toks
        Cons(t, _) -> t.span
        Nil        -> Span(0, 0)
      println("parse error at " ++ sp.start.show ++ ": " ++ msg)
      Node(sp, Literal(LitBool(False)))
  action()

pub fun run-parser-program( tokens : list<token> ) : <div,console> program
  var toks := tokens
  with handler
    fun peek()
      match toks
        Cons(t, _) -> t.kind
        Nil        -> TkEof
    fun advance()
      match toks
        Cons(t, rest) -> { toks := rest; t }
        Nil           -> Token(TkEof, Span(0, 0))
    fun current-span()
      match toks
        Cons(t, _) -> t.span
        Nil        -> Span(0, 0)
    fun parse-error( msg )
      val sp = match toks
        Cons(t, _) -> t.span
        Nil        -> Span(0, 0)
      println("parse error at " ++ sp.start.show ++ ": " ++ msg)
      Node(sp, Literal(LitBool(False)))
  parse-program()
