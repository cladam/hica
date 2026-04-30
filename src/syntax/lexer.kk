/*
 * hica – lexical analysis
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
module syntax/lexer

import syntax/ast

// ---------------------------------------------------------------------------
// Tokens
// ---------------------------------------------------------------------------

pub type token-kind
  // Literals
  TkInt( value : int )
  TkFloat( value : string )
  TkBool( value : bool )
  TkString( value : string )
  // String interpolation: "hello {name}!" becomes
  //   TkInterpStart  TkStringPart("hello ")  TkInterpExpr  ...expr tokens...  TkRBrace  TkStringPart("!")  TkInterpEnd
  TkInterpStart                     // opening " of interpolated string
  TkStringPart( value : string )    // literal text segment between { }
  TkInterpExpr                      // { that opens an expression
  TkInterpEnd                       // closing " of interpolated string
  // Identifiers and keywords
  TkIdent( name : string )
  TkLet
  TkFn
  TkFun
  TkIf
  TkElse
  TkMatch
  TkRepeat
  TkTrue
  TkFalse
  // Punctuation
  TkLParen
  TkRParen
  TkLBrace
  TkRBrace
  TkComma
  TkSemicolon
  TkColon
  TkArrow       // =>
  TkThinArrow   // ->
  // Operators
  TkPlus
  TkMinus
  TkStar
  TkSlash
  TkEq          // =
  TkEqEq        // ==
  TkBangEq      // !=
  TkLt
  TkGt
  TkLe
  TkGe
  TkAmpAmp      // &&
  TkPipePipe    // ||
  TkPipeGt      // |>
  TkBang        // !
  // Special
  TkEof
  TkError( msg : string )

pub struct token
  kind : token-kind
  span : span

pub fun token/show( t : token ) : string
  t.kind.show

pub fun token-kind/show( tk : token-kind ) : string
  match tk
    TkInt(v)     -> v.show
    TkFloat(v)   -> v
    TkBool(v)    -> v.show
    TkString(v)  -> "\"" ++ v ++ "\""
    TkInterpStart   -> "<interp-start>"
    TkStringPart(v) -> "<part:\"" ++ v ++ "\">"
    TkInterpExpr    -> "<interp-expr>"
    TkInterpEnd     -> "<interp-end>"
    TkIdent(n)   -> n
    TkLet        -> "let"
    TkFn         -> "fn"
    TkFun        -> "fun"
    TkIf         -> "if"
    TkElse       -> "else"
    TkMatch      -> "match"
    TkRepeat     -> "repeat"
    TkTrue       -> "true"
    TkFalse      -> "false"
    TkLParen     -> "("
    TkRParen     -> ")"
    TkLBrace     -> "{"
    TkRBrace     -> "}"
    TkComma      -> ","
    TkSemicolon  -> ";"
    TkColon      -> ":"
    TkArrow      -> "=>"
    TkThinArrow  -> "->"
    TkPlus       -> "+"
    TkMinus      -> "-"
    TkStar       -> "*"
    TkSlash      -> "/"
    TkEq         -> "="
    TkEqEq       -> "=="
    TkBangEq     -> "!="
    TkLt         -> "<"
    TkGt         -> ">"
    TkLe         -> "<="
    TkGe         -> ">="
    TkAmpAmp     -> "&&"
    TkPipePipe   -> "||"
    TkPipeGt     -> "|>"
    TkBang       -> "!"
    TkEof        -> "<eof>"
    TkError(m)   -> "<error: " ++ m ++ ">"

// ---------------------------------------------------------------------------
// Lexer
// ---------------------------------------------------------------------------

pub fun lex( source : string ) : div list<token>
  lex-from(source.list, 0)

fun lex-from( cs : list<char>, pos : int ) : div list<token>
  match cs
    Nil -> [Token(TkEof, Span(pos, pos))]
    Cons(c, rest) ->
      if c.is-white then lex-from(rest, pos + 1)
      elif c == '/' && rest.head-is('/') then skip-line-comment(rest.tail, pos)
      elif c.is-digit then lex-number(cs, pos)
      elif c.is-alpha || c == '_' then lex-ident(cs, pos)
      elif c == '"' then lex-string(rest, pos, pos + 1)
      else lex-punct(cs, pos)

fun head-is( cs : list<char>, ch : char ) : bool
  match cs
    Cons(c, _) -> c == ch
    _          -> False

fun skip-line-comment( cs : list<char>, pos : int ) : div list<token>
  match cs
    Nil             -> [Token(TkEof, Span(pos, pos))]
    Cons('\n', rest) -> lex-from(rest, pos + 1)
    Cons(_, rest)   -> skip-line-comment(rest, pos + 1)

fun lex-number( cs : list<char>, start : int ) : div list<token>
  val (digits, rest) = cs.span(fn(c) c.is-digit)
  match rest
    Cons('.', Cons(d, _)) | d.is-digit ->
      val (frac, rest2) = rest.tail.span(fn(c) c.is-digit)
      val text = digits.string ++ "." ++ frac.string
      val end = start + digits.length + 1 + frac.length
      Cons(Token(TkFloat(text), Span(start, end)), lex-from(rest2, end))
    _ ->
      val n = digits.string.parse-int.default(0)
      val end = start + digits.length
      Cons(Token(TkInt(n), Span(start, end)), lex-from(rest, end))

fun lex-ident( cs : list<char>, start : int ) : div list<token>
  val (chars, rest) = cs.span(fn(c) c.is-alpha || c.is-digit || c == '_')
  val word = chars.string
  val end = start + chars.length
  val kind = match word
    "let"   -> TkLet
    "fn"    -> TkFn
    "fun"   -> TkFun
    "if"    -> TkIf
    "else"  -> TkElse
    "match"  -> TkMatch
    "repeat" -> TkRepeat
    "true"   -> TkBool(True)
    "false"  -> TkBool(False)
    _       -> TkIdent(word)
  Cons(Token(kind, Span(start, end)), lex-from(rest, end))

fun lex-string( cs : list<char>, start : int, pos : int ) : div list<token>
  // First, check if this string contains '{' (interpolation)
  if string-has-interp(cs) then
    Cons(Token(TkInterpStart, Span(start, start + 1)), lex-interp-parts(cs, start, pos))
  else
    lex-plain-string(cs, start, pos)

// Check whether a string body (after opening ") contains a '{' before the closing '"'
fun string-has-interp( cs : list<char> ) : bool
  match cs
    Nil            -> False
    Cons('"', _)   -> False
    Cons('{', _)   -> True
    Cons(_, rest)  -> string-has-interp(rest)

// Lex a plain string (no interpolation) — original behaviour
fun lex-plain-string( cs : list<char>, start : int, pos : int ) : div list<token>
  match cs
    Nil -> [Token(TkError("unterminated string"), Span(start, pos))]
    Cons('"', rest) ->
      Cons(Token(TkString(""), Span(start, pos + 1)), lex-from(rest, pos + 1))
    Cons(_, rest) ->
      match lex-plain-string(rest, start, pos + 1)
        Cons(Token(TkString(s), sp), toks) ->
          match cs
            Cons(c, _) -> Cons(Token(TkString(c.string ++ s), sp), toks)
            _          -> Cons(Token(TkString(s), sp), toks)
        other -> other

// Lex interpolated string parts: text segments and {expr} holes
fun lex-interp-parts( cs : list<char>, start : int, pos : int ) : div list<token>
  match cs
    Nil -> [Token(TkError("unterminated interpolated string"), Span(start, pos))]
    Cons('"', rest) ->
      // End of interpolated string
      Cons(Token(TkInterpEnd, Span(pos, pos + 1)), lex-from(rest, pos + 1))
    Cons('{', rest) ->
      // Start of expression hole — lex the expression tokens until matching '}'
      Cons(Token(TkInterpExpr, Span(pos, pos + 1)), lex-interp-expr(rest, start, pos + 1, 1))
    _ ->
      // Accumulate a text segment until '{' or '"'
      val (text, text-end, remaining) = collect-string-part(cs, pos)
      Cons(Token(TkStringPart(text), Span(pos, text-end)), lex-interp-parts(remaining, start, text-end))

// Collect literal text characters until we hit '{' or '"' (or end of input)
fun collect-string-part( cs : list<char>, pos : int ) : (string, int, list<char>)
  match cs
    Nil           -> ("", pos, Nil)
    Cons('"', _)  -> ("", pos, cs)
    Cons('{', _)  -> ("", pos, cs)
    Cons(c, rest) ->
      val (s, end, remaining) = collect-string-part(rest, pos + 1)
      (c.string ++ s, end, remaining)

// Lex expression tokens inside an interpolation hole.
// We track brace depth so nested {}'s work (e.g., "{if x { 1 } else { 2 }}").
// When we hit the matching '}', we resume string lexing.
fun lex-interp-expr( cs : list<char>, str-start : int, pos : int, depth : int ) : div list<token>
  match cs
    Nil -> [Token(TkError("unterminated interpolation expression"), Span(str-start, pos))]
    Cons('}', rest) ->
      if depth == 1 then
        // Closing brace of the interpolation hole — resume string parts
        // We emit TkRBrace so the parser knows the expression ended
        Cons(Token(TkRBrace, Span(pos, pos + 1)), lex-interp-parts(rest, str-start, pos + 1))
      else
        // Nested brace — emit as normal token
        Cons(Token(TkRBrace, Span(pos, pos + 1)), lex-interp-expr(rest, str-start, pos + 1, depth - 1))
    Cons('{', rest) ->
      Cons(Token(TkLBrace, Span(pos, pos + 1)), lex-interp-expr(rest, str-start, pos + 1, depth + 1))
    _ ->
      // Lex one normal token, then continue in interp-expr mode
      // We reuse lex-from but need to intercept the result to stay in interp mode
      lex-one-interp(cs, str-start, pos, depth)

// Lex a single token inside an interpolation expression, then continue in interp-expr mode.
// Handles whitespace, identifiers, numbers, and operators.
fun lex-one-interp( cs : list<char>, str-start : int, pos : int, depth : int ) : div list<token>
  match cs
    Nil -> [Token(TkError("unterminated interpolation expression"), Span(str-start, pos))]
    Cons(c, rest) ->
      if c.is-white then lex-one-interp(rest, str-start, pos + 1, depth)
      elif c.is-digit then
        val (digits, rem) = cs.span(fn(ch) ch.is-digit)
        match rem
          Cons('.', Cons(d, _)) | d.is-digit ->
            val (frac, rem2) = rem.tail.span(fn(ch) ch.is-digit)
            val text = digits.string ++ "." ++ frac.string
            val end = pos + digits.length + 1 + frac.length
            Cons(Token(TkFloat(text), Span(pos, end)), lex-interp-expr(rem2, str-start, end, depth))
          _ ->
            val n = digits.string.parse-int.default(0)
            val end = pos + digits.length
            Cons(Token(TkInt(n), Span(pos, end)), lex-interp-expr(rem, str-start, end, depth))
      elif c.is-alpha || c == '_' then
        val (chars, rem) = cs.span(fn(ch) ch.is-alpha || ch.is-digit || ch == '_')
        val word = chars.string
        val end = pos + chars.length
        val kind = match word
          "let"    -> TkLet
          "fn"     -> TkFn
          "fun"    -> TkFun
          "if"     -> TkIf
          "else"   -> TkElse
          "match"  -> TkMatch
          "repeat" -> TkRepeat
          "true"   -> TkBool(True)
          "false"  -> TkBool(False)
          _        -> TkIdent(word)
        Cons(Token(kind, Span(pos, end)), lex-interp-expr(rem, str-start, end, depth))
      elif c == '"' then
        // Nested string inside interpolation
        lex-string-then-interp(rest, str-start, pos, pos + 1, depth)
      else
        // Punctuation / operators — lex one or two char token
        lex-punct-interp(cs, str-start, pos, depth)

// Lex a plain string inside an interpolation expression, then continue in interp-expr mode.
fun lex-string-then-interp( cs : list<char>, str-start : int, quote-pos : int, pos : int, depth : int ) : div list<token>
  match cs
    Nil -> [Token(TkError("unterminated string in interpolation"), Span(quote-pos, pos))]
    Cons('"', rest) ->
      Cons(Token(TkString(""), Span(quote-pos, pos + 1)), lex-interp-expr(rest, str-start, pos + 1, depth))
    Cons(c, rest) ->
      match lex-string-then-interp(rest, str-start, quote-pos, pos + 1, depth)
        Cons(Token(TkString(s), sp), toks) ->
          Cons(Token(TkString(c.string ++ s), sp), toks)
        other -> other

// Lex a punctuation/operator token inside an interpolation expression.
fun lex-punct-interp( cs : list<char>, str-start : int, pos : int, depth : int ) : div list<token>
  match cs
    Cons('=', Cons('>', rem)) -> Cons(Token(TkArrow, Span(pos, pos+2)), lex-interp-expr(rem, str-start, pos+2, depth))
    Cons('=', Cons('=', rem)) -> Cons(Token(TkEqEq, Span(pos, pos+2)), lex-interp-expr(rem, str-start, pos+2, depth))
    Cons('!', Cons('=', rem)) -> Cons(Token(TkBangEq, Span(pos, pos+2)), lex-interp-expr(rem, str-start, pos+2, depth))
    Cons('<', Cons('=', rem)) -> Cons(Token(TkLe, Span(pos, pos+2)), lex-interp-expr(rem, str-start, pos+2, depth))
    Cons('>', Cons('=', rem)) -> Cons(Token(TkGe, Span(pos, pos+2)), lex-interp-expr(rem, str-start, pos+2, depth))
    Cons('-', Cons('>', rem)) -> Cons(Token(TkThinArrow, Span(pos, pos+2)), lex-interp-expr(rem, str-start, pos+2, depth))
    Cons('&', Cons('&', rem)) -> Cons(Token(TkAmpAmp, Span(pos, pos+2)), lex-interp-expr(rem, str-start, pos+2, depth))
    Cons('|', Cons('|', rem)) -> Cons(Token(TkPipePipe, Span(pos, pos+2)), lex-interp-expr(rem, str-start, pos+2, depth))
    Cons('|', Cons('>', rem)) -> Cons(Token(TkPipeGt, Span(pos, pos+2)), lex-interp-expr(rem, str-start, pos+2, depth))
    Cons('=', rem) -> Cons(Token(TkEq, Span(pos, pos+1)), lex-interp-expr(rem, str-start, pos+1, depth))
    Cons('!', rem) -> Cons(Token(TkBang, Span(pos, pos+1)), lex-interp-expr(rem, str-start, pos+1, depth))
    Cons('(', rem) -> Cons(Token(TkLParen, Span(pos, pos+1)), lex-interp-expr(rem, str-start, pos+1, depth))
    Cons(')', rem) -> Cons(Token(TkRParen, Span(pos, pos+1)), lex-interp-expr(rem, str-start, pos+1, depth))
    Cons(',', rem) -> Cons(Token(TkComma, Span(pos, pos+1)), lex-interp-expr(rem, str-start, pos+1, depth))
    Cons(';', rem) -> Cons(Token(TkSemicolon, Span(pos, pos+1)), lex-interp-expr(rem, str-start, pos+1, depth))
    Cons(':', rem) -> Cons(Token(TkColon, Span(pos, pos+1)), lex-interp-expr(rem, str-start, pos+1, depth))
    Cons('+', rem) -> Cons(Token(TkPlus, Span(pos, pos+1)), lex-interp-expr(rem, str-start, pos+1, depth))
    Cons('-', rem) -> Cons(Token(TkMinus, Span(pos, pos+1)), lex-interp-expr(rem, str-start, pos+1, depth))
    Cons('*', rem) -> Cons(Token(TkStar, Span(pos, pos+1)), lex-interp-expr(rem, str-start, pos+1, depth))
    Cons('/', rem) -> Cons(Token(TkSlash, Span(pos, pos+1)), lex-interp-expr(rem, str-start, pos+1, depth))
    Cons('<', rem) -> Cons(Token(TkLt, Span(pos, pos+1)), lex-interp-expr(rem, str-start, pos+1, depth))
    Cons('>', rem) -> Cons(Token(TkGt, Span(pos, pos+1)), lex-interp-expr(rem, str-start, pos+1, depth))
    Cons(c, rem) -> Cons(Token(TkError("unexpected character in interpolation: " ++ c.string), Span(pos, pos+1)), lex-interp-expr(rem, str-start, pos+1, depth))
    Nil -> [Token(TkError("unterminated interpolation expression"), Span(str-start, pos))]

fun lex-punct( cs : list<char>, pos : int ) : div list<token>
  match cs
    Cons('=', Cons('>', rest)) -> Cons(Token(TkArrow, Span(pos, pos+2)), lex-from(rest, pos+2))
    Cons('=', Cons('=', rest)) -> Cons(Token(TkEqEq, Span(pos, pos+2)), lex-from(rest, pos+2))
    Cons('!', Cons('=', rest)) -> Cons(Token(TkBangEq, Span(pos, pos+2)), lex-from(rest, pos+2))
    Cons('<', Cons('=', rest)) -> Cons(Token(TkLe, Span(pos, pos+2)), lex-from(rest, pos+2))
    Cons('>', Cons('=', rest)) -> Cons(Token(TkGe, Span(pos, pos+2)), lex-from(rest, pos+2))
    Cons('-', Cons('>', rest)) -> Cons(Token(TkThinArrow, Span(pos, pos+2)), lex-from(rest, pos+2))
    Cons('&', Cons('&', rest)) -> Cons(Token(TkAmpAmp, Span(pos, pos+2)), lex-from(rest, pos+2))
    Cons('|', Cons('|', rest)) -> Cons(Token(TkPipePipe, Span(pos, pos+2)), lex-from(rest, pos+2))
    Cons('|', Cons('>', rest)) -> Cons(Token(TkPipeGt, Span(pos, pos+2)), lex-from(rest, pos+2))
    Cons('=', rest) -> Cons(Token(TkEq, Span(pos, pos+1)), lex-from(rest, pos+1))
    Cons('!', rest) -> Cons(Token(TkBang, Span(pos, pos+1)), lex-from(rest, pos+1))
    Cons('(', rest) -> Cons(Token(TkLParen, Span(pos, pos+1)), lex-from(rest, pos+1))
    Cons(')', rest) -> Cons(Token(TkRParen, Span(pos, pos+1)), lex-from(rest, pos+1))
    Cons('{', rest) -> Cons(Token(TkLBrace, Span(pos, pos+1)), lex-from(rest, pos+1))
    Cons('}', rest) -> Cons(Token(TkRBrace, Span(pos, pos+1)), lex-from(rest, pos+1))
    Cons(',', rest) -> Cons(Token(TkComma, Span(pos, pos+1)), lex-from(rest, pos+1))
    Cons(';', rest) -> Cons(Token(TkSemicolon, Span(pos, pos+1)), lex-from(rest, pos+1))
    Cons(':', rest) -> Cons(Token(TkColon, Span(pos, pos+1)), lex-from(rest, pos+1))
    Cons('+', rest) -> Cons(Token(TkPlus, Span(pos, pos+1)), lex-from(rest, pos+1))
    Cons('-', rest) -> Cons(Token(TkMinus, Span(pos, pos+1)), lex-from(rest, pos+1))
    Cons('*', rest) -> Cons(Token(TkStar, Span(pos, pos+1)), lex-from(rest, pos+1))
    Cons('/', rest) -> Cons(Token(TkSlash, Span(pos, pos+1)), lex-from(rest, pos+1))
    Cons('<', rest) -> Cons(Token(TkLt, Span(pos, pos+1)), lex-from(rest, pos+1))
    Cons('>', rest) -> Cons(Token(TkGt, Span(pos, pos+1)), lex-from(rest, pos+1))
    Cons(c, rest)   -> Cons(Token(TkError("unexpected character: " ++ c.string), Span(pos, pos+1)), lex-from(rest, pos+1))
    Nil             -> [Token(TkEof, Span(pos, pos))]
