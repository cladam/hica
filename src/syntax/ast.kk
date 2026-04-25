// Hica — Abstract Syntax Tree
// Inspired by Lisette's ast.rs, adapted for Koka's algebraic data types.
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

pub fun node/show( n : node ) : div string
  n.expr.show

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

pub type hica-type
  TInt
  TBool
  TString
  TUnit
  TFun( params : list<hica-type>, result : hica-type )
  TVar( name : string )

pub fun hica-type/show( t : hica-type ) : div string
  match t
    TInt        -> "int"
    TBool       -> "bool"
    TString     -> "string"
    TUnit       -> "()"
    TFun(ps, r) -> "(" ++ ps.map(show).join(", ") ++ ") -> " ++ r.show
    TVar(n)     -> n

// ---------------------------------------------------------------------------
// Expressions
// ---------------------------------------------------------------------------

pub type literal
  LitInt( i : int )
  LitBool( b : bool )
  LitString( s : string )

pub fun literal/show( l : literal ) : string
  match l
    LitInt(i)    -> i.show
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
