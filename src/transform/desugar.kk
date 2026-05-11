/*
 * hica – desugaring pass
 *
 * Rewrites AST constructs that require expansion before codegen.
 * Runs after parsing and before type checking.
 *
 * Current desugars:
 *   PRange(lo, hi)   → PVar("hc__rng") + guard (hc__rng >= lo && hc__rng <= hi)
 *   PBits(mask, val) → PVar("hc__bits") + guard (hc__bits.and(mask) == val)
 * 
 * This source file is part of the hica open source project
 * Copyright (C) 2026 Claes Adamsson <claes.adamsson@gmail.com>
 *
 * See https://github.com/cladam/hica/blob/main/LICENSE for license information
 */
module transform/desugar

import syntax/ast

// ---------------------------------------------------------------------------
// Public entry point — desugar an entire program
// ---------------------------------------------------------------------------

pub fun desugar-program( p : program ) : div program
  p( decls = p.decls.map(desugar-decl),
     tests = p.tests.map(desugar-test) )

// ---------------------------------------------------------------------------
// Walk declarations
// ---------------------------------------------------------------------------

fun desugar-decl( d : fun-decl ) : div fun-decl
  d( body = desugar-node(d.body) )

fun desugar-test( t : test-decl ) : div test-decl
  t( body = desugar-node(t.body) )

// ---------------------------------------------------------------------------
// Walk AST nodes — only rewrite what we need, pass through the rest
// ---------------------------------------------------------------------------

fun desugar-node( n : node ) : div node
  val e2 = match n.expr
    Block(stmts) ->
      Block(stmts.map(desugar-node))
    Let(name, ty, init, body) ->
      Let(name, ty, desugar-node(init), desugar-node(body))
    VarDecl(name, ty, init, body) ->
      VarDecl(name, ty, desugar-node(init), desugar-node(body))
    Assign(name, rhs) ->
      Assign(name, desugar-node(rhs))
    If(cond, then-e, else-e) ->
      If(desugar-node(cond), desugar-node(then-e), desugar-node(else-e))
    Call(callee, args) ->
      Call(desugar-node(callee), args.map(desugar-node))
    Binary(op, l, r) ->
      Binary(op, desugar-node(l), desugar-node(r))
    Unary(op, e) ->
      Unary(op, desugar-node(e))
    Match(scrut, arms) ->
      Match(desugar-node(scrut), arms.map(desugar-arm))
    Fun(params, body) ->
      Fun(params, desugar-node(body))
    Repeat(count, body) ->
      Repeat(desugar-node(count), desugar-node(body))
    ForIn(name, lo, hi, body) ->
      ForIn(name, desugar-node(lo), desugar-node(hi), desugar-node(body))
    ForEach(name, coll, body) ->
      ForEach(name, desugar-node(coll), desugar-node(body))
    While(cond, body) ->
      While(desugar-node(cond), desugar-node(body))
    Loop(body) ->
      Loop(desugar-node(body))
    Tuple(elems) ->
      Tuple(elems.map(desugar-node))
    TupleIndex(tup, idx) ->
      TupleIndex(desugar-node(tup), idx)
    EList(elems) ->
      EList(elems.map(desugar-node))
    MapLit(entries) ->
      MapLit(entries.map(fn((k, v)) (desugar-node(k), desugar-node(v))))
    ListIndex(lst, idx) ->
      ListIndex(desugar-node(lst), desugar-node(idx))
    ListSlice(lst, s, e) ->
      ListSlice(desugar-node(lst), s.map(desugar-node), e.map(desugar-node))
    LetTuple(names, init, body) ->
      LetTuple(names, desugar-node(init), desugar-node(body))
    StructLit(sname, fields) ->
      StructLit(sname, fields.map(fn((f, v)) (f, desugar-node(v))))
    StructUpdate(sname, base, fields, defs) ->
      StructUpdate(sname, desugar-node(base), fields.map(fn((f, v)) (f, desugar-node(v))), defs)
    FieldAccess(obj, fname) ->
      FieldAccess(desugar-node(obj), fname)
    ESome(v) -> ESome(desugar-node(v))
    EOk(v)   -> EOk(desugar-node(v))
    EErr(v)  -> EErr(desugar-node(v))
    EConstructor(nm, args) -> EConstructor(nm, args.map(desugar-node))
    StringInterp(parts) -> StringInterp(parts.map(desugar-node))
    ETry(inner) -> ETry(desugar-node(inner))
    // Leaves — no sub-expressions
    _ -> n.expr
  n( expr = e2 )

// ---------------------------------------------------------------------------
// Desugar match arms: PRange and PBits become PVar + guard
// ---------------------------------------------------------------------------

fun desugar-arm( a : match-arm ) : div match-arm
  match a.pattern
    PRange(lo, hi) ->
      // hc__rng >= lo && hc__rng <= hi
      val rng-var = no-node(Var("hc__rng"))
      val lo-node = no-node(Literal(LitInt(lo)))
      val hi-node = no-node(Literal(LitInt(hi)))
      val ge = no-node(Binary(Ge, rng-var, lo-node))
      val le = no-node(Binary(Le, rng-var, hi-node))
      val range-guard = no-node(Binary(And, ge, le))
      val merged = merge-guard(range-guard, a.guard)
      Match-arm(PVar("hc__rng"), Just(merged), desugar-node(a.body))
    PBits(msk, vl) ->
      // bit_and(hc__bits, mask) == val
      val bits-var = no-node(Var("hc__bits"))
      val mask-node = no-node(Literal(LitInt(msk)))
      val val-node  = no-node(Literal(LitInt(vl)))
      val and-call = no-node(Call(no-node(Var("bit_and")), [bits-var, mask-node]))
      val bits-guard = no-node(Binary(Eq, and-call, val-node))
      val merged = merge-guard(bits-guard, a.guard)
      Match-arm(PVar("hc__bits"), Just(merged), desugar-node(a.body))
    _ ->
      a( guard = a.guard.map(desugar-node), body = desugar-node(a.body) )

// Merge a synthetic guard with an optional user guard using &&
fun merge-guard( synth : node, user : maybe<node> ) : div node
  match user
    Nothing -> synth
    Just(g) -> no-node(Binary(And, synth, desugar-node(g)))

// Helper: node with no span info
fun no-node( e : expr ) : node
  Node(no-span, e)
