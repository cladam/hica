/*
 * hica – type and effect inference
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
module semantics/checker

import syntax/ast
import diagnostics/diagnostics

// ---------------------------------------------------------------------------
// Fresh type variable generation
// ---------------------------------------------------------------------------

pub effect fresh
  fun fresh-tvar() : hica-type

pub fun run-fresh( action : () -> <fresh|e> a ) : e a
  var counter := 0
  with handler
    fun fresh-tvar()
      val n = counter
      counter := counter + 1
      TVar("t" ++ n.show)
  action()

// ---------------------------------------------------------------------------
// Substitution: mapping from type-variable names to concrete types
// ---------------------------------------------------------------------------

pub alias subst = list<(string, hica-type)>

pub val empty-subst : subst = []

// Find a type in a substitution by variable name.
fun subst-find( s : subst, name : string ) : maybe<hica-type>
  match s
    Nil -> Nothing
    Cons((k, v), rest) -> if k == name then Just(v) else subst-find(rest, name)

// Apply a substitution to a type, replacing any TVar that appears in the map.
pub fun apply-subst( s : subst, t : hica-type ) : div hica-type
  match t
    TVar(name) ->
      match subst-find(s, name)
        Just(replacement) -> apply-subst(s, replacement)
        Nothing           -> t
    TFun(params, result) ->
      TFun(params.map(fn(p) apply-subst(s, p)), apply-subst(s, result))
    _ -> t

// Check if a name is bound in a substitution.
fun subst-has( s : subst, name : string ) : bool
  match s
    Nil -> False
    Cons((k, _), rest) -> if k == name then True else subst-has(rest, name)

// Compose two substitutions: applying (compose s1 s2) is the same as
// first applying s2, then applying s1.
pub fun compose-subst( s1 : subst, s2 : subst ) : div subst
  val updated-s2 = s2.map-subst(fn(k, v) (k, apply-subst(s1, v)))
  s1 ++ updated-s2.filter-subst(fn(k, _v) !subst-has(s1, k))

// Map over a substitution, applying f to each (key, value) pair.
fun map-subst( s : subst, f : (string, hica-type) -> div (string, hica-type) ) : div subst
  match s
    Nil -> Nil
    Cons((k, v), rest) -> Cons(f(k, v), rest.map-subst(f))

// Filter a substitution, keeping entries where the predicate holds.
fun filter-subst( s : subst, pred : (string, hica-type) -> bool ) : subst
  match s
    Nil -> Nil
    Cons((k, v), rest) ->
      if pred(k, v) then Cons((k, v), rest.filter-subst(pred))
      else rest.filter-subst(pred)

// ---------------------------------------------------------------------------
// Occurs check: prevent infinite types like t0 = int -> t0
// ---------------------------------------------------------------------------

fun occurs-in( name : string, t : hica-type ) : div bool
  match t
    TVar(n)          -> n == name
    TFun(params, r)  -> params.any(fn(p) occurs-in(name, p)) || occurs-in(name, r)
    _                -> False

// ---------------------------------------------------------------------------
// Unification
// ---------------------------------------------------------------------------

pub fun unify( t1 : hica-type, t2 : hica-type, sp : span ) : <div,diag> subst
  match (t1, t2)
    (TVar(a), _) ->
      if t2 == TVar(a) then empty-subst
      elif occurs-in(a, t2) then
        emit-error(sp, "infinite type: " ++ a ++ " occurs in " ++ t2.show)
        empty-subst
      else [(a, t2)]
    (_, TVar(b)) ->
      unify(TVar(b), t1, sp)
    (TInt, TInt)       -> empty-subst
    (TBool, TBool)     -> empty-subst
    (TString, TString) -> empty-subst
    (TUnit, TUnit)     -> empty-subst
    (TFun(ps1, r1), TFun(ps2, r2)) ->
      if ps1.length != ps2.length then
        emit-error(sp, "function arity mismatch: expected " ++ ps1.length.show ++ " params, got " ++ ps2.length.show)
        empty-subst
      else
        val param-subst = unify-lists(ps1, ps2, sp)
        val r1' = apply-subst(param-subst, r1)
        val r2' = apply-subst(param-subst, r2)
        val ret-subst = unify(r1', r2', sp)
        compose-subst(ret-subst, param-subst)
    _ ->
      emit-error(sp, "type mismatch: expected " ++ t1.show ++ ", got " ++ t2.show)
      empty-subst

fun unify-lists( ts1 : list<hica-type>, ts2 : list<hica-type>, sp : span ) : <div,diag> subst
  match (ts1, ts2)
    (Cons(a, as'), Cons(b, bs')) ->
      val s = unify(a, b, sp)
      val rest-s = unify-lists(as'.map(fn(t) apply-subst(s, t)), bs'.map(fn(t) apply-subst(s, t)), sp)
      compose-subst(rest-s, s)
    _ -> empty-subst

// ---------------------------------------------------------------------------
// Type environment
// ---------------------------------------------------------------------------

pub alias type-env = list<(string, hica-type)>

pub val empty-env : type-env = []

// Find a type in the environment by name.
fun env-find( env : type-env, name : string ) : maybe<hica-type>
  match env
    Nil -> Nothing
    Cons((k, v), rest) -> if k == name then Just(v) else env-find(rest, name)

pub fun env/lookup( env : type-env, name : string, sp : span ) : <diag,fresh> hica-type
  match env-find(env, name)
    Just(t)  -> t
    Nothing  ->
      emit-error(sp, "undefined variable: " ++ name)
      fresh-tvar()

pub fun env/extend( env : type-env, name : string, t : hica-type ) : type-env
  Cons((name, t), env)

// ---------------------------------------------------------------------------
// Type inference
// ---------------------------------------------------------------------------

// Infer the type of a node, returning the updated substitution and a
// node annotated with its inferred type.
pub fun infer( env : type-env, s : subst, n : node ) : <div,diag,fresh> (subst, node)
  match n.expr
    // --- Literals: known concrete types ---
    Literal(LitInt(_)) ->
      (s, n(typ = Just(TInt)))
    Literal(LitBool(_)) ->
      (s, n(typ = Just(TBool)))
    Literal(LitString(_)) ->
      (s, n(typ = Just(TString)))

    // --- Variables: look up in environment ---
    Var(name) ->
      val t = env.lookup(name, n.span)
      val resolved = apply-subst(s, t)
      (s, n(typ = Just(resolved)))

    // --- Let bindings: infer init, extend env, infer body ---
    Let(name, ann, init, body) ->
      val (s1, init') = infer(env, s, init)
      val init-type = get-type(init')
      // If there's a type annotation, unify with inferred type
      val s2 = match ann
        Just(declared) -> compose-subst(unify(init-type, declared, init.span), s1)
        Nothing        -> s1
      val bound-type = apply-subst(s2, init-type)
      val env' = env.extend(name, bound-type)
      val (s3, body') = infer(env', s2, body)
      val body-type = get-type(body')
      (s3, Node(n.span, Let(name, ann, init', body'), Just(body-type)))

    // --- Blocks: infer each statement, type is the last ---
    Block(stmts) ->
      val (s', stmts', last-type) = infer-stmts(env, s, stmts)
      (s', Node(n.span, Block(stmts'), Just(last-type)))

    // --- Not yet handled: assign a fresh type variable ---
    _ ->
      val t = fresh-tvar()
      (s, n(typ = Just(t)))

// Infer types for a list of statements (inside a block).
// Returns the updated substitution, typed statements, and the type of
// the last statement.
fun infer-stmts( env : type-env, s : subst, stmts : list<node> ) : <div,diag,fresh> (subst, list<node>, hica-type)
  match stmts
    Nil -> (s, [], TUnit)
    Cons(stmt, Nil) ->
      val (s', stmt') = infer(env, s, stmt)
      (s', [stmt'], get-type(stmt'))
    Cons(stmt, rest) ->
      val (s1, stmt') = infer(env, s, stmt)
      // If this stmt is a let binding, extend env for subsequent stmts
      val env' = match stmt'.expr
        Let(name, _, _, _) -> env.extend(name, get-type(stmt'))
        _                  -> env
      val (s2, rest', last-type) = infer-stmts(env', s1, rest)
      (s2, Cons(stmt', rest'), last-type)

// Extract the inferred type from a node, defaulting to TUnit.
fun get-type( n : node ) : hica-type
  match n.typ
    Just(t)  -> t
    Nothing  -> TUnit

// ---------------------------------------------------------------------------
// Top-level: check a full program
// ---------------------------------------------------------------------------

// Infer a top-level function declaration.
fun infer-decl( env : type-env, s : subst, d : fun-decl ) : <div,diag,fresh> (subst, type-env, fun-decl)
  // Assign fresh type variables to each parameter
  val param-types = d.params.map(fn(_p) fresh-tvar())
  // Extend environment with params
  val param-env = zip(d.params, param-types).foldl(env, fn(e, entry) match entry { (n, t) -> e.extend(n, t) })
  // Infer the body
  val (s1, body') = infer(param-env, s, d.body)
  val body-type = get-type(body')
  // Build the function type
  val resolved-params = param-types.map(fn(t) apply-subst(s1, t))
  val fun-type = TFun(resolved-params, apply-subst(s1, body-type))
  // Extend the outer environment with this function's name
  val env' = env.extend(d.name, fun-type)
  val d' = d(body = body')
  (s1, env', d')

// Check an entire program: infer all declarations in order.
pub fun check-program( p : program ) : <div,diag,fresh> program
  val (_, _, decls') = infer-decls(empty-env, empty-subst, p.decls)
  Program(decls')

fun infer-decls( env : type-env, s : subst, ds : list<fun-decl> ) : <div,diag,fresh> (subst, type-env, list<fun-decl>)
  match ds
    Nil -> (s, env, [])
    Cons(d, rest) ->
      val (s1, env1, d') = infer-decl(env, s, d)
      val (s2, env2, rest') = infer-decls(env1, s1, rest)
      (s2, env2, Cons(d', rest'))

// Convenience: check a single node (legacy API, still used by some tests).
pub fun check( n : node ) : node
  n
