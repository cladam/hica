/*
 * hica – abstract syntax tree definitions
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
module syntax/ast

// ---------------------------------------------------------------------------
// Source locations
// ---------------------------------------------------------------------------

pub struct span
  start : int
  end   : int

pub val no-span = Span(0, 0)

pub struct node
  span : span
  expr : expr
  typ  : maybe<hica-type> = Nothing

pub fun node/show( n : node ) : div string
  match n.typ
    Just(t) -> n.expr.show ++ " : " ++ t.show
    Nothing -> n.expr.show

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

pub type hica-type
  TInt
  TFloat
  TBool
  TString
  TUnit
  TTuple( elems : list<hica-type> )
  TFun( params : list<hica-type>, result : hica-type )
  TVar( name : string )

pub fun hica-type/show( t : hica-type ) : div string
  match t
    TInt        -> "int"
    TFloat      -> "float"
    TBool       -> "bool"
    TString     -> "string"
    TUnit       -> "()"
    TTuple(es)  -> "(" ++ es.map(show).join(", ") ++ ")"
    TFun(ps, r) -> "(" ++ ps.map(show).join(", ") ++ ") -> " ++ r.show
    TVar(n)     -> n

pub fun hica-type/(==)( t1 : hica-type, t2 : hica-type ) : div bool
  match (t1, t2)
    (TInt, TInt)       -> True
    (TFloat, TFloat)   -> True
    (TBool, TBool)     -> True
    (TString, TString) -> True
    (TUnit, TUnit)     -> True
    (TTuple(a), TTuple(b)) ->
      a.length == b.length && zip(a, b).all(fn((x, y)) x == y)
    (TVar(a), TVar(b)) -> a == b
    (TFun(ps1, r1), TFun(ps2, r2)) ->
      ps1.length == ps2.length && zip(ps1, ps2).all(fn((a, b)) a == b) && r1 == r2
    _ -> False

// ---------------------------------------------------------------------------
// Expressions
// ---------------------------------------------------------------------------

pub type literal
  LitInt( i : int )
  LitFloat( f : string )
  LitBool( b : bool )
  LitString( s : string )

pub fun literal/show( l : literal ) : string
  match l
    LitInt(i)    -> i.show
    LitFloat(f)  -> f
    LitBool(b)   -> b.show
    LitString(s) -> "\"" ++ s ++ "\""

pub type binop
  Add
  Sub
  Mul
  Div
  Eq
  Neq
  Lt
  Gt
  Le
  Ge
  And
  Or

pub fun binop/show( op : binop ) : string
  match op
    Add -> "+"
    Sub -> "-"
    Mul -> "*"
    Div -> "/"
    Eq  -> "=="
    Neq -> "!="
    Lt  -> "<"
    Gt  -> ">"
    Le  -> "<="
    Ge  -> ">="
    And -> "&&"
    Or  -> "||"

pub type unop
  Neg
  Not

pub fun unop/show( op : unop ) : string
  match op
    Neg -> "-"
    Not -> "!"

pub type expr
  // Literals
  Literal( lit : literal )

  // Variables
  Var( name : string )

  // let name : type = init; body
  Let( name : string, type-ann : maybe<hica-type>, init : node, body : node )

  // fn(params) { body }  or  fn(params) => body
  Fun( params : list<string>, body : node )

  // callee(args)
  Call( callee : node, args : list<node> )

  // Binary and unary operators
  Binary( op : binop, lhs : node, rhs : node )
  Unary( op : unop, operand : node )

  // if cond { then } else { else }
  If( cond : node, then-expr : node, else-expr : node )

  // { stmts }
  Block( stmts : list<node> )

  // match scrutinee { arms }
  Match( scrutinee : node, arms : list<match-arm> )

  // repeat(count) { body }
  Repeat( count : node, body : node )

  // "hello {expr}!" — parts alternate between LitString segments and expressions
  StringInterp( parts : list<node> )

  // (a, b, c) — tuple literal
  Tuple( elems : list<node> )

  // expr.0, expr.1 — tuple field access
  TupleIndex( tuple : node, index : int )

  // let (a, b) = init; body — tuple destructuring
  LetTuple( names : list<string>, init : node, body : node )

pub struct match-arm
  pattern : pattern
  body    : node

pub type pattern
  PWild
  PVar( name : string )
  PLit( lit : literal )

pub fun pattern/show( p : pattern ) : string
  match p
    PWild    -> "_"
    PVar(n)  -> n
    PLit(l)  -> l.show

// ---------------------------------------------------------------------------
// Pretty printing
// ---------------------------------------------------------------------------

pub fun expr/show( e : expr ) : div string
  match e
    Literal(l)       -> l.show
    Var(n)           -> n
    Let(n, _, i, b)  -> "let " ++ n ++ " = " ++ i.show ++ "; " ++ b.show
    Fun(ps, b)       -> "fun(" ++ ps.join(", ") ++ ") => " ++ b.show
    Call(f, args)    -> f.show ++ "(" ++ args.map(show).join(", ") ++ ")"
    Binary(op, l, r) -> "(" ++ l.show ++ " " ++ op.show ++ " " ++ r.show ++ ")"
    Unary(op, o)     -> op.show ++ o.show
    If(c, t, e')     -> "if " ++ c.show ++ " { " ++ t.show ++ " } else { " ++ e'.show ++ " }"
    Block(ss)        -> "{ " ++ ss.map(show).join("; ") ++ " }"
    Match(s, arms)   -> "match " ++ s.show ++ " { " ++ arms.map(fn(a) a.pattern.show ++ " => " ++ a.body.show).join(", ") ++ " }"
    Repeat(c, b)     -> "repeat(" ++ c.show ++ ") " ++ b.show
    StringInterp(ps) -> "\"" ++ ps.map(fn(p) match p.expr { Literal(LitString(s)) -> s; _ -> "{" ++ p.show ++ "}" }).join("") ++ "\""
    Tuple(es)        -> "(" ++ es.map(show).join(", ") ++ ")"
    TupleIndex(t, i) -> t.show ++ "." ++ i.show
    LetTuple(ns, i, b) -> "let (" ++ ns.join(", ") ++ ") = " ++ i.show ++ "; " ++ b.show

// ---------------------------------------------------------------------------
// Top-level declarations
// ---------------------------------------------------------------------------

pub struct fun-decl
  span        : span
  name        : string
  params      : list<string>
  body        : node
  param-types : list<hica-type> = []
  ret-type    : maybe<hica-type> = Nothing

pub fun fun-decl/show( d : fun-decl ) : div string
  "fun " ++ d.name ++ "(" ++ d.params.join(", ") ++ ") " ++ d.body.show

pub struct program
  decls : list<fun-decl>

pub fun program/show( p : program ) : div string
  p.decls.map(show).join("\n\n")
