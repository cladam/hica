/*
 * hica – type and effect inference
 * 
 * This source file is part of the hica open source project
 * Copyright (C) 2026 Claes Adamsson <claes.adamsson@gmail.com>
 *
 * See https://github.com/cladam/hica/blob/main/LICENSE for license information
*/
module semantics/checker

import syntax/ast
import diagnostics/diagnostics
import semantics/prelude

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
    TTuple(elems) ->
      TTuple(elems.map(fn(e) apply-subst(s, e)))
    TList(elem) ->
      TList(apply-subst(s, elem))
    TMaybe(elem) ->
      TMaybe(apply-subst(s, elem))
    TResult(ok, err) ->
      TResult(apply-subst(s, ok), apply-subst(s, err))
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
    TTuple(elems)    -> elems.any(fn(e) occurs-in(name, e))
    TList(elem)      -> occurs-in(name, elem)
    TMaybe(elem)     -> occurs-in(name, elem)
    TResult(ok, err) -> occurs-in(name, ok) || occurs-in(name, err)
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
    (TFloat, TFloat)   -> empty-subst
    (TBool, TBool)     -> empty-subst
    (TString, TString) -> empty-subst
    (TChar, TChar)     -> empty-subst
    (TUnit, TUnit)     -> empty-subst
    (TTuple(es1), TTuple(es2)) ->
      if es1.length != es2.length then
        emit-error(sp, "tuple size mismatch: expected " ++ es1.length.show ++ " elements, got " ++ es2.length.show)
        empty-subst
      else unify-lists(es1, es2, sp)
    (TList(e1), TList(e2)) ->
      unify(e1, e2, sp)
    (TMaybe(e1), TMaybe(e2)) ->
      unify(e1, e2, sp)
    (TResult(o1, e1), TResult(o2, e2)) ->
      val s1 = unify(o1, o2, sp)
      val s2 = unify(apply-subst(s1, e1), apply-subst(s1, e2), sp)
      compose-subst(s2, s1)
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

// Find a type in the environment by name.
fun env-find( env : type-env, name : string ) : maybe<hica-type>
  match env
    Nil -> Nothing
    Cons((k, v), rest) -> if k == name then Just(v) else env-find(rest, name)

pub fun env/lookup( env : type-env, name : string, sp : span ) : <div,diag,fresh> hica-type
  match env-find(env, name)
    Just(t)  -> freshen(t)
    Nothing  ->
      emit-error(sp, "undefined variable: " ++ name)
      fresh-tvar()

pub fun env/extend( env : type-env, name : string, t : hica-type ) : type-env
  Cons((name, t), env)

// ---------------------------------------------------------------------------
// Freshening: replace TVars with fresh ones (minimal let-polymorphism)
// ---------------------------------------------------------------------------

// Collect all TVar names in a type that start with "_" (extern TVars).
fun collect-tvars( t : hica-type ) : div list<string>
  match t
    TVar(n)          -> if n.head-char.default(' ') == '_' then [n] else []
    TFun(params, r)  -> params.flatmap(fn(p) collect-tvars(p)) ++ collect-tvars(r)
    TTuple(elems)    -> elems.flatmap(fn(e) collect-tvars(e))
    TList(elem)      -> collect-tvars(elem)
    TMaybe(elem)     -> collect-tvars(elem)
    TResult(ok, err) -> collect-tvars(ok) ++ collect-tvars(err)
    _                -> []

// Replace TVars according to a mapping.
fun apply-rename( mapping : list<(string, hica-type)>, t : hica-type ) : div hica-type
  match t
    TVar(n) ->
      match mapping.find-mapping(n)
        Just(replacement) -> replacement
        Nothing           -> t
    TFun(params, r) -> TFun(params.map(fn(p) apply-rename(mapping, p)), apply-rename(mapping, r))
    TTuple(elems)   -> TTuple(elems.map(fn(e) apply-rename(mapping, e)))
    TList(elem)     -> TList(apply-rename(mapping, elem))
    TMaybe(elem)    -> TMaybe(apply-rename(mapping, elem))
    TResult(ok, err) -> TResult(apply-rename(mapping, ok), apply-rename(mapping, err))
    _               -> t

fun find-mapping( mapping : list<(string, hica-type)>, name : string ) : maybe<hica-type>
  match mapping
    Nil -> Nothing
    Cons((k, v), rest) -> if k == name then Just(v) else find-mapping(rest, name)

// Freshen a type: replace all TVars with fresh ones.
// This is a no-op for types without TVars (e.g. user-declared functions).
fun freshen( t : hica-type ) : <div,fresh> hica-type
  val tvars = collect-tvars(t)
  match tvars
    Nil -> t
    _   ->
      val unique = tvars.foldl([], fn(acc : list<string>, v) if acc.any(fn(a) a == v) then acc else Cons(v, acc))
      val mapping = unique.map(fn(v) (v, fresh-tvar()))
      apply-rename(mapping, t)

// Zip parameter names with their optional annotations.
// Uses the annotation when present, otherwise a fresh type variable.
fun zip-with-anns( params : list<string>, anns : list<maybe<hica-type>> ) : <div,fresh> list<hica-type>
  match (params, anns)
    (Cons(_, ps), Cons(Just(t), as')) -> Cons(t, zip-with-anns(ps, as'))
    (Cons(_, ps), Cons(Nothing, as')) -> Cons(fresh-tvar(), zip-with-anns(ps, as'))
    (Cons(_, ps), Nil)                -> Cons(fresh-tvar(), zip-with-anns(ps, []))
    _                                 -> []

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
    Literal(LitFloat(_)) ->
      (s, n(typ = Just(TFloat)))
    Literal(LitBool(_)) ->
      (s, n(typ = Just(TBool)))
    Literal(LitString(_)) ->
      (s, n(typ = Just(TString)))
    Literal(LitChar(_)) ->
      (s, n(typ = Just(TChar)))

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

    // --- Lambda / anonymous functions ---
    Fun(params, body) ->
      // Assign a fresh type variable to each parameter
      val param-types = params.map(fn(_p) fresh-tvar())
      // Extend environment with params
      val fun-env = zip(params, param-types).foldl(env, fn(e, entry) match entry { (nm, t) -> e.extend(nm, t) })
      // Infer the body
      val (s1, body') = infer(fun-env, s, body)
      val resolved-params = param-types.map(fn(t) apply-subst(s1, t))
      val ret-type = apply-subst(s1, get-type(body'))
      val fun-type = TFun(resolved-params, ret-type)
      (s1, Node(n.span, Fun(params, body'), Just(fun-type)))

    // --- Function calls ---
    Call(callee, args) ->
      // Infer the callee
      val (s1, callee') = infer(env, s, callee)
      // Infer each argument
      val (s2, args') = infer-args(env, s1, args)
      val callee-type = apply-subst(s2, get-type(callee'))
      // Build the expected function type: (arg-types) -> fresh-ret
      val arg-types = args'.map(fn(a) apply-subst(s2, get-type(a)))
      val ret-var = fresh-tvar()
      val expected = TFun(arg-types, ret-var)
      // Unify callee's type with the expected function type
      val s3 = compose-subst(unify(callee-type, expected, n.span), s2)
      val result-type = apply-subst(s3, ret-var)
      (s3, Node(n.span, Call(callee', args'), Just(result-type)))

    // --- Binary operators ---
    Binary(op, lhs, rhs) ->
      val (s1, lhs') = infer(env, s, lhs)
      val (s2, rhs') = infer(env, s1, rhs)
      val lt = apply-subst(s2, get-type(lhs'))
      val rt = apply-subst(s2, get-type(rhs'))
      val (s3, result-type) = match op
        Add ->
          // + works on int, float, string, or lists: unify operands, then check resolved type
          val s-lr = compose-subst(unify(lt, rt, n.span), s2)
          val resolved = apply-subst(s-lr, lt)
          match resolved
            TInt    -> (s-lr, TInt)
            TFloat  -> (s-lr, TFloat)
            TString -> (s-lr, TString)
            TList(_) -> (s-lr, resolved)
            TVar(_) ->
              // Ambiguous — default to int
              (compose-subst(unify(resolved, TInt, n.span), s-lr), TInt)
            _ ->
              emit-error(n.span, "operator + requires int, float, string, or list operands, got " ++ resolved.show)
              (s-lr, TInt)
        Sub -> infer-numeric-op(lt, rt, lhs, rhs, n, s2)
        Mul -> infer-numeric-op(lt, rt, lhs, rhs, n, s2)
        Div -> infer-numeric-op(lt, rt, lhs, rhs, n, s2)
        Mod -> infer-numeric-op(lt, rt, lhs, rhs, n, s2)
        Eq  -> (compose-subst(unify(lt, rt, n.span), s2), TBool)
        Neq -> (compose-subst(unify(lt, rt, n.span), s2), TBool)
        Lt  -> infer-comparison-op(lt, rt, lhs, rhs, n, s2)
        Gt  -> infer-comparison-op(lt, rt, lhs, rhs, n, s2)
        Le  -> infer-comparison-op(lt, rt, lhs, rhs, n, s2)
        Ge  -> infer-comparison-op(lt, rt, lhs, rhs, n, s2)
        And -> (compose-subst(unify(rt, TBool, rhs.span), compose-subst(unify(lt, TBool, lhs.span), s2)), TBool)
        Or  -> (compose-subst(unify(rt, TBool, rhs.span), compose-subst(unify(lt, TBool, lhs.span), s2)), TBool)
        In  ->
          // x in list: rhs must be TList(elem), lhs must match elem
          val elem-var = fresh-tvar()
          val s-list = compose-subst(unify(rt, TList(elem-var), rhs.span), s2)
          val resolved-elem = apply-subst(s-list, elem-var)
          val s-elem = compose-subst(unify(lt, resolved-elem, lhs.span), s-list)
          (s-elem, TBool)
      (s3, Node(n.span, Binary(op, lhs', rhs'), Just(result-type)))

    // --- Unary operators ---
    Unary(op, operand) ->
      val (s1, operand') = infer(env, s, operand)
      val ot = apply-subst(s1, get-type(operand'))
      val (s2, result-type) = match op
        Neg ->
          val s-u = compose-subst(unify(ot, ot, operand.span), s1)
          val resolved = apply-subst(s-u, ot)
          match resolved
            TInt    -> (s-u, TInt)
            TFloat  -> (s-u, TFloat)
            TVar(_) -> (compose-subst(unify(resolved, TInt, operand.span), s-u), TInt)
            _       ->
              emit-error(operand.span, "operator - requires int or float operand, got " ++ resolved.show)
              (s-u, TInt)
        Not -> (compose-subst(unify(ot, TBool, operand.span), s1), TBool)
      (s2, Node(n.span, Unary(op, operand'), Just(result-type)))

    // --- If expressions ---
    If(cond, then-e, else-e) ->
      // Condition must be bool
      val (s1, cond') = infer(env, s, cond)
      val cond-type = apply-subst(s1, get-type(cond'))
      val s2 = compose-subst(unify(cond-type, TBool, cond.span), s1)
      // Infer both branches
      val (s3, then') = infer(env, s2, then-e)
      val (s4, else') = infer(env, s3, else-e)
      val then-type = apply-subst(s4, get-type(then'))
      val else-type = apply-subst(s4, get-type(else'))
      // Unify branches — they must return the same type
      val s5 = compose-subst(unify(then-type, else-type, n.span), s4)
      val result-type = apply-subst(s5, then-type)
      (s5, Node(n.span, If(cond', then', else'), Just(result-type)))

    // --- Match expressions ---
    Match(scrut, arms) ->
      val (s1, scrut') = infer(env, s, scrut)
      val scrut-type = apply-subst(s1, get-type(scrut'))
      val result-var = fresh-tvar()
      val (s2, arms') = infer-arms(env, s1, scrut-type, result-var, arms)
      val result-type = apply-subst(s2, result-var)
      (s2, Node(n.span, Match(scrut', arms'), Just(result-type)))

    // --- Repeat expressions ---
    Repeat(count, body) ->
      val (s1, count') = infer(env, s, count)
      val count-type = apply-subst(s1, get-type(count'))
      val s2 = compose-subst(unify(count-type, TInt, count.span), s1)
      val (s3, body') = infer(env, s2, body)
      (s3, Node(n.span, Repeat(count', body'), Just(TUnit)))

    // --- For-in expressions ---
    ForIn(name, start-e, end-e, body) ->
      val (s1, start') = infer(env, s, start-e)
      val start-type = apply-subst(s1, get-type(start'))
      val s2 = compose-subst(unify(start-type, TInt, start-e.span), s1)
      val (s3, end') = infer(env, s2, end-e)
      val end-type = apply-subst(s3, get-type(end'))
      val s4 = compose-subst(unify(end-type, TInt, end-e.span), s3)
      val env' = env.extend(name, TInt)
      val (s5, body') = infer(env', s4, body)
      (s5, Node(n.span, ForIn(name, start', end', body'), Just(TUnit)))

    // --- For-each over collections ---
    ForEach(name, coll, body) ->
      val (s1, coll') = infer(env, s, coll)
      val coll-type = apply-subst(s1, get-type(coll'))
      val elem-type = fresh-tvar()
      val s2 = compose-subst(unify(coll-type, TList(elem-type), coll.span), s1)
      val resolved-elem = apply-subst(s2, elem-type)
      val env' = env.extend(name, resolved-elem)
      val (s3, body') = infer(env', s2, body)
      (s3, Node(n.span, ForEach(name, coll', body'), Just(TUnit)))

    // --- String interpolation ---
    StringInterp(parts) ->
      val (s1, parts') = infer-interp-parts(env, s, parts)
      (s1, Node(n.span, StringInterp(parts'), Just(TString)))

    // --- Tuples ---
    Tuple(elems) ->
      if elems.length > 5 then
        emit-error(n.span, "tuples can have at most 5 elements, got " ++ elems.length.show)
      val (s1, elems') = infer-args(env, s, elems)
      val elem-types = elems'.map(fn(e) apply-subst(s1, get-type(e)))
      (s1, Node(n.span, Tuple(elems'), Just(TTuple(elem-types))))

    // --- Lists ---
    EList(elems) ->
      match elems
        Nil ->
          val elem-var = fresh-tvar()
          (s, Node(n.span, EList([]), Just(TList(elem-var))))
        Cons(_, _) ->
          val (s1, elems') = infer-args(env, s, elems)
          val elem-types = elems'.map(fn(e) apply-subst(s1, get-type(e)))
          // Unify all element types with the first
          val first-type = elem-types.head.default(TUnit)
          val s2 = elem-types.tail.foldl(s1, fn(acc, et) compose-subst(unify(apply-subst(acc, first-type), apply-subst(acc, et), n.span), acc))
          (s2, Node(n.span, EList(elems'), Just(TList(apply-subst(s2, first-type)))))

    TupleIndex(tup, idx) ->
      val (s1, tup') = infer(env, s, tup)
      val tup-type = apply-subst(s1, get-type(tup'))
      match tup-type
        TTuple(elems) ->
          if idx >= 0 && idx < elems.length then
            val elem-type = elems[idx].default(TUnit)
            (s1, Node(n.span, TupleIndex(tup', idx), Just(elem-type)))
          else
            emit-error(n.span, "tuple index " ++ idx.show ++ " out of range for " ++ tup-type.show)
            (s1, Node(n.span, TupleIndex(tup', idx), Just(fresh-tvar())))
        TVar(_) ->
          // Type not yet known — return a fresh var
          val result-var = fresh-tvar()
          (s1, Node(n.span, TupleIndex(tup', idx), Just(result-var)))
        _ ->
          emit-error(n.span, "cannot index non-tuple type " ++ tup-type.show)
          (s1, Node(n.span, TupleIndex(tup', idx), Just(fresh-tvar())))

    LetTuple(names, init, body) ->
      val (s1, init') = infer(env, s, init)
      val init-type = apply-subst(s1, get-type(init'))
      // Unify with a tuple of fresh vars
      val name-vars = names.map(fn(_n) fresh-tvar())
      val expected = TTuple(name-vars)
      val s2 = compose-subst(unify(init-type, expected, init.span), s1)
      val bound-types = name-vars.map(fn(v) apply-subst(s2, v))
      val env' = zip(names, bound-types).foldl(env, fn(e, entry) match entry { (nm, t) -> e.extend(nm, t) })
      val (s3, body') = infer(env', s2, body)
      val body-type = get-type(body')
      (s3, Node(n.span, LetTuple(names, init', body'), Just(body-type)))

    // --- List indexing ---
    ListIndex(lst, idx) ->
      val (s1, lst') = infer(env, s, lst)
      val (s2, idx') = infer(env, s1, idx)
      val elem-var = fresh-tvar()
      val s3 = compose-subst(unify(apply-subst(s2, get-type(lst')), TList(elem-var), n.span), s2)
      val s4 = compose-subst(unify(apply-subst(s3, get-type(idx')), TInt, n.span), s3)
      (s4, Node(n.span, ListIndex(lst', idx'), Just(apply-subst(s4, elem-var))))

    // --- List slicing ---
    ListSlice(lst, start-m, end-m) ->
      val (s1, lst') = infer(env, s, lst)
      val elem-var = fresh-tvar()
      val s2 = compose-subst(unify(apply-subst(s1, get-type(lst')), TList(elem-var), n.span), s1)
      val (s3, start-m') = match start-m
        Just(se) ->
          val (si, se') = infer(env, s2, se)
          val si2 = compose-subst(unify(apply-subst(si, get-type(se')), TInt, n.span), si)
          (si2, Just(se'))
        Nothing -> (s2, Nothing)
      val (s4, end-m') = match end-m
        Just(ee) ->
          val (si, ee') = infer(env, s3, ee)
          val si2 = compose-subst(unify(apply-subst(si, get-type(ee')), TInt, n.span), si)
          (si2, Just(ee'))
        Nothing -> (s3, Nothing)
      (s4, Node(n.span, ListSlice(lst', start-m', end-m'), Just(TList(apply-subst(s4, elem-var)))))

    // --- Maybe constructors ---
    ESome(value) ->
      val (s1, value') = infer(env, s, value)
      val val-type = apply-subst(s1, get-type(value'))
      (s1, Node(n.span, ESome(value'), Just(TMaybe(val-type))))

    ENone ->
      val elem-var = fresh-tvar()
      (s, Node(n.span, ENone, Just(TMaybe(elem-var))))

    // --- Result constructors ---
    EOk(value) ->
      val (s1, value') = infer(env, s, value)
      val val-type = apply-subst(s1, get-type(value'))
      val err-var = fresh-tvar()
      (s1, Node(n.span, EOk(value'), Just(TResult(val-type, err-var))))

    EErr(value) ->
      val (s1, value') = infer(env, s, value)
      val val-type = apply-subst(s1, get-type(value'))
      val ok-var = fresh-tvar()
      (s1, Node(n.span, EErr(value'), Just(TResult(ok-var, val-type))))

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
      // If this stmt is a let (chain), extend env for subsequent stmts
      val env' = extend-let-chain(env, s1, stmt')
      val (s2, rest', last-type) = infer-stmts(env', s1, rest)
      (s2, Cons(stmt', rest'), last-type)

// Recursively extract all let bindings from a let chain (let a = ...; let b = ...; body)
// and extend the environment with each one.
fun extend-let-chain( env : type-env, s : subst, n : node ) : div type-env
  match n.expr
    Let(name, _, init', body) ->
      val env' = env.extend(name, apply-subst(s, get-type(init')))
      extend-let-chain(env', s, body)
    LetTuple(names, init', body) ->
      val env' = match apply-subst(s, get-type(init'))
        TTuple(ts) -> zip(names, ts).foldl(env, fn(e, entry) match entry { (nm, t) -> e.extend(nm, t) })
        _ -> env
      extend-let-chain(env', s, body)
    _ -> env

// Infer types for a list of call arguments.
fun infer-args( env : type-env, s : subst, args : list<node> ) : <div,diag,fresh> (subst, list<node>)
  match args
    Nil -> (s, [])
    Cons(arg, rest) ->
      val (s1, arg') = infer(env, s, arg)
      val (s2, rest') = infer-args(env, s1, rest)
      (s2, Cons(arg', rest'))

// Infer types for string interpolation parts.
// Each part is inferred independently — string segments stay TString,
// expression parts can be any type (they get .show in codegen).
fun infer-interp-parts( env : type-env, s : subst, parts : list<node> ) : <div,diag,fresh> (subst, list<node>)
  match parts
    Nil -> (s, [])
    Cons(part, rest) ->
      val (s1, part') = infer(env, s, part)
      val (s2, rest') = infer-interp-parts(env, s1, rest)
      (s2, Cons(part', rest'))

// Infer types for match arms.
// Each arm's pattern constrains the scrutinee type, and each arm's body
// must unify with the result type variable.
fun infer-arms( env : type-env, s : subst, scrut-type : hica-type, result-var : hica-type, arms : list<match-arm> ) : <div,diag,fresh> (subst, list<match-arm>)
  match arms
    Nil -> (s, [])
    Cons(arm, rest) ->
      // Constrain scrutinee type from pattern
      val (s1, pat-env) = infer-pattern(env, s, scrut-type, arm.pattern)
      // Infer arm body in extended environment
      val (s2, body') = infer(pat-env, s1, arm.body)
      val body-type = apply-subst(s2, get-type(body'))
      // Unify with result type so all arms agree
      val s3 = compose-subst(unify(body-type, apply-subst(s2, result-var), arm.body.span), s2)
      val (s4, rest') = infer-arms(env, s3, scrut-type, result-var, rest)
      (s4, Cons(Match-arm(arm.pattern, body'), rest'))

// Infer a numeric binary operator (-, *, /): works on int or float.
fun infer-numeric-op( lt : hica-type, rt : hica-type, lhs : node, rhs : node, n : node, s : subst ) : <div,diag,fresh> (subst, hica-type)
  val s-lr = compose-subst(unify(lt, rt, n.span), s)
  val resolved = apply-subst(s-lr, lt)
  match resolved
    TInt    -> (s-lr, TInt)
    TFloat  -> (s-lr, TFloat)
    TVar(_) -> (compose-subst(unify(resolved, TInt, n.span), s-lr), TInt)
    _       ->
      emit-error(n.span, "arithmetic operator requires int or float operands, got " ++ resolved.show)
      (s-lr, TInt)

// Infer a comparison operator (<, >, <=, >=): works on int or float, returns bool.
fun infer-comparison-op( lt : hica-type, rt : hica-type, lhs : node, rhs : node, n : node, s : subst ) : <div,diag,fresh> (subst, hica-type)
  val s-lr = compose-subst(unify(lt, rt, n.span), s)
  val resolved = apply-subst(s-lr, lt)
  match resolved
    TInt    -> (s-lr, TBool)
    TFloat  -> (s-lr, TBool)
    TVar(_) -> (compose-subst(unify(resolved, TInt, n.span), s-lr), TBool)
    _       ->
      emit-error(n.span, "comparison operator requires int or float operands, got " ++ resolved.show)
      (s-lr, TBool)

// Infer type constraints from a match pattern.
// Returns the updated substitution and the environment extended with
// any pattern-bound variables.
fun infer-pattern( env : type-env, s : subst, scrut-type : hica-type, p : pattern ) : <div,diag,fresh> (subst, type-env)
  match p
    PWild    -> (s, env)
    PVar(name) -> (s, env.extend(name, scrut-type))
    PLit(LitInt(_))    -> (compose-subst(unify(scrut-type, TInt, no-span), s), env)
    PLit(LitFloat(_))  -> (compose-subst(unify(scrut-type, TFloat, no-span), s), env)
    PLit(LitBool(_))   -> (compose-subst(unify(scrut-type, TBool, no-span), s), env)
    PLit(LitString(_)) -> (compose-subst(unify(scrut-type, TString, no-span), s), env)
    PLit(LitChar(_))   -> (compose-subst(unify(scrut-type, TChar, no-span), s), env)
    PSome(inner) ->
      val elem-var = fresh-tvar()
      val s1 = compose-subst(unify(scrut-type, TMaybe(elem-var), no-span), s)
      val inner-type = apply-subst(s1, elem-var)
      infer-pattern(env, s1, inner-type, inner)
    PNone ->
      val elem-var = fresh-tvar()
      val s1 = compose-subst(unify(scrut-type, TMaybe(elem-var), no-span), s)
      (s1, env)
    POk(inner) ->
      val ok-var = fresh-tvar()
      val err-var = fresh-tvar()
      val s1 = compose-subst(unify(scrut-type, TResult(ok-var, err-var), no-span), s)
      val inner-type = apply-subst(s1, ok-var)
      infer-pattern(env, s1, inner-type, inner)
    PErr(inner) ->
      val ok-var = fresh-tvar()
      val err-var = fresh-tvar()
      val s1 = compose-subst(unify(scrut-type, TResult(ok-var, err-var), no-span), s)
      val inner-type = apply-subst(s1, err-var)
      infer-pattern(env, s1, inner-type, inner)

// Extract the inferred type from a node, defaulting to TUnit.
fun get-type( n : node ) : hica-type
  match n.typ
    Just(t)  -> t
    Nothing  -> TUnit

// ---------------------------------------------------------------------------
// Top-level: check a full program
// ---------------------------------------------------------------------------

// Infer a top-level function declaration.
// Supports self-recursion: the function's own name is pre-seeded in the
// environment with a fresh type so recursive calls can resolve.
fun infer-decl( env : type-env, s : subst, d : fun-decl ) : <div,diag,fresh> (subst, type-env, fun-decl)
  // Assign types to each parameter: use annotation if provided, otherwise fresh type variable
  val param-types = zip-with-anns(d.params, d.param-anns)
  val ret-var = match d.ret-ann
    Just(t) -> t
    Nothing -> fresh-tvar()
  // Pre-seed the environment with the function's own type (enables recursion)
  val self-type = TFun(param-types, ret-var)
  val env-with-self = env.extend(d.name, self-type)
  // Extend environment with params
  val param-env = zip(d.params, param-types).foldl(env-with-self, fn(e, entry) match entry { (n, t) -> e.extend(n, t) })
  // Infer the body
  val (s1, body') = infer(param-env, s, d.body)
  val body-type = get-type(body')
  // Unify the pre-seeded return type with the actual body type
  val s2 = compose-subst(unify(apply-subst(s1, ret-var), apply-subst(s1, body-type), d.body.span), s1)
  // Build the function type
  val resolved-params = param-types.map(fn(t) apply-subst(s2, t))
  val fun-type = TFun(resolved-params, apply-subst(s2, body-type))
  // Detect if the function is recursive (calls itself in its body)
  val recursive = body-calls-name(d.body, d.name)
  // Extend the outer environment with this function's name
  val env' = env.extend(d.name, fun-type)
  val d' = d(body = body', param-types = resolved-params, ret-type = Just(apply-subst(s2, body-type)), is-recursive = recursive)
  (s2, env', d')

// Check an entire program: infer all declarations in order.
pub fun check-program( p : program ) : <div,diag,fresh> program
  val (_, _, decls') = infer-decls(extern-env(), empty-subst, p.decls)
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

// ---------------------------------------------------------------------------
// Recursion detection: check if a function body calls a given name
// ---------------------------------------------------------------------------

fun body-calls-name( n : node, name : string ) : div bool
  match n.expr
    Var(v)                  -> v == name
    Call(callee, args)      -> body-calls-name(callee, name) || args.any(fn(a) body-calls-name(a, name))
    Binary(_, l, r)         -> body-calls-name(l, name) || body-calls-name(r, name)
    Unary(_, o)             -> body-calls-name(o, name)
    Let(_, _, init, body)   -> body-calls-name(init, name) || body-calls-name(body, name)
    LetTuple(_, init, body) -> body-calls-name(init, name) || body-calls-name(body, name)
    Block(stmts)            -> stmts.any(fn(st) body-calls-name(st, name))
    If(cond, th, el)        -> body-calls-name(cond, name) || body-calls-name(th, name) || body-calls-name(el, name)
    Match(scrut, arms)      -> body-calls-name(scrut, name) || arms.any(fn(a) body-calls-name(a.body, name))
    Fun(_, body)            -> body-calls-name(body, name)
    Repeat(count, body)     -> body-calls-name(count, name) || body-calls-name(body, name)
    ForIn(_, s, e, body)    -> body-calls-name(s, name) || body-calls-name(e, name) || body-calls-name(body, name)
    StringInterp(parts)     -> parts.any(fn(p) body-calls-name(p, name))
    Tuple(elems)            -> elems.any(fn(e) body-calls-name(e, name))
    EList(elems)            -> elems.any(fn(e) body-calls-name(e, name))
    TupleIndex(tup, _)      -> body-calls-name(tup, name)
    ListIndex(lst, idx)     -> body-calls-name(lst, name) || body-calls-name(idx, name)
    ListSlice(lst, sm, em)  ->
      body-calls-name(lst, name) ||
      sm.map(fn(x) body-calls-name(x, name)).default(False) ||
      em.map(fn(x) body-calls-name(x, name)).default(False)
    ESome(v)                -> body-calls-name(v, name)
    EOk(v)                  -> body-calls-name(v, name)
    EErr(v)                 -> body-calls-name(v, name)
    _                       -> False
