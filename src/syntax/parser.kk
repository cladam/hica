/*
 * hica – syntax parser
 * 
 * This source file is part of the hica open source project
 * Copyright (C) 2026 Claes Adamsson <claes.adamsson@gmail.com>
 *
 * See https://github.com/cladam/hica/blob/main/LICENSE for license information
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
    TkFloat(f) ->
      val t = advance()
      Node(t.span, Literal(LitFloat(f)))
    TkBool(b) ->
      val t = advance()
      Node(t.span, Literal(LitBool(b)))
    TkString(s) ->
      val t = advance()
      Node(t.span, Literal(LitString(s)))
    TkChar(c) ->
      val t = advance()
      Node(t.span, Literal(LitChar(c)))
    TkIdent(name) ->
      val t = advance()
      Node(t.span, Var(name))
    TkLParen ->
      val start-tok = advance()
      match peek()
        TkRParen ->
          // Either () => lambda or empty parens
          val end-tok = advance()
          match peek()
            TkArrow ->
              advance()
              val body = parse-lambda-body()
              Node(Span(start-tok.span.start, body.span.end), Fun([], body))
            _ ->
              Node(Span(start-tok.span.start, end-tok.span.end), Tuple([]))
        _ ->
          val e = parse-expr()
          match peek()
            TkComma ->
              // (e, e2, ...) — could be tuple or multi-param lambda
              advance()
              val rest = parse-tuple-rest()
              val end-tok = expect(")", fn(k) match k { TkRParen -> True; _ -> False })
              match peek()
                TkArrow ->
                  advance()
                  val params = extract-param-names(Cons(e, rest))
                  val body = parse-lambda-body()
                  Node(Span(start-tok.span.start, body.span.end), Fun(params, body))
                _ ->
                  Node(Span(start-tok.span.start, end-tok.span.end), Tuple(Cons(e, rest)))
            _ ->
              // (e) — could be grouped expr or single-param lambda
              expect(")", fn(k) match k { TkRParen -> True; _ -> False })
              match peek()
                TkArrow ->
                  advance()
                  val params = extract-param-names([e])
                  val body = parse-lambda-body()
                  Node(Span(start-tok.span.start, body.span.end), Fun(params, body))
                _ ->
                  e
    TkLBracket ->
      val start-tok = advance()
      match peek()
        TkRBracket ->
          val end-tok = advance()
          Node(Span(start-tok.span.start, end-tok.span.end), EList([]))
        _ ->
          val first = parse-expr()
          val rest = parse-list-rest()
          val end-tok = expect("]", fn(k) match k { TkRBracket -> True; _ -> False })
          Node(Span(start-tok.span.start, end-tok.span.end), EList(Cons(first, rest)))
    TkLBrace ->
      parse-block()
    TkIf ->
      parse-if()
    TkLet ->
      parse-let()
    TkMatch ->
      parse-match()
    TkRepeat ->
      parse-repeat()
    TkFor ->
      parse-for-in()
    TkInterpStart ->
      parse-string-interp()
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
    TkIn       -> Just((7, 8, In))
    TkLt       -> Just((7, 8, Lt))
    TkGt       -> Just((7, 8, Gt))
    TkLe       -> Just((7, 8, Le))
    TkGe       -> Just((7, 8, Ge))
    TkPlus     -> Just((9, 10, Add))
    TkMinus    -> Just((9, 10, Sub))
    TkStar     -> Just((11, 12, Mul))
    TkSlash    -> Just((11, 12, Div))
    TkPercent  -> Just((11, 12, Mod))
    _          -> Nothing

// Pratt parser: parse binary expressions with binding power.
fun parse-binary( min-bp : int ) : <div,parser> node
  val lhs = parse-postfix()
  parse-binary-loop(lhs, min-bp)

// Parse postfix operations: function calls f(args) and tuple index expr.N
fun parse-postfix() : <div,parser> node
  var result := parse-prefix()
  var cont := True
  while { cont }
    match peek()
      TkLParen ->
        advance()
        val args = parse-args()
        val end-tok = expect(")", fn(k) match k { TkRParen -> True; _ -> False })
        result := Node(Span(result.span.start, end-tok.span.end), Call(result, args))
      TkDot ->
        advance()
        match peek()
          TkInt(idx) ->
            val t = advance()
            result := Node(Span(result.span.start, t.span.end), TupleIndex(result, idx))
          _ ->
            parse-error("expected tuple index (0, 1, ...) after '.'")
            ()
      TkLBracket ->
        advance()
        match peek()
          TkColon ->
            // list[:end] — slice with no start
            advance()
            val end-e = parse-expr()
            val end-tok = expect("]", fn(k) match k { TkRBracket -> True; _ -> False })
            result := Node(Span(result.span.start, end-tok.span.end), ListSlice(result, Nothing, Just(end-e)))
          TkRBracket ->
            // list[] — parse error, empty index
            parse-error("expected index expression inside []")
            val end-tok = advance()
            result := Node(Span(result.span.start, end-tok.span.end), ListIndex(result, Node(no-span, Literal(LitInt(0)))))
          _ ->
            val idx-e = parse-expr()
            match peek()
              TkColon ->
                // list[start:] or list[start:end]
                advance()
                match peek()
                  TkRBracket ->
                    // list[start:]
                    val end-tok = advance()
                    result := Node(Span(result.span.start, end-tok.span.end), ListSlice(result, Just(idx-e), Nothing))
                  _ ->
                    // list[start:end]
                    val end-e = parse-expr()
                    val end-tok = expect("]", fn(k) match k { TkRBracket -> True; _ -> False })
                    result := Node(Span(result.span.start, end-tok.span.end), ListSlice(result, Just(idx-e), Just(end-e)))
              _ ->
                // list[index]
                val end-tok = expect("]", fn(k) match k { TkRBracket -> True; _ -> False })
                result := Node(Span(result.span.start, end-tok.span.end), ListIndex(result, idx-e))
      _ -> cont := False
  result

fun parse-args() : <div,parser> list<node>
  match peek()
    TkRParen -> []
    _ ->
      val first = parse-expr()
      match peek()
        TkComma -> { advance(); Cons(first, parse-args()) }
        _       -> [first]

fun parse-tuple-rest() : <div,parser> list<node>
  match peek()
    TkRParen -> []
    _ ->
      val elem = parse-expr()
      match peek()
        TkComma -> { advance(); Cons(elem, parse-tuple-rest()) }
        _       -> [elem]

fun parse-list-rest() : <div,parser> list<node>
  match peek()
    TkRBracket -> []
    TkComma ->
      advance()
      match peek()
        TkRBracket -> []  // trailing comma
        _ ->
          val elem = parse-expr()
          Cons(elem, parse-list-rest())
    _ -> []

fun parse-binary-loop( lhs : node, min-bp : int ) : <div,parser> node
  val tk = peek()
  // Pipe operator |> desugars: a |> f  →  f(a)
  match tk
    TkPipeGt | min-bp <= 0 ->
      advance()
      val rhs = parse-binary(1)
      val desugared = Node(Span(lhs.span.start, rhs.span.end), Call(rhs, [lhs]))
      parse-binary-loop(desugared, min-bp)
    _ ->
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

fun extract-param-names( exprs : list<node> ) : <div,parser> list<string>
  exprs.map fn(n)
    match n.expr
      Var(name) -> name
      _ -> { parse-error("expected parameter name"); "" }

fun parse-lambda-body() : <div,parser> node
  match peek()
    TkLBrace -> parse-block()
    _        -> parse-expr()

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
  match peek()
    TkLParen ->
      // Tuple destructuring: let (a, b) = init; body
      advance()
      val names = parse-let-tuple-names()
      expect(")", fn(k) match k { TkRParen -> True; _ -> False })
      expect("=", fn(k) match k { TkEq -> True; _ -> False })
      val init = parse-expr()
      match peek()
        TkSemicolon -> { advance(); () }
        _           -> ()
      val body = parse-expr()
      Node(Span(t.span.start, body.span.end), LetTuple(names, init, body))
    _ ->
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

fun parse-let-tuple-names() : <div,parser> list<string>
  match peek()
    TkRParen -> []
    TkIdent(n) ->
      advance()
      match peek()
        TkComma -> { advance(); Cons(n, parse-let-tuple-names()) }
        _       -> [n]
    _ -> { parse-error("expected identifier in tuple pattern"); [] }

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

fun parse-repeat() : <div,parser> node
  val t = expect("repeat", fn(k) match k { TkRepeat -> True; _ -> False })
  expect("(", fn(k) match k { TkLParen -> True; _ -> False })
  val count = parse-expr()
  expect(")", fn(k) match k { TkRParen -> True; _ -> False })
  val body = parse-block()
  Node(Span(t.span.start, body.span.end), Repeat(count, body))

fun parse-for-in() : <div,parser> node
  val t = expect("for", fn(k) match k { TkFor -> True; _ -> False })
  val name = match peek()
    TkIdent(n) -> { advance(); n }
    _          -> { parse-error("expected loop variable after 'for'"); "_" }
  expect("in", fn(k) match k { TkIn -> True; _ -> False })
  val start-expr = parse-expr()
  expect("..", fn(k) match k { TkDotDot -> True; _ -> False })
  val end-expr = parse-expr()
  val body = parse-block()
  Node(Span(t.span.start, body.span.end), ForIn(name, start-expr, end-expr, body))

// ---------------------------------------------------------------------------
// String interpolation: "hello {expr}!"
// Token stream: TkInterpStart [TkStringPart(s) | TkInterpExpr ...expr... TkRBrace]* TkInterpEnd
// ---------------------------------------------------------------------------

fun parse-string-interp() : <div,parser> node
  val t = advance() // consume TkInterpStart
  val parts = parse-interp-parts()
  val end-t = expect("end of interpolated string", fn(k) match k { TkInterpEnd -> True; _ -> False })
  Node(Span(t.span.start, end-t.span.end), StringInterp(parts))

fun parse-interp-parts() : <div,parser> list<node>
  match peek()
    TkInterpEnd -> []
    TkStringPart(s) ->
      val t = advance()
      Cons(Node(t.span, Literal(LitString(s))), parse-interp-parts())
    TkInterpExpr ->
      val t = advance() // consume TkInterpExpr
      val expr = parse-expr()
      expect("}", fn(k) match k { TkRBrace -> True; _ -> False })
      Cons(expr, parse-interp-parts())
    _ ->
      parse-error("unexpected token in interpolated string: " ++ peek().show)
      []

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
