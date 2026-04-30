/*
 * hica – AST tree-walking transformation
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
    Repeat(count, body) ->
      Repeat(walk(count, f), walk(body, f))
    ForIn(name, start-e, end-e, body) ->
      ForIn(name, walk(start-e, f), walk(end-e, f), walk(body, f))
    StringInterp(parts) ->
      StringInterp(parts.map(fn(p) walk(p, f)))
    Tuple(elems) ->
      Tuple(elems.map(fn(e) walk(e, f)))
    EList(elems) ->
      EList(elems.map(fn(e) walk(e, f)))
    ListIndex(lst, idx) ->
      ListIndex(walk(lst, f), walk(idx, f))
    ListSlice(lst, s, e) ->
      ListSlice(walk(lst, f), s.map(fn(n) walk(n, f)), e.map(fn(n) walk(n, f)))
    TupleIndex(tup, idx) ->
      TupleIndex(walk(tup, f), idx)
    LetTuple(names, init, body) ->
      LetTuple(names, walk(init, f), walk(body, f))
    other -> other
  Node(n.span, f(walked))
