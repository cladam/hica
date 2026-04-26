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
  TkBool( value : bool )
  TkString( value : string )
  // Identifiers and keywords
  TkIdent( name : string )
  TkLet
  TkFn
  TkIf
  TkElse
  TkMatch
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
    TkBool(v)    -> v.show
    TkString(v)  -> "\"" ++ v ++ "\""
    TkIdent(n)   -> n
    TkLet        -> "let"
    TkFn         -> "fn"
    TkIf         -> "if"
    TkElse       -> "else"
    TkMatch      -> "match"
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
    "if"    -> TkIf
    "else"  -> TkElse
    "match" -> TkMatch
    "true"  -> TkBool(True)
    "false" -> TkBool(False)
    _       -> TkIdent(word)
  Cons(Token(kind, Span(start, end)), lex-from(rest, end))

fun lex-string( cs : list<char>, start : int, pos : int ) : div list<token>
  match cs
    Nil -> [Token(TkError("unterminated string"), Span(start, pos))]
    Cons('"', rest) ->
      Cons(Token(TkString(""), Span(start, pos + 1)), lex-from(rest, pos + 1))
    Cons(_, rest) ->
      // For now, accumulate via recursive calls — we'll optimise later
      match lex-string(rest, start, pos + 1)
        Cons(Token(TkString(s), sp), toks) ->
          match cs
            Cons(c, _) -> Cons(Token(TkString(c.string ++ s), sp), toks)
            _          -> Cons(Token(TkString(s), sp), toks)
        other -> other

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
