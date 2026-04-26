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
// Stub: pass-through checker (to be replaced in Phase 1+)
// ---------------------------------------------------------------------------

pub fun check( n : node ) : node
  n  // pass-through for now
