/*
 * hica – abstract syntax tree definitions
 * 
 * This source file is part of the hica open source project
 * Copyright (C) 2026 Claes Adamsson <claes.adamsson@gmail.com>
 *
 * See https://github.com/cladam/hica/blob/main/LICENSE for license information
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
  TChar
  TUnit
  TTuple( elems : list<hica-type> )
  TList( elem : hica-type )
  TMaybe( elem : hica-type )
  TResult( ok-type : hica-type, err-type : hica-type )
  TFun( params : list<hica-type>, result : hica-type )
  TVar( name : string )

pub fun hica-type/show( t : hica-type ) : div string
  match t
    TInt        -> "int"
    TFloat      -> "float"
    TBool       -> "bool"
    TString     -> "string"
    TChar       -> "char"
    TUnit       -> "()"
    TTuple(es)  -> "(" ++ es.map(show).join(", ") ++ ")"
    TList(e)    -> "list<" ++ e.show ++ ">"
    TMaybe(e)   -> "maybe<" ++ e.show ++ ">"
    TResult(o, e) -> "result<" ++ o.show ++ ", " ++ e.show ++ ">"
    TFun(ps, r) -> "(" ++ ps.map(show).join(", ") ++ ") -> " ++ r.show
    TVar(n)     -> n

pub fun hica-type/(==)( t1 : hica-type, t2 : hica-type ) : div bool
  match (t1, t2)
    (TInt, TInt)       -> True
    (TFloat, TFloat)   -> True
    (TBool, TBool)     -> True
    (TString, TString) -> True
    (TChar, TChar)     -> True
    (TUnit, TUnit)     -> True
    (TTuple(a), TTuple(b)) ->
      a.length == b.length && zip(a, b).all(fn((x, y)) x == y)
    (TList(a), TList(b)) -> a == b
    (TMaybe(a), TMaybe(b)) -> a == b
    (TResult(o1, e1), TResult(o2, e2)) -> o1 == o2 && e1 == e2
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
  LitChar( c : string )

pub fun literal/show( l : literal ) : string
  match l
    LitInt(i)    -> i.show
    LitFloat(f)  -> f
    LitBool(b)   -> b.show
    LitString(s) -> "\"" ++ s ++ "\""
    LitChar(c)   -> "'" ++ c ++ "'"

pub type binop
  Add
  Sub
  Mul
  Div
  Mod
  Eq
  Neq
  Lt
  Gt
  Le
  Ge
  And
  Or
  In

pub fun binop/show( op : binop ) : string
  match op
    Add -> "+"
    Sub -> "-"
    Mul -> "*"
    Div -> "/"
    Mod -> "%"
    Eq  -> "=="
    Neq -> "!="
    Lt  -> "<"
    Gt  -> ">"
    Le  -> "<="
    Ge  -> ">="
    And -> "&&"
    Or  -> "||"
    In  -> "in"

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

  // for name in start..end { body }
  ForIn( name : string, start : node, end : node, body : node )

  // "hello {expr}!" — parts alternate between LitString segments and expressions
  StringInterp( parts : list<node> )

  // (a, b, c) — tuple literal
  Tuple( elems : list<node> )

  // expr.0, expr.1 — tuple field access
  TupleIndex( tuple : node, index : int )

  // [a, b, c] — list literal
  EList( elems : list<node> )

  // list[index] — list indexing
  ListIndex( list : node, index : node )

  // list[start:end] — list slicing
  ListSlice( list : node, slice-start : maybe<node>, slice-end : maybe<node> )

  // let (a, b) = init; body — tuple destructuring
  LetTuple( names : list<string>, init : node, body : node )

  // Some(x) — wrap value in maybe
  ESome( value : node )

  // None — empty maybe
  ENone

  // Ok(x) — success result
  EOk( value : node )

  // Err(x) — error result
  EErr( value : node )

pub struct match-arm
  pattern : pattern
  body    : node

pub type pattern
  PWild
  PVar( name : string )
  PLit( lit : literal )
  PSome( inner : pattern )
  PNone
  POk( inner : pattern )
  PErr( inner : pattern )

pub fun pattern/show( p : pattern ) : string
  match p
    PWild    -> "_"
    PVar(n)  -> n
    PLit(l)  -> l.show
    PSome(i) -> "Some(" ++ i.show ++ ")"
    PNone    -> "None"
    POk(i)   -> "Ok(" ++ i.show ++ ")"
    PErr(i)  -> "Err(" ++ i.show ++ ")"

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
    ForIn(nm, s, e, b) -> "for " ++ nm ++ " in " ++ s.show ++ ".." ++ e.show ++ " " ++ b.show
    StringInterp(ps) -> "\"" ++ ps.map(fn(p) match p.expr { Literal(LitString(s)) -> s; _ -> "{" ++ p.show ++ "}" }).join("") ++ "\""
    Tuple(es)        -> "(" ++ es.map(show).join(", ") ++ ")"
    EList(es)        -> "[" ++ es.map(show).join(", ") ++ "]"
    ListIndex(l, i)  -> l.show ++ "[" ++ i.show ++ "]"
    ListSlice(l, s, e) ->
      val s-str = match s { Just(n) -> n.show; Nothing -> "" }
      val e-str = match e { Just(n) -> n.show; Nothing -> "" }
      l.show ++ "[" ++ s-str ++ ":" ++ e-str ++ "]"
    TupleIndex(t, i) -> t.show ++ "." ++ i.show
    LetTuple(ns, i, b) -> "let (" ++ ns.join(", ") ++ ") = " ++ i.show ++ "; " ++ b.show
    ESome(v)         -> "Some(" ++ v.show ++ ")"
    ENone            -> "None"
    EOk(v)           -> "Ok(" ++ v.show ++ ")"
    EErr(v)          -> "Err(" ++ v.show ++ ")"

// ---------------------------------------------------------------------------
// Top-level declarations
// ---------------------------------------------------------------------------

pub struct fun-decl
  span        : span
  name        : string
  params      : list<string>
  body        : node
  param-anns  : list<maybe<hica-type>> = []  // user-written type annotations per param
  ret-ann     : maybe<hica-type> = Nothing   // user-written return type annotation
  param-types : list<hica-type> = []
  ret-type    : maybe<hica-type> = Nothing
  is-recursive : bool = False

pub fun fun-decl/show( d : fun-decl ) : div string
  "fun " ++ d.name ++ "(" ++ d.params.join(", ") ++ ") " ++ d.body.show

pub struct program
  decls : list<fun-decl>

pub fun program/show( p : program ) : div string
  p.decls.map(show).join("\n\n")

// ---------------------------------------------------------------------------
// Type environment
// ---------------------------------------------------------------------------

pub alias type-env = list<(string, hica-type)>

pub val empty-env : type-env = []
