// Hica — AST Folder
// Generic tree-walking transformation, inspired by Lisette's ast_folder.rs.
// In Koka we use first-class functions instead of traits.
module syntax/fold

import syntax/ast

pub alias transform = (expr) -> expr

// Walk an AST node, applying `f` bottom-up to each expression.
pub fun walk( n : node, f : transform ) : node
  val walked = match n.expr
    Let(name, t, init, body) ->
      Let(name, t, walk(init, f), walk(body, f))
    Fun(params, body) ->
      Fun(params, walk(body, f))
    Call(callee, args) ->
      Call(walk(callee, f), args.map(fn(a) walk(a, f)))
    Binary(op, lhs, rhs) ->
      Binary(op, walk(lhs, f), walk(rhs, f))
    Unary(op, operand) ->
      Unary(op, walk(operand, f))
    If(cond, then-e, else-e) ->
      If(walk(cond, f), walk(then-e, f), walk(else-e, f))
    Block(stmts) ->
      Block(stmts.map(fn(s) walk(s, f)))
    Match(scrut, arms) ->
      Match(walk(scrut, f), arms.map(fn(a) Match-arm(a.pattern, walk(a.body, f))))
    other -> other
  Node(n.span, f(walked))
