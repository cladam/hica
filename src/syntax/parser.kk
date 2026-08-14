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
  fun peek-next() : token-kind
  fun peek-newline() : bool  // True if next token is on a new line
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
          //
          // NOTE: `Name { ... }` in expression position is always parsed as
          // a struct literal (or struct update via `...spread`). This means
          // a zero-arg enum constructor followed by a block in a `if`/`while`
          // condition — `if m == Ctrl { println("ctrl") }` — parses `Ctrl {`
          // as a struct literal and confuses the rest of the expression.
          //
          // The workaround for now is to parenthesise: `if (m == Ctrl) { ... }`.
          // A proper fix requires 3-token lookahead (`{ IDENT :` = struct,
          // `{ IDENT ...` = block) — that needs a `peek-nth` extension to
          // the parser effect and is tracked as a separate issue.
          match peek()
            TkLBrace | name.is-upper-start ->
              advance() // consume {
              // Check for struct update: Name { ...base, field: value }
              match peek()
                TkSpread ->
                  advance() // consume ...
                  val base = parse-expr()
                  match peek()
                    TkComma ->
                      advance()
                      val fields = parse-struct-lit-fields()
                      val end-tok = expect("}", fn(k) match k { TkRBrace -> True; _ -> False })
                      Node(Span(t.span.start, end-tok.span.end), StructUpdate(name, base, fields, []))
                    _ ->
                      // { ...base } with no overrides
                      val end-tok = expect("}", fn(k) match k { TkRBrace -> True; _ -> False })
                      Node(Span(t.span.start, end-tok.span.end), StructUpdate(name, base, [], []))
                _ ->
                  val fields = parse-struct-lit-fields()
                  val end-tok = expect("}", fn(k) match k { TkRBrace -> True; _ -> False })
                  Node(Span(t.span.start, end-tok.span.end), StructLit(name, fields))
            TkLParen | name.is-upper-start ->
              // Constructor call: Name(args)
              advance() // consume (
              val args = parse-args()
              val end-tok = expect(")", fn(k) match k { TkRParen -> True; _ -> False })
              Node(Span(t.span.start, end-tok.span.end), EConstructor(name, args))
            TkEq ->
              // x = expr — reassignment (only valid for var-declared names)
              advance()
              val value = parse-expr()
              Node(Span(t.span.start, value.span.end), Assign(name, value))
            _ ->
              if name.is-upper-start then
                // Bare constructor: Name with no args
                Node(t.span, EConstructor(name, []))
              else
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
                  val body = parse-lambda-body()
                  // Tuple destructuring in lambda: ((a, b)) => expr
                  // desugars to: fn(_tp) { let (_tp_0, _tp_1, ...) = _tp; expr }
                  match e.expr
                    Tuple(elems) ->
                      val tup-names = extract-param-names(elems)
                      val desugar-body = Node(Span(e.span.start, body.span.end), LetTuple(tup-names, Node(e.span, Var("_tp")), body))
                      Node(Span(start-tok.span.start, body.span.end), Fun(["_tp"], desugar-body))
                    _ ->
                      val params = extract-param-names([e])
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
          match peek()
            TkDotDot ->
              advance()
              val last = parse-expr()
              val end-tok = expect("]", fn(k) match k { TkRBracket -> True; _ -> False })
              val callee = Node(Span(start-tok.span.start, end-tok.span.end), Var("range"))
              Node(Span(start-tok.span.start, end-tok.span.end), Call(callee, [first, last]))
            TkDotDotEq ->
              advance()
              val last = parse-expr()
              val end-tok = expect("]", fn(k) match k { TkRBracket -> True; _ -> False })
              val callee = Node(Span(start-tok.span.start, end-tok.span.end), Var("range_inc"))
              Node(Span(start-tok.span.start, end-tok.span.end), Call(callee, [first, last]))
            _ ->
              val rest = parse-list-rest()
              val end-tok = expect("]", fn(k) match k { TkRBracket -> True; _ -> False })
              Node(Span(start-tok.span.start, end-tok.span.end), EList(Cons(first, rest)))
    TkLBrace ->
      // Lookahead: { "key" : ... } is a map literal
      // Also: { : } is an empty map
      match peek-next()
        TkColon -> parse-empty-map()
        TkString(_) -> parse-map-literal()
        _ -> parse-block()
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
    TkLoop ->
      parse-loop()
    TkHandle ->
      parse-handle-expr()
    TkSpawn ->
      parse-spawn-expr()
    TkBreak ->
      val t = advance()
      Node(t.span, Break)
    TkContinue ->
      val t = advance()
      Node(t.span, Continue)
    TkInterpStart ->
      parse-string-interp()
    TkMinus ->
      val t = advance()
      val operand = parse-postfix()
      Node(Span(t.span.start, operand.span.end), Unary(Neg, operand))
    TkBang ->
      val t = advance()
      val operand = parse-postfix()
      Node(Span(t.span.start, operand.span.end), Unary(Not, operand))
    _ ->
      val err = parse-error("unexpected token: " ++ tk.show)
      // Belt-and-suspenders: consume the offending token so callers that loop
      // on parse-prefix (or its callers) make forward progress. Without
      // this, sequences like `let x = @` wedge the parser.
      match peek()
        TkEof -> ()
        _     -> { advance(); () }
      err

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

// Statement-level expressions should not have postfix ( applied.
fun is-statement-expr( e : expr ) : bool
  match e
    While(_, _)        -> True
    Loop(_)            -> True
    Repeat(_, _)       -> True
    ForIn(_, _, _, _)  -> True
    ForEach(_, _, _)   -> True
    If(_, _, _)        -> True
    Block(_)           -> True
    Let(_, _, _, _)    -> True
    LetTuple(_, _, _)  -> True
    VarDecl(_, _, _, _) -> True
    Assign(_, _)       -> True
    Break              -> True
    Continue           -> True
    _                  -> False

// Parse postfix operations: function calls f(args) and tuple index expr.N
fun parse-postfix() : <div,parser> node
  var result := parse-prefix()
  var cont := True
  while { cont }
    match peek()
      TkLParen ->
        if result.expr.is-statement-expr || peek-newline() then cont := False
        else
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
            // UFCS: expr.f(args) desugars to f(expr, args)
            match peek()
              TkLParen ->
                advance()
                val args = parse-args()
                val end-tok = expect(")", fn(k) match k { TkRParen -> True; _ -> False })
                result := Node(Span(result.span.start, end-tok.span.end), Call(Node(t.span, Var(field)), Cons(result, args)))
              _ ->
                result := Node(Span(result.span.start, t.span.end), FieldAccess(result, field))
          _ ->
            parse-error("expected field name or tuple index after '.'")
            ()
      TkLBracket ->
        if peek-newline() then cont := False
        else
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
                TkDotDot ->
                  // User wrote list[start..end] (Rust-style) — give a targeted error
                  parse-error("use ':' for slices, not '..'. Try: list[start:end]")
                  advance()  // skip ..
                  val end-e = parse-expr()
                  val end-tok = expect("]", fn(k) match k { TkRBracket -> True; _ -> False })
                  result := Node(Span(result.span.start, end-tok.span.end), ListSlice(result, Just(idx-e), Just(end-e)))
                TkDotDotEq ->
                  // User wrote list[start..=end] (Rust-style) — give a targeted error
                  parse-error("use ':' for slices, not '..='. Try: list[start:end]")
                  advance()  // skip ..=
                  val end-e = parse-expr()
                  val end-tok = expect("]", fn(k) match k { TkRBracket -> True; _ -> False })
                  result := Node(Span(result.span.start, end-tok.span.end), ListSlice(result, Just(idx-e), Just(end-e)))
                _ ->
                  // list[index]
                  val end-tok = expect("]", fn(k) match k { TkRBracket -> True; _ -> False })
                  result := Node(Span(result.span.start, end-tok.span.end), ListIndex(result, idx-e))
      TkQuestion ->
        val t = advance()
        result := Node(Span(result.span.start, t.span.end), ETry(result))
      TkAmpQuest ->
        val t = advance()
        result := Node(Span(result.span.start, t.span.end), EValidateTry(result))
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

// ---------------------------------------------------------------------------
// Map literals: {"key": value, ...} or {:} for empty map
// ---------------------------------------------------------------------------

fun parse-empty-map() : <div,parser> node
  val start-tok = advance()    // consume {
  advance()                    // consume :
  val end-tok = expect("}", fn(k) match k { TkRBrace -> True; _ -> False })
  Node(Span(start-tok.span.start, end-tok.span.end), MapLit([]))

fun parse-map-literal() : <div,parser> node
  val start-tok = advance()    // consume {
  val entries = parse-map-entries()
  val end-tok = expect("}", fn(k) match k { TkRBrace -> True; _ -> False })
  Node(Span(start-tok.span.start, end-tok.span.end), MapLit(entries))

fun parse-map-entries() : <div,parser> list<(node, node)>
  val key = parse-expr()
  expect(":", fn(k) match k { TkColon -> True; _ -> False })
  val value = parse-expr()
  val entry = (key, value)
  match peek()
    TkComma ->
      advance()
      match peek()
        TkRBrace -> [entry]   // trailing comma
        _ -> Cons(entry, parse-map-entries())
    _ -> [entry]

fun parse-binary-loop( lhs : node, min-bp : int ) : <div,parser> node
  val tk = peek()
  // Pipe operator |> desugars: a |> f(b, c)  →  f(a, b, c)
  //                            a |> f        →  f(a)
  match tk
    TkPipeGt | min-bp <= 0 ->
      advance()
      val rhs = parse-binary(1)
      val desugared = match rhs.expr
        Call(callee, args) ->
          Node(Span(lhs.span.start, rhs.span.end), Call(callee, Cons(lhs, args)))
        _ ->
          Node(Span(lhs.span.start, rhs.span.end), Call(rhs, [lhs]))
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
              val (row, ret) = parse-effect-row-and-return()
              TFun([], ret, row)
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
                  val (row, ret) = parse-effect-row-and-return()
                  TFun(Cons(first, rest), ret, row)
                _ ->
                  TTuple(Cons(first, rest))
            TkRParen ->
              // (T) — could be grouped or single-param function type
              advance()
              match peek()
                TkThinArrow ->
                  advance()
                  val (row, ret) = parse-effect-row-and-return()
                  TFun([first], ret, row)
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
        "stream" ->
          expect("<", fn(k) match k { TkLt -> True; _ -> False })
          val elem = parse-type()
          expect(">", fn(k) match k { TkGt -> True; _ -> False })
          TStream(elem)
        "result" ->
          expect("<", fn(k) match k { TkLt -> True; _ -> False })
          val ok-t = parse-type()
          expect(",", fn(k) match k { TkComma -> True; _ -> False })
          val err-t = parse-type()
          expect(">", fn(k) match k { TkGt -> True; _ -> False })
          TResult(ok-t, err-t)
        _ ->
          // User-defined struct or enum type
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

// After the `->` of a function type, parse an optional effect row `<E1, E2>`
// (design doc §4.5) followed by the return type. Returns (effects, ret-type).
// An empty row (`<>` — not distinguishable from absence in v1) or a missing
// row both yield [] — the wildcard/permissive default that keeps existing
// programs working. Effect names must be PascalCase identifiers.
fun parse-effect-row-and-return() : <div,parser> (list<string>, hica-type)
  match peek()
    TkLt ->
      advance()  // consume <
      val row = parse-effect-row-names()
      expect(">", fn(k) match k { TkGt -> True; _ -> False })
      val ret = parse-type()
      (row, ret)
    _ ->
      val ret = parse-type()
      ([], ret)

// Parse a comma-separated list of effect names: E1, E2, E3
// (or empty). Each name must be a PascalCase identifier. Trailing `>` is
// consumed by the caller.
fun parse-effect-row-names() : <div,parser> list<string>
  match peek()
    TkGt -> []   // empty row `<>` — allowed; see design doc §4.5
    TkIdent(name) | name.is-upper-start ->
      advance()
      match peek()
        TkComma -> { advance(); Cons(name, parse-effect-row-names()) }
        _       -> [name]
    _ ->
      parse-error("expected effect name (PascalCase) in effect row")
      []

// Parse an optional `: type` annotation. Returns Nothing if no colon.
fun parse-optional-type-ann() : <div,parser> maybe<hica-type>
  match peek()
    TkColon -> { advance(); Just(parse-type()) }
    _       -> Nothing

// Parse an optional `: <E1, E2> type` return-type annotation (design doc §4.5).
// Used by function declarations (`fun f() : <Db> int`) to attach a user-declared
// effect row directly onto the function itself. The `<row>` is optional; when
// absent, this behaves exactly like parse-optional-type-ann.
// Returns (effect-row, type-annotation).
fun parse-optional-ret-ann() : <div,parser> (list<string>, maybe<hica-type>)
  match peek()
    TkColon ->
      advance()
      match peek()
        TkLt ->
          advance()
          val row = parse-effect-row-names()
          expect(">", fn(k) match k { TkGt -> True; _ -> False })
          (row, Just(parse-type()))
        _ ->
          ([], Just(parse-type()))
    _ ->
      ([], Nothing)

// ---------------------------------------------------------------------------
// Parameters and bindings
// ---------------------------------------------------------------------------

// Returns the keyword string if the token is a hica keyword, Nothing otherwise.
// Used to emit clear diagnostics when a keyword appears in identifier position.
fun keyword-name( tk : token-kind ) : maybe<string>
  match tk
    TkLet      -> Just("let")
    TkVar      -> Just("var")
    TkFun      -> Just("fun")
    TkIf       -> Just("if")
    TkElse     -> Just("else")
    TkMatch    -> Just("match")
    TkFor      -> Just("for")
    TkIn       -> Just("in")
    TkRepeat   -> Just("repeat")
    TkWhile    -> Just("while")
    TkLoop     -> Just("loop")
    TkBreak    -> Just("break")
    TkContinue -> Just("continue")
    TkStruct   -> Just("struct")
    TkType     -> Just("type")
    TkImport   -> Just("import")
    TkFrom     -> Just("from")
    TkPub      -> Just("pub")
    TkExtern   -> Just("extern")
    TkTest     -> Just("test")
    _          -> Nothing

fun parse-typed-params() : <div,parser> list<(string, maybe<hica-type>)>
  match peek()
    TkRParen -> []
    TkIdent(name) ->
      advance()
      val ann = parse-optional-type-ann()
      match peek()
        TkComma -> { advance(); Cons((name, ann), parse-typed-params()) }
        _       -> [(name, ann)]
    _ ->
      match keyword-name(peek())
        Just(kw) ->
          val _ = parse-error("'" ++ kw ++ "' is a reserved keyword – choose a different parameter name")
          advance()
          val ann = parse-optional-type-ann()
          match peek()
            TkComma -> { advance(); Cons((kw, ann), parse-typed-params()) }
            _       -> [(kw, ann)]
        Nothing -> []

fun parse-params() : <div,parser> list<string>
  match peek()
    TkRParen -> []
    TkIdent(name) ->
      advance()
      match peek()
        TkComma -> { advance(); Cons(name, parse-params()) }
        _       -> [name]
    _ ->
      match keyword-name(peek())
        Just(kw) ->
          val _ = parse-error("'" ++ kw ++ "' is a reserved keyword – choose a different parameter name")
          advance()
          match peek()
            TkComma -> { advance(); Cons(kw, parse-params()) }
            _       -> [kw]
        Nothing -> []

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
      val pat = parse-or-pattern()
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

// Parse a pattern, possibly with or-alternatives: pat1 | pat2 | pat3
fun parse-or-pattern() : <div,parser> pattern
  val first = parse-pattern()
  match peek()
    TkPipe ->
      val alts = parse-or-rest()
      POr(Cons(first, alts))
    _ -> first

fun parse-or-rest() : <div,parser> list<pattern>
  match peek()
    TkPipe ->
      advance()
      val p = parse-pattern()
      Cons(p, parse-or-rest())
    _ -> []

fun parse-pattern-list() : <div,parser> list<pattern>
  val p = parse-pattern()
  match peek()
    TkComma -> { advance(); Cons(p, parse-pattern-list()) }
    _       -> [p]

fun parse-struct-pattern-fields() : <div,parser> list<(string, pattern)>
  val fname = match peek()
    TkIdent(f) -> { advance(); f }
    _ -> { parse-error("expected field name in struct pattern"); "" }
  val pat = match peek()
    TkColon -> { advance(); parse-pattern() }
    _       -> PVar(fname)
  val field = (fname, pat)
  match peek()
    TkComma -> { advance(); Cons(field, parse-struct-pattern-fields()) }
    _       -> [field]

fun parse-list-pattern-elems() : <div,parser> (list<pattern>, maybe<pattern>)
  // Check for ..rest or .. at current position
  match peek()
    TkDotDot ->
      advance()
      val rest-pat = match peek()
        TkRBracket -> PWild
        TkIdent(n) -> { advance(); PVar(n) }
        _          -> { parse-error("expected variable name or ] after .."); PWild }
      ([], Just(rest-pat))
    _ ->
      val p = parse-pattern()
      match peek()
        TkComma ->
          advance()
          val (more, rest) = parse-list-pattern-elems()
          (Cons(p, more), rest)
        _ -> ([p], Nothing)

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
    TkLBracket ->
      advance()
      match peek()
        TkRBracket ->
          advance()
          PList([], Nothing)
        _ ->
          val (elems, rest) = parse-list-pattern-elems()
          expect("]", fn(k) match k { TkRBracket -> True; _ -> False })
          PList(elems, rest)
    TkIdent(n)   ->
      advance()
      if n.is-upper-start then
        // Constructor pattern: Name(...) or struct pattern: Name { ... }
        match peek()
          TkLParen ->
            advance()
            match peek()
              TkRParen ->
                advance()
                PConstructor(n, [])
              _ ->
                val args = parse-pattern-list()
                expect(")", fn(k) match k { TkRParen -> True; _ -> False })
                PConstructor(n, args)
          TkLBrace ->
            advance()
            match peek()
              TkRBrace ->
                advance()
                PStruct(n, [])
              _ ->
                val fps = parse-struct-pattern-fields()
                expect("}", fn(k) match k { TkRBrace -> True; _ -> False })
                PStruct(n, fps)
          _ ->
            PConstructor(n, [])
      else
        PVar(n)
    TkInt(i)     ->
      advance()
      match peek()
        TkDotDotEq ->
          advance()
          match peek()
            TkInt(j) -> { advance(); PRange(i, j) }
            _        -> { parse-error("expected integer after ..="); PLit(LitInt(i)) }
        _ -> PLit(LitInt(i))
    TkBitPattern(m, v) -> { advance(); PBits(m, v) }
    TkBool(b)    -> { advance(); PLit(LitBool(b)) }
    TkString(s)  -> { advance(); PLit(LitString(s)) }
    TkChar(c)    -> { advance(); PLit(LitChar(c)) }
    TkFloat(f)   -> { advance(); PLit(LitFloat(f)) }
    // Fallback: consume the offending token so the parser makes forward
    // progress on unrecognised patterns. Without the advance() here, callers
    // that re-enter parse-pattern (e.g. constructor arg lists) will loop
    // forever emitting the same error.
    _ ->
      parse-error("expected pattern")
      match peek()
        TkEof -> ()
        _     -> { advance(); () }
      PWild

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

fun parse-loop() : <div,parser> node
  val t = expect("loop", fn(k) match k { TkLoop -> True; _ -> False })
  val body = parse-block()
  Node(Span(t.span.start, body.span.end), Loop(body))

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

// Parse an import declaration:
//   import "path"                      — import all pub items
//   from "path" import { a, b }        — selective import
//   pub import "path"                  — re-export all pub items
//   extern import "path"               — passthrough to Koka (no .hc resolution)
fun parse-import-decl() : <div,parser> import-decl
  val sp = current-span()
  // Check for `pub import` or `extern import`
  val is-pub = match peek()
    TkPub -> { advance(); True }
    _     -> False
  val is-extern = match peek()
    TkExtern -> { advance(); True }
    _        -> False
  match peek()
    TkImport ->
      advance()
      val path-str = match peek()
        TkString(s) -> { advance(); s }
        _           -> { parse-error("expected string path after import"); "" }
      Import-decl(Span(sp.start, current-span().end), path-str, Nothing, is-pub, is-extern)
    TkFrom ->
      advance()
      val path-str = match peek()
        TkString(s) -> { advance(); s }
        _           -> { parse-error("expected string path after from"); "" }
      expect("import", fn(k) match k { TkImport -> True; _ -> False })
      expect("{", fn(k) match k { TkLBrace -> True; _ -> False })
      val names = parse-import-names()
      expect("}", fn(k) match k { TkRBrace -> True; _ -> False })
      Import-decl(Span(sp.start, current-span().end), path-str, Just(names), is-pub)
    _ ->
      parse-error("expected import or from")
      Import-decl(sp, "", Nothing, False)

// Parse comma-separated import names: { a, b, c }
fun parse-import-names() : <div,parser> list<string>
  var names := []
  while { match peek() { TkRBrace -> False; TkEof -> False; _ -> True } }
    match peek()
      TkIdent(n) -> { val _ = advance(); names := Cons(n, names) }
      TkComma    -> { val _ = advance(); () }
      _          -> { val _ = parse-error("expected name in import list"); val _ = advance(); () }
  names.reverse

// Parse a struct declaration: struct Name { field: type, ... }
fun parse-struct-decl( doc : maybe<string> = Nothing ) : <div,parser> struct-def
  val t = expect("struct", fn(k) match k { TkStruct -> True; _ -> False })
  val name = match peek()
    TkIdent(n) -> { advance(); n }
    _          -> { parse-error("expected struct name"); "_" }
  val is-opaque = match peek()
    TkPriv -> { advance(); True }
    _      -> False
  expect("{", fn(k) match k { TkLBrace -> True; _ -> False })
  val fields = parse-struct-def-fields()
  val end-tok = expect("}", fn(k) match k { TkRBrace -> True; _ -> False })
  Struct-def(Span(t.span.start, end-tok.span.end), name, fields = fields, doc = doc, is-pub = False, is-opaque = is-opaque)

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
// Type (enum) declarations: type Name { Variant, Variant(field: type), ... }
// ---------------------------------------------------------------------------

pub fun parse-type-decl( doc : maybe<string> = Nothing ) : <div,parser> type-def
  val t = expect("type", fn(k) match k { TkType -> True; _ -> False })
  val name = match peek()
    TkIdent(n) -> { advance(); n }
    _          -> { parse-error("expected type name"); "_" }
  expect("{", fn(k) match k { TkLBrace -> True; _ -> False })
  val variants = parse-variant-defs()
  val end-tok = expect("}", fn(k) match k { TkRBrace -> True; _ -> False })
  Type-def(Span(t.span.start, end-tok.span.end), name, variants = variants, doc = doc, is-pub = False)

// Parse variant definitions: Name, Name(field: type, ...), ...
fun parse-variant-defs() : <div,parser> list<variant-def>
  match peek()
    TkRBrace -> []
    TkIdent(name) ->
      advance()
      val fields = match peek()
        TkLParen ->
          advance()
          val fs = parse-variant-fields()
          expect(")", fn(k) match k { TkRParen -> True; _ -> False })
          fs
        _ -> []
      match peek()
        TkComma ->
          advance()
          Cons(Variant-def(name, fields), parse-variant-defs())
        _ -> [Variant-def(name, fields)]
    _ ->
      parse-error("expected variant name in type definition")
      []

// Parse variant fields: name: type, ...
fun parse-variant-fields() : <div,parser> list<(string, hica-type)>
  match peek()
    TkRParen -> []
    TkIdent(name) ->
      advance()
      expect(":", fn(k) match k { TkColon -> True; _ -> False })
      val ftype = parse-type()
      match peek()
        TkComma ->
          advance()
          Cons((name, ftype), parse-variant-fields())
        _ -> [(name, ftype)]
    _ ->
      parse-error("expected field name in variant definition")
      []

// ---------------------------------------------------------------------------
// Test declarations: test "name" { body }
// ---------------------------------------------------------------------------

pub fun parse-test-decl() : <div,parser> test-decl
  val t = expect("test", fn(k) match k { TkTest -> True; _ -> False })
  val name = match peek()
    TkString(s) -> { advance(); s }
    _           -> { parse-error("expected test name string"); "unnamed" }
  val body = parse-block()
  Test-decl(Span(t.span.start, body.span.end), name, body)

// ---------------------------------------------------------------------------
// Top-level declarations: fun name(params) { body } or fun name(params) => expr
// ---------------------------------------------------------------------------

pub fun parse-fun-decl( doc : maybe<string> = Nothing ) : <div,parser> fun-decl
  val is-pub = match peek()
    TkPub -> { advance(); True }
    _     -> False
  val is-noinline = match peek()
    TkNoinline -> { advance(); True }
    _          -> False
  val t = expect("fun", fn(k) match k { TkFun -> True; _ -> False })
  val name = match peek()
    TkIdent(n) -> { advance(); n }
    _          -> { parse-error("expected function name"); "_" }
  expect("(", fn(k) match k { TkLParen -> True; _ -> False })
  val typed-params = parse-typed-params()
  expect(")", fn(k) match k { TkRParen -> True; _ -> False })
  val (fun-eff-row, ret-ann) = parse-optional-ret-ann()
  val param-names = typed-params.map(fn(e) e.fst)
  val p-anns = typed-params.map(fn(e) e.snd)
  val body = match peek()
    TkArrow ->
      advance()
      parse-expr()
    _ ->
      parse-block()
  Fun-decl(Span(t.span.start, body.span.end), name, params = param-names, body = body, doc = doc, param-anns = p-anns, ret-ann = ret-ann, fun-effects = fun-eff-row, is-pub = is-pub, is-noinline = is-noinline)

fun parse-global-decl() : <div,parser> global-decl
  val t = expect("let", fn(k) match k { TkLet -> True; _ -> False })
  val name = match peek()
    TkIdent(n) -> { advance(); n }
    _          -> { parse-error("expected identifier after 'let'"); "_" }
  val ann = parse-optional-type-ann()
  expect("=", fn(k) match k { TkEq -> True; _ -> False })
  val body = parse-expr()
  match peek()
    TkSemicolon -> { advance(); () }
    _           -> ()
  Global-decl(Span(t.span.start, body.span.end), name, body, ann = ann)

// ---------------------------------------------------------------------------
// Effect declarations (design doc §4.1)
//
//   effect Name { fun op(param: T, ...) : Ret ... }
//
// Each op is `fun op(<typed-params>) : <ret>`; a missing return type
// defaults to TUnit (parse-optional-type-ann returns Nothing → TUnit here).
// Untyped params get TVar("_") — the M1 checker leaves op-args untyped
// via fresh type variables inside handler arms, so this placeholder is
// only used for effect-def emission and design-doc-compliant AST shape.
// ---------------------------------------------------------------------------

fun parse-effect-op( doc : maybe<string> = Nothing ) : <div,parser> effect-op
  val t = expect("fun", fn(k) match k { TkFun -> True; _ -> False })
  val op-name = match peek()
    TkIdent(n) -> { advance(); n }
    _          -> { parse-error("expected operation name"); "_" }
  expect("(", fn(k) match k { TkLParen -> True; _ -> False })
  val typed-params = parse-typed-params()
  val end-paren = expect(")", fn(k) match k { TkRParen -> True; _ -> False })
  val ret-ann = parse-optional-type-ann()
  val ret = match ret-ann
    Just(rt) -> rt
    Nothing  -> TUnit
  // Materialise param types: fresh TVar per untyped param (checker replaces later).
  val params = typed-params.map fn((pname, pann))
    val ptype = match pann
      Just(pt) -> pt
      Nothing  -> TVar("_")
    (pname, ptype)
  Effect-op(Span(t.span.start, end-paren.span.end), op-name, doc, params, ret)

// Parse the contiguous list of op declarations inside `effect Name { … }`.
// Each op is on its own line; no separators required. Optional doc-comments
// preceding an op are attached to that op.
fun parse-effect-ops() : <div,parser> list<effect-op>
  var ops : list<effect-op> := []
  var doc : maybe<string> := Nothing
  while { match peek() { TkFun -> True; TkDocComment(_) -> True; _ -> False } }
    match peek()
      TkDocComment(txt) ->
        advance()
        doc := (match doc { Just(prev) -> Just(prev ++ "\n" ++ txt); Nothing -> Just(txt) })
      TkFun ->
        ops := Cons(parse-effect-op(doc), ops)
        doc := Nothing
      _ -> ()
  ops.reverse

// Parse `effect Name { fun op(...) : T ... }`. Called from parse-program.
// The `pub` prefix (design doc §12 Q2) is consumed by the caller; is-pub is
// passed in.
fun parse-effect-def( is-pub : bool = False, doc : maybe<string> = Nothing ) : <div,parser> effect-def
  val t = expect("effect", fn(k) match k { TkEffect -> True; _ -> False })
  val name = match peek()
    TkIdent(n) -> { advance(); n }
    _          -> { parse-error("expected effect name"); "_" }
  expect("{", fn(k) match k { TkLBrace -> True; _ -> False })
  val ops = parse-effect-ops()
  val end-tok = expect("}", fn(k) match k { TkRBrace -> True; _ -> False })
  Effect-def(Span(t.span.start, end-tok.span.end), name, doc, ops, is-pub)

// ---------------------------------------------------------------------------
// Handle expressions (design doc §4.3)
//
//   handle Name { op(args) => body, ... }
//     (with var x = e, var y = e)?
//     in { body }
//
// Called from parse-prefix on TkHandle. Arms are comma-separated (trailing
// comma allowed). The `with var …` clause is optional (populated in M5;
// parsed here so the surface syntax is stable from M1).
// ---------------------------------------------------------------------------

fun parse-handle-arm() : <div,parser> handle-arm
  val start-sp = current-span()
  val op-name = match peek()
    TkIdent(n) -> { advance(); n }
    _          -> { parse-error("expected operation name in handler arm"); "_" }
  expect("(", fn(k) match k { TkLParen -> True; _ -> False })
  val params = parse-params()
  expect(")", fn(k) match k { TkRParen -> True; _ -> False })
  expect("=>", fn(k) match k { TkArrow -> True; _ -> False })
  val body = parse-expr()
  Handle-arm(Span(start-sp.start, body.span.end), op-name, params, body)

fun parse-handle-arms() : <div,parser> list<handle-arm>
  var arms : list<handle-arm> := []
  while { match peek() { TkRBrace -> False; TkEof -> False; _ -> True } }
    arms := Cons(parse-handle-arm(), arms)
    // optional comma between arms; also tolerate trailing semicolons/newlines
    match peek()
      TkComma     -> { advance(); () }
      TkSemicolon -> { advance(); () }
      _           -> ()
  arms.reverse

// Parse an optional `with var x = e, var y = e` clause after the handler body.
// Returns an empty list if the clause is absent.
fun parse-handle-state() : <div,parser> list<(string, node)>
  // `with` is a real keyword (TkWith); it's only meaningful in this position
  // so it doesn't need to be reserved as an identifier elsewhere.
  match peek()
    TkWith ->
      advance()
      var state : list<(string, node)> := []
      var more := True
      while { more }
        expect("var", fn(k) match k { TkVar -> True; _ -> False })
        val vname = match peek()
          TkIdent(n) -> { advance(); n }
          _          -> { parse-error("expected state variable name after 'var'"); "_" }
        // optional : type — parsed and discarded for M1 (checker infers).
        val _ann = parse-optional-type-ann()
        expect("=", fn(k) match k { TkEq -> True; _ -> False })
        // Parse the initialiser at a binding-power ABOVE `In`'s l-bp (7) so
        // the trailing `in` keyword of `handle … with … in { … }` is never
        // greedily consumed as the binary `in` operator (list membership).
        // See `infix-bp` — `In` has (7, 8), so bp = 9 skips it. All other
        // binops with l-bp >= 9 (Add, Mul, etc.) still work in initialisers.
        // This means state initialisers cannot use `x in list` inline; wrap
        // it in parens: `var found = (x in xs)`.
        val init = parse-binary(9)
        state := Cons((vname, init), state)
        match peek()
          TkComma -> { advance(); () }
          _       -> more := False
      state.reverse
    _ -> []

fun parse-handle-expr() : <div,parser> node
  val t = expect("handle", fn(k) match k { TkHandle -> True; _ -> False })
  val ename = match peek()
    TkIdent(n) -> { advance(); n }
    _          -> { parse-error("expected effect name after 'handle'"); "_" }
  expect("{", fn(k) match k { TkLBrace -> True; _ -> False })
  val arms = parse-handle-arms()
  expect("}", fn(k) match k { TkRBrace -> True; _ -> False })
  val state = parse-handle-state()
  // Consume `in` (a real keyword — TkIn — that here means "the following block
  // is the handled body", not the binary In operator).
  expect("in", fn(k) match k { TkIn -> True; _ -> False })
  val body = parse-block()
  Node(Span(t.span.start, body.span.end), EHandle(ename, arms, state, body))

// ---------------------------------------------------------------------------
// Spawn expressions (named-effects v2, N1 — design doc §4.2)
//
//   spawn Name { op(args) => body, ... }
//     (with var x = e, var y = e)?
//     as ident
//
// Called from parse-prefix on TkSpawn. Arm and state grammar is identical to
// `handle`; only the trailing clause differs (`as ident` instead of `in {…}`).
// The parsed AST is `ESpawn(name, arms, state, binder)`; the binder is
// scoped to the enclosing block by the checker (lenient in N1).
// ---------------------------------------------------------------------------

fun parse-spawn-expr() : <div,parser> node
  val t = expect("spawn", fn(k) match k { TkSpawn -> True; _ -> False })
  val ename = match peek()
    TkIdent(n) -> { advance(); n }
    _          -> { parse-error("expected effect name after 'spawn'"); "_" }
  expect("{", fn(k) match k { TkLBrace -> True; _ -> False })
  val arms = parse-handle-arms()
  expect("}", fn(k) match k { TkRBrace -> True; _ -> False })
  val state = parse-handle-state()
  // Consume `as` (a real keyword — TkAs — that binds the fresh reference to
  // the identifier that follows).
  expect("as", fn(k) match k { TkAs -> True; _ -> False })
  val (binder, end-sp) = match peek()
    TkIdent(n) ->
      val nt = advance()
      (n, nt.span)
    _ ->
      parse-error("expected binder identifier after 'as' in spawn expression")
      ("_", current-span())
  Node(Span(t.span.start, end-sp.end), ESpawn(ename, arms, state, binder))

// ---------------------------------------------------------------------------
// Actor declarations (design doc §11.4 / §13.4, milestone M6)
//
//   actor Name {
//     var s1 = init1
//     var s2 : T = init2
//     receive(msg: MsgType) => <body>
//   }
//
// Desugars into TWO top-level items:
//
//   1. effect Name { fun send_<name>(msg: MsgType) : () }
//   2. pub fun with_<name>(action) {
//        handle Name {
//          send_<name>(msg) => <receive-body-verbatim>
//        } with var s1 = init1, var s2 = init2 in {
//          action()
//        }
//      }
//
// The `msg` parameter must carry an explicit type annotation
// (`msg: CounterMsg`) — the checker needs it to type the effect op.
// State variables MAY carry annotations; if omitted the helper omits
// them and lets the checker infer via the initialiser (identical to
// hand-written `with var …`).
//
// Design decisions (documented in effects-journal.md M6):
//   * The single op is named `send_<name>` (e.g. `send_counter`,
//     `send_pinger`) — not bare `send`. Effect-op namespaces are
//     currently flat (design doc §8.2), so naming the op after the
//     actor sidesteps the ambiguity when two actors coexist. This
//     is the design-doc §13.4 workaround for the pre-named-effects
//     era; when named effects land (post-M6, §10) we can drop the
//     `_<name>` suffix and let users write `counter.send(Incr)`.
//   * With_<name> helper generated as `pub` so it crosses module
//     boundaries just like ordinary `pub fun`.
//   * The receive body is copied verbatim into the arm; the message
//     parameter name is preserved so the body's `match msg { … }`
//     continues to bind correctly.
//   * The old Phase-1 shape (`<Name>State` struct + `<name>_receive`
//     function) is retired — no shipped example uses the `actor`
//     keyword (see effects-journal.md M6 log for the audit).
// ---------------------------------------------------------------------------

fun parse-actor-decl() : <div,parser> (effect-def, fun-decl)
  val t = expect("actor", fn(k) match k { TkActor -> True; _ -> False })
  val name = match peek()
    TkIdent(n) -> { advance(); n }
    _          -> { parse-error("expected actor name"); "_" }

  expect("{", fn(k) match k { TkLBrace -> True; _ -> False })

  // State bindings — same as `handle … with var …` clause but written
  // as `var x = init` (with optional `: T` annotation), one per line.
  // Whether the annotation is present is preserved so the generated
  // helper can carry it into the `with var` clause verbatim.
  var state-bindings : list<(string, maybe<hica-type>, node)> := []

  while { match peek() { TkVar -> True; _ -> False } }
    advance() // consume 'var'
    val var-name = match peek()
      TkIdent(n) -> { advance(); n }
      _          -> { parse-error("expected state variable name"); "_" }
    val ann = parse-optional-type-ann()
    expect("=", fn(k) match k { TkEq -> True; _ -> False })
    // Same bp-9 trick used by parse-handle-state: never let the initialiser
    // greedily consume a trailing `receive` identifier as anything odd.
    val init-expr = parse-binary(9)
    state-bindings := Cons((var-name, ann, init-expr), state-bindings)
    match peek()
      TkSemicolon -> { advance(); () }
      _           -> ()

  // The `receive(msg: MsgType)` header. The msg annotation is REQUIRED
  // (§13.4 exit criterion + user-agreed session-11 decision) so we can
  // materialise the effect op signature.
  expect("receive", fn(k) match k { TkIdent("receive") -> True; _ -> False })
  expect("(", fn(k) match k { TkLParen -> True; _ -> False })
  val msg-param = match peek()
    TkIdent(n) -> { advance(); n }
    _          -> { parse-error("expected message parameter name"); "msg" }
  val msg-ann = parse-optional-type-ann()
  val msg-type = match msg-ann
    Just(ty) -> ty
    Nothing  ->
      parse-error("actor '" ++ name ++ "': receive parameter needs an explicit type annotation, e.g. receive(msg: " ++ name ++ "Msg)")
      TVar("_")
  expect(")", fn(k) match k { TkRParen -> True; _ -> False })

  val body-start = current-span()
  val receive-body = match peek()
    TkArrow ->
      advance()
      parse-expr()
    _ ->
      parse-block()

  val end-tok = expect("}", fn(k) match k { TkRBrace -> True; _ -> False })

  // (1) Effect declaration: `effect Name { fun send_<name>(msg: MsgType) : () }`
  val send-op-name = "send_" ++ name.to-lower
  val send-op = Effect-op(Span(t.span.start, end-tok.span.end),
                          send-op-name,
                          params = [(msg-param, msg-type)],
                          ret = TUnit)
  val edef = Effect-def(Span(t.span.start, end-tok.span.end),
                        name,
                        ops = [send-op],
                        is-pub = False)

  // (2) Helper function: `pub fun with_<name>(action) { handle Name { … } with var … in { action() } }`
  val handle-arms = [Handle-arm(Span(body-start.start, end-tok.span.end),
                                send-op-name, [msg-param], receive-body)]
  val state-clause = state-bindings.reverse.map(fn((n, _ann, init)) (n, init))
  val action-call  = Node(body-start, Call(Node(body-start, Var("action")), []))
  val action-block = Node(body-start, Block([action-call]))
  val handle-node  = Node(Span(t.span.start, end-tok.span.end),
                          EHandle(name, handle-arms, state-clause, action-block))
  val helper-body  = Node(Span(t.span.start, end-tok.span.end), Block([handle-node]))
  val helper-name  = "with_" ++ name.to-lower
  val fdecl = Fun-decl(Span(t.span.start, end-tok.span.end),
                       helper-name,
                       params = ["action"],
                       body = helper-body,
                       param-anns = [Nothing],
                       ret-ann = Nothing,
                       is-pub = True)

  (edef, fdecl)

pub fun parse-program() : <div,parser> program
  var decls := []
  var structs := []
  var types := []
  var effects : list<effect-def> := []
  var globals := []
  var tests := []
  var imports := []
  // Parse imports at the top of the file
  while { match peek() { TkImport -> True; TkFrom -> True; TkExtern -> True; _ -> False } }
    imports := Cons(parse-import-decl(), imports)
  
  var current-doc : maybe<string> := Nothing
  // Parse remaining declarations
  while { match peek() { TkEof -> False; _ -> True } }
    match peek()
      TkDocComment(txt) ->
        advance()
        current-doc := (match current-doc { Just(prev) -> Just(prev ++ "\n" ++ txt); Nothing -> Just(txt) })
      TkOpaque ->
        advance()
        match peek()
          TkStruct ->
            val sd = parse-struct-decl(current-doc)
            structs := Cons(sd(is-opaque = True), structs)
          _ ->
            parse-error("expected 'struct' after 'opaque'")
            ()
        current-doc := Nothing
      TkStruct ->
        structs := Cons(parse-struct-decl(current-doc), structs)
        current-doc := Nothing
      TkType ->
        types := Cons(parse-type-decl(current-doc), types)
        current-doc := Nothing
      TkEffect ->
        val edef = parse-effect-def(False, current-doc)
        effects := Cons(edef, effects)
        current-doc := Nothing
      TkTest ->
        if !current-doc.is-nothing then
          val _ = parse-error("doc comment ignored on test declaration")
          ()
        tests := Cons(parse-test-decl(), tests)
        current-doc := Nothing
      TkExtern ->
        if !current-doc.is-nothing then
          val _ = parse-error("doc comment ignored on extern declaration")
          ()
        imports := Cons(parse-import-decl(), imports)
        current-doc := Nothing
      TkLet ->
        if !current-doc.is-nothing then
          val _ = parse-error("doc comment ignored on let declaration")
          ()
        globals := Cons(parse-global-decl(), globals)
        current-doc := Nothing
      TkActor ->
        if !current-doc.is-nothing then
          val _ = parse-error("doc comment ignored on actor declaration")
          ()
        // M6: an actor desugars to an effect declaration plus a
        // pub fun with_<name>(action) helper. The old Phase-1 shape
        // (struct + <name>_receive) is retired; no shipped example
        // uses the `actor` keyword.
        val (edef, fdecl) = parse-actor-decl()
        effects := Cons(edef, effects)
        decls   := Cons(fdecl, decls)
        current-doc := Nothing
      TkFun ->
        decls := Cons(parse-fun-decl(current-doc), decls)
        current-doc := Nothing
      TkNoinline ->
        decls := Cons(parse-fun-decl(current-doc), decls)
        current-doc := Nothing
      TkPub ->
        // pub import "path" — re-export
        match peek-next()
          TkImport ->
            if !current-doc.is-nothing then
              val _ = parse-error("doc comment ignored on pub import")
              ()
            imports := Cons(parse-import-decl(), imports)
          TkExtern ->
            if !current-doc.is-nothing then
              val _ = parse-error("doc comment ignored on pub extern")
              ()
            imports := Cons(parse-import-decl(), imports)
          TkStruct ->
            advance()
            val sd = parse-struct-decl(current-doc)
            structs := Cons(sd(is-pub = True), structs)
          TkType ->
            advance()
            val td = parse-type-decl(current-doc)
            types := Cons(td(is-pub = True), types)
          TkLet ->
            if !current-doc.is-nothing then
              val _ = parse-error("doc comment ignored on pub let")
              ()
            advance()
            val gd = parse-global-decl()
            globals := Cons(gd(is-pub = True), globals)
          _ ->
            decls := Cons(parse-fun-decl(current-doc), decls)
        current-doc := Nothing
      _ ->
        if !current-doc.is-nothing then
          val _ = parse-error("doc comment ignored")
          ()
        decls := Cons(parse-fun-decl(current-doc), decls)
        current-doc := Nothing
  Program(structs.reverse, types = types.reverse, effects = effects.reverse, decls = decls.reverse, globals = globals.reverse, tests = tests.reverse, imports = imports.reverse)

// ---------------------------------------------------------------------------
// Runner: handle the parser effect over a token list
// ---------------------------------------------------------------------------

// Compute (line, column) from a 0-based character offset.
// Both line and column are 1-based in the output.
fun offset-to-linecol( source : string, offset : int ) : (int, int)
  if source.is-empty then (0, offset)
  else
    var line := 1
    var col  := 1
    var i    := 0
    source.list.foreach fn(c)
      if i < offset then
        if c == '\n' then
          line := line + 1
          col  := 1
        else
          col := col + 1
        i := i + 1
    (line, col)

pub fun run-parser( tokens : list<token>, action : () -> <div,parser,console> node, source : string = "" ) : <div,console> node
  var toks := tokens
  with handler
    fun peek()
      match toks
        Cons(t, _) -> t.kind
        Nil        -> TkEof
    fun peek-next()
      match toks
        Cons(_, Cons(t2, _)) -> t2.kind
        _ -> TkEof
    fun peek-newline()
      match toks
        Cons(t, _) -> t.newline-before
        Nil        -> False
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
      val (line, col) = offset-to-linecol(source, sp.start)
      println("parse error at " ++ line.show ++ ":" ++ col.show ++ ": " ++ msg)
      Node(sp, Literal(LitBool(False)))
  action()

pub fun run-parser-program( tokens : list<token>, source : string = "" ) : <div,console> program
  var toks := tokens
  with handler
    fun peek()
      match toks
        Cons(t, _) -> t.kind
        Nil        -> TkEof
    fun peek-next()
      match toks
        Cons(_, Cons(t2, _)) -> t2.kind
        _ -> TkEof
    fun peek-newline()
      match toks
        Cons(t, _) -> t.newline-before
        Nil        -> False
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
      val (line, col) = offset-to-linecol(source, sp.start)
      println("parse error at " ++ line.show ++ ":" ++ col.show ++ ": " ++ msg)
      Node(sp, Literal(LitBool(False)))
  parse-program()

// Like run-parser-program but also returns the list of parse error messages.
// Used for testing — does not print errors to console.
pub fun run-parser-program-with-errors( tokens : list<token>, source : string = "" ) : <div> (program, list<string>)
  var toks := tokens
  var errs := []
  with handler
    fun peek()
      match toks
        Cons(t, _) -> t.kind
        Nil        -> TkEof
    fun peek-next()
      match toks
        Cons(_, Cons(t2, _)) -> t2.kind
        _ -> TkEof
    fun peek-newline()
      match toks
        Cons(t, _) -> t.newline-before
        Nil        -> False
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
      val (line, col) = offset-to-linecol(source, sp.start)
      errs := errs ++ ["parse error at " ++ line.show ++ ":" ++ col.show ++ ": " ++ msg]
      Node(sp, Literal(LitBool(False)))
  val prog = parse-program()
  (prog, errs)

// ---------------------------------------------------------------------------
// REPL fragment parser: parse a single declaration or expression
// ---------------------------------------------------------------------------

pub fun parse-repl-input() : <div,parser> repl-input
  match peek()
    TkFun    -> ReplDecl(parse-fun-decl())
    TkPub    ->
      match peek-next()
        TkFun    -> ReplDecl(parse-fun-decl())
        TkStruct -> { advance(); ReplStruct(parse-struct-decl()(is-pub = True)) }
        TkType   -> { advance(); ReplType(parse-type-decl()(is-pub = True)) }
        TkImport -> ReplImport(parse-import-decl())
        _        -> ReplDecl(parse-fun-decl())
    TkOpaque ->
      advance()
      match peek()
        TkStruct -> ReplStruct(parse-struct-decl()(is-opaque = True))
        _        -> { parse-error("expected 'struct' after 'opaque'"); ReplExpr(parse-expr()) }
    TkStruct -> ReplStruct(parse-struct-decl())
    TkType   -> ReplType(parse-type-decl())
    TkImport -> ReplImport(parse-import-decl())
    TkFrom   -> ReplImport(parse-import-decl())
    TkExtern -> ReplImport(parse-import-decl())
    _        -> ReplExpr(parse-expr())

pub fun run-parser-repl( tokens : list<token>, source : string = "" ) : <div,console> repl-input
  var toks := tokens
  with handler
    fun peek()
      match toks
        Cons(t, _) -> t.kind
        Nil        -> TkEof
    fun peek-next()
      match toks
        Cons(_, Cons(t2, _)) -> t2.kind
        _ -> TkEof
    fun peek-newline()
      match toks
        Cons(t, _) -> t.newline-before
        Nil        -> False
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
      val (line, col) = offset-to-linecol(source, sp.start)
      println("parse error at " ++ line.show ++ ":" ++ col.show ++ ": " ++ msg)
      Node(sp, Literal(LitBool(False)))
  parse-repl-input()

pub fun run-parser-repl-tracked( tokens : list<token>, source : string ) : <div,console> (repl-input, bool)
  var toks := tokens
  var had-errors := False
  with handler
    fun peek()
      match toks
        Cons(t, _) -> t.kind
        Nil        -> TkEof
    fun peek-next()
      match toks
        Cons(_, Cons(t2, _)) -> t2.kind
        _ -> TkEof
    fun peek-newline()
      match toks
        Cons(t, _) -> t.newline-before
        Nil        -> False
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
      val (line, col) = offset-to-linecol(source, sp.start)
      println("parse error at " ++ line.show ++ ":" ++ col.show ++ ": " ++ msg)
      had-errors := True
      Node(sp, Literal(LitBool(False)))
  val result = parse-repl-input()
  (result, had-errors)
