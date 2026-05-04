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
      match name
        "None" ->
          val t = advance()
          Node(t.span, ENone)
        "Some" ->
          val t = advance()
          expect("(", fn(k) match k { TkLParen -> True; _ -> False })
          val inner = parse-expr()
          val end-tok = expect(")", fn(k) match k { TkRParen -> True; _ -> False })
          Node(Span(t.span.start, end-tok.span.end), ESome(inner))
        "Ok" ->
          val t = advance()
          expect("(", fn(k) match k { TkLParen -> True; _ -> False })
          val inner = parse-expr()
          val end-tok = expect(")", fn(k) match k { TkRParen -> True; _ -> False })
          Node(Span(t.span.start, end-tok.span.end), EOk(inner))
        "Err" ->
          val t = advance()
          expect("(", fn(k) match k { TkLParen -> True; _ -> False })
          val inner = parse-expr()
          val end-tok = expect(")", fn(k) match k { TkRParen -> True; _ -> False })
          Node(Span(t.span.start, end-tok.span.end), EErr(inner))
        _ ->
          val t = advance()
          // Check for struct literal: Name { field: value, ... }
          match peek()
            TkLBrace | name.is-upper-start ->
              advance() // consume {
              val fields = parse-struct-lit-fields()
              val end-tok = expect("}", fn(k) match k { TkRBrace -> True; _ -> False })
              Node(Span(t.span.start, end-tok.span.end), StructLit(name, fields))
            TkEq ->
              // x = expr — reassignment (only valid for var-declared names)
              advance()
              val value = parse-expr()
              Node(Span(t.span.start, value.span.end), Assign(name, value))
            _ ->
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
    TkVar ->
      parse-var()
    TkMatch ->
      parse-match()
    TkRepeat ->
      parse-repeat()
    TkFor ->
      parse-for-in()
    TkWhile ->
      parse-while()
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
          TkIdent(field) ->
            val t = advance()
            result := Node(Span(result.span.start, t.span.end), FieldAccess(result, field))
          _ ->
            parse-error("expected field name or tuple index after '.'")
            ()
      TkLBracket ->
        advance()
        match peek()
          TkColon ->
            // list[:end] or list[:] — slice with no start
            advance()
            match peek()
              TkRBracket ->
                // list[:] — identity slice
                val end-tok = advance()
                result := Node(Span(result.span.start, end-tok.span.end), ListSlice(result, Nothing, Nothing))
              _ ->
                // list[:end]
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

// ---------------------------------------------------------------------------
// Type annotations
// ---------------------------------------------------------------------------

// Parse a type expression: int, float, bool, string, char,
// list<T>, maybe<T>, result<T,E>, (T, T) tuples, (T) -> T functions.
fun parse-type() : <div,parser> hica-type
  match peek()
    TkLParen ->
      // Tuple type or function type: (int, string) or (int) -> string
      advance()
      match peek()
        TkRParen ->
          // () -> T  (no-param function type)
          advance()
          match peek()
            TkThinArrow ->
              advance()
              val ret = parse-type()
              TFun([], ret)
            _ ->
              TUnit
        _ ->
          val first = parse-type()
          match peek()
            TkComma ->
              // (T, T, ...) — could be tuple or multi-param function type
              advance()
              val rest = parse-type-list()
              expect(")", fn(k) match k { TkRParen -> True; _ -> False })
              match peek()
                TkThinArrow ->
                  advance()
                  val ret = parse-type()
                  TFun(Cons(first, rest), ret)
                _ ->
                  TTuple(Cons(first, rest))
            TkRParen ->
              // (T) — could be grouped or single-param function type
              advance()
              match peek()
                TkThinArrow ->
                  advance()
                  val ret = parse-type()
                  TFun([first], ret)
                _ ->
                  first  // just grouping parens
            _ ->
              parse-error("expected ',' or ')' in type")
              first
    TkIdent(name) ->
      advance()
      match name
        "int"    -> TInt
        "float"  -> TFloat
        "bool"   -> TBool
        "string" -> TString
        "char"   -> TChar
        "list"   ->
          expect("<", fn(k) match k { TkLt -> True; _ -> False })
          val elem = parse-type()
          expect(">", fn(k) match k { TkGt -> True; _ -> False })
          TList(elem)
        "maybe"  ->
          expect("<", fn(k) match k { TkLt -> True; _ -> False })
          val elem = parse-type()
          expect(">", fn(k) match k { TkGt -> True; _ -> False })
          TMaybe(elem)
        "result" ->
          expect("<", fn(k) match k { TkLt -> True; _ -> False })
          val ok-t = parse-type()
          expect(",", fn(k) match k { TkComma -> True; _ -> False })
          val err-t = parse-type()
          expect(">", fn(k) match k { TkGt -> True; _ -> False })
          TResult(ok-t, err-t)
        _ ->
          // User-defined struct type
          if name.is-upper-start then TStruct(name)
          else
            parse-error("unknown type: " ++ name)
            TUnit
    _ ->
      parse-error("expected type")
      TUnit

fun parse-type-list() : <div,parser> list<hica-type>
  match peek()
    TkRParen -> []
    _ ->
      val t = parse-type()
      match peek()
        TkComma -> { advance(); Cons(t, parse-type-list()) }
        _       -> [t]

// Parse an optional `: type` annotation. Returns Nothing if no colon.
fun parse-optional-type-ann() : <div,parser> maybe<hica-type>
  match peek()
    TkColon -> { advance(); Just(parse-type()) }
    _       -> Nothing

// ---------------------------------------------------------------------------
// Parameters and bindings
// ---------------------------------------------------------------------------

fun parse-typed-params() : <div,parser> list<(string, maybe<hica-type>)>
  match peek()
    TkRParen -> []
    TkIdent(name) ->
      advance()
      val ann = parse-optional-type-ann()
      match peek()
        TkComma -> { advance(); Cons((name, ann), parse-typed-params()) }
        _       -> [(name, ann)]
    _ -> []

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
      val body = parse-let-body(init.span.end)
      Node(Span(t.span.start, body.span.end), LetTuple(names, init, body))
    _ ->
      val name = match peek()
        TkIdent(n) -> { advance(); n }
        _          -> { parse-error("expected identifier"); "_" }
      val ann = parse-optional-type-ann()
      expect("=", fn(k) match k { TkEq -> True; _ -> False })
      val init = parse-expr()
      // optional semicolon before body
      match peek()
        TkSemicolon -> { advance(); () }
        _           -> ()
      val body = parse-let-body(init.span.end)
      Node(Span(t.span.start, body.span.end), Let(name, ann, init, body))

fun parse-var() : <div,parser> node
  val t = expect("var", fn(k) match k { TkVar -> True; _ -> False })
  val name = match peek()
    TkIdent(n) -> { advance(); n }
    _          -> { parse-error("expected identifier after 'var'"); "_" }
  val ann = parse-optional-type-ann()
  expect("=", fn(k) match k { TkEq -> True; _ -> False })
  val init = parse-expr()
  match peek()
    TkSemicolon -> { advance(); () }
    _           -> ()
  val body = parse-let-body(init.span.end)
  Node(Span(t.span.start, body.span.end), VarDecl(name, ann, init, body))

// Parse the body of a let binding. If we're at the end of a block (}) or
// end of file, synthesize a unit value — this allows trailing lets like
// `let x = 42` as the last statement without requiring a continuation.
fun parse-let-body( fallback-pos : int ) : <div,parser> node
  match peek()
    TkRBrace -> Node(Span(fallback-pos, fallback-pos), Tuple([]))
    TkEof    -> Node(Span(fallback-pos, fallback-pos), Tuple([]))
    _        -> parse-expr()

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
      // optional guard: pattern if condition => body
      val guard = match peek()
        TkIf -> { advance(); Just(parse-expr()) }
        _    -> Nothing
      expect("=>", fn(k) match k { TkArrow -> True; _ -> False })
      val body = parse-expr()
      // optional comma between arms
      match peek()
        TkComma -> { advance(); () }
        _       -> ()
      Cons(Match-arm(pat, guard, body), parse-match-arms())

fun parse-pattern-list() : <div,parser> list<pattern>
  val p = parse-pattern()
  match peek()
    TkComma -> { advance(); Cons(p, parse-pattern-list()) }
    _       -> [p]

fun parse-pattern() : <div,parser> pattern
  match peek()
    TkIdent("_") -> { advance(); PWild }
    TkIdent("None") -> { advance(); PNone }
    TkIdent("Some") ->
      advance()
      expect("(", fn(k) match k { TkLParen -> True; _ -> False })
      val inner = parse-pattern()
      expect(")", fn(k) match k { TkRParen -> True; _ -> False })
      PSome(inner)
    TkIdent("Ok") ->
      advance()
      expect("(", fn(k) match k { TkLParen -> True; _ -> False })
      val inner = parse-pattern()
      expect(")", fn(k) match k { TkRParen -> True; _ -> False })
      POk(inner)
    TkIdent("Err") ->
      advance()
      expect("(", fn(k) match k { TkLParen -> True; _ -> False })
      val inner = parse-pattern()
      expect(")", fn(k) match k { TkRParen -> True; _ -> False })
      PErr(inner)
    TkLParen ->
      advance()
      val first = parse-pattern()
      expect(",", fn(k) match k { TkComma -> True; _ -> False })
      val rest = parse-pattern-list()
      expect(")", fn(k) match k { TkRParen -> True; _ -> False })
      PTuple(Cons(first, rest))
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
  val collection-expr = parse-expr()
  match peek()
    TkDotDot ->
      // for name in start..end { body }
      advance()
      val end-expr = parse-expr()
      val body = parse-block()
      Node(Span(t.span.start, body.span.end), ForIn(name, collection-expr, end-expr, body))
    _ ->
      // for name in collection { body }
      val body = parse-block()
      Node(Span(t.span.start, body.span.end), ForEach(name, collection-expr, body))

fun parse-while() : <div,parser> node
  val t = expect("while", fn(k) match k { TkWhile -> True; _ -> False })
  val cond = parse-expr()
  val body = parse-block()
  Node(Span(t.span.start, body.span.end), While(cond, body))

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
// Struct helpers
// ---------------------------------------------------------------------------

// Check whether a string starts with an uppercase letter.
fun is-upper-start( s : string ) : bool
  match s.list
    Cons(c, _) -> c.is-upper
    _          -> False

// Parse struct literal fields: field: expr, ...
fun parse-struct-lit-fields() : <div,parser> list<(string, node)>
  match peek()
    TkRBrace -> []
    TkIdent(name) ->
      advance()
      expect(":", fn(k) match k { TkColon -> True; _ -> False })
      val value = parse-expr()
      match peek()
        TkComma ->
          advance()
          Cons((name, value), parse-struct-lit-fields())
        _ -> [(name, value)]
    _ ->
      parse-error("expected field name in struct literal")
      []

// Parse a struct declaration: struct Name { field: type, ... }
fun parse-struct-decl() : <div,parser> struct-def
  val t = expect("struct", fn(k) match k { TkStruct -> True; _ -> False })
  val name = match peek()
    TkIdent(n) -> { advance(); n }
    _          -> { parse-error("expected struct name"); "_" }
  expect("{", fn(k) match k { TkLBrace -> True; _ -> False })
  val fields = parse-struct-def-fields()
  val end-tok = expect("}", fn(k) match k { TkRBrace -> True; _ -> False })
  Struct-def(Span(t.span.start, end-tok.span.end), name, fields)

// Parse struct definition fields: name: type, ...
fun parse-struct-def-fields() : <div,parser> list<(string, hica-type)>
  match peek()
    TkRBrace -> []
    TkIdent(name) ->
      advance()
      expect(":", fn(k) match k { TkColon -> True; _ -> False })
      val ftype = parse-type()
      match peek()
        TkComma ->
          advance()
          Cons((name, ftype), parse-struct-def-fields())
        _ -> [(name, ftype)]
    _ ->
      parse-error("expected field name in struct definition")
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
  val typed-params = parse-typed-params()
  expect(")", fn(k) match k { TkRParen -> True; _ -> False })
  val ret-ann = parse-optional-type-ann()
  val param-names = typed-params.map(fn(e) e.fst)
  val p-anns = typed-params.map(fn(e) e.snd)
  val body = match peek()
    TkArrow ->
      advance()
      parse-expr()
    _ ->
      parse-block()
  Fun-decl(Span(t.span.start, body.span.end), name, param-names, body, param-anns = p-anns, ret-ann = ret-ann)

pub fun parse-program() : <div,parser> program
  var decls := []
  var structs := []
  while { match peek() { TkEof -> False; _ -> True } }
    match peek()
      TkStruct -> structs := Cons(parse-struct-decl(), structs)
      _        -> decls := Cons(parse-fun-decl(), decls)
  Program(structs.reverse, decls.reverse)

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
