module semantics/analyser

import syntax/ast
import semantics/checker

pub type rule-category
  PurityEffects
  Immutability
  PipelinesAllocation
  ErrorHandling
  DoubleWrapping
  ClosureLambdaNoise

pub struct debt-item
  category : rule-category
  message  : string
  points   : int
  span     : span
  hint     : string

pub struct function-score
  name  : string
  items : list<debt-item>
  span  : span
  signature : string

// ---------------------------------------------------------------------------
// Formatters
// ---------------------------------------------------------------------------

fun score-cmp(a: function-score, b: function-score) : order
  val a-total = a.items.map(points).sum
  val b-total = b.items.map(points).sum
  if a-total > b-total then (Lt : order)
  elif a-total < b-total then (Gt : order)
  else (Eq : order)

fun sort-scores(scores: list<function-score>) : list<function-score>
  fun insert(s: function-score, xs: list<function-score>) : list<function-score>
    match xs
      Nil -> [s]
      Cons(x, rest) ->
        match score-cmp(s, x)
          Lt -> Cons(s, xs)
          Eq -> Cons(s, xs)
          Gt -> Cons(x, insert(s, rest))
  
  scores.foldl([], fn(acc, s) insert(s, acc))

pub fun format-terminal(file: string, source: string, scores: list<function-score>, total: int, num-decls: int) : string
  val non-empty-scores = scores.filter(fn(s) !s.items.is-empty)
  // Sort scores by highest debt first
  val sorted-scores = sort-scores(non-empty-scores)

  var critical-cnt := 0
  var high-cnt := 0
  var medium-cnt := 0

  val parts = sorted-scores.map fn(score)
    val func-total = score.items.map(points).sum
    val severity-label = 
      if func-total >= 10 then { critical-cnt := critical-cnt + 1; "\x1b[31m[CRITICAL]\x1b[0m" }
      elif func-total >= 6 then { high-cnt := high-cnt + 1; "\x1b[33m[HIGH]\x1b[0m" }
      else { medium-cnt := medium-cnt + 1; "\x1b[36m[MEDIUM]\x1b[0m" }

    // Resolve line number from span
    val start-pos = score.span.start
    val line-num = source.list.take(start-pos).filter(fn(c) c == '\n').length + 1
    
    val p1 = severity-label ++ " " ++ file ++ ":" ++ line-num.show ++ " (score: " ++ func-total.show ++ ")\n  " ++ score.signature ++ "\n"
    
    val p2 = score.items.map(fn(item)
      val cat-str = match item.category
        PurityEffects -> "Effects"
        Immutability -> "Immutability"
        PipelinesAllocation -> "Allocation"
        ErrorHandling -> "ErrorHandling"
        DoubleWrapping -> "DoubleWrapping"
        ClosureLambdaNoise -> "Style"
      val base-msg = "  - [" ++ cat-str ++ "] " ++ item.message ++ " (score: +" ++ item.points.show ++ ")\n"
      val hint-msg = if !item.hint.is-empty then "    └─> Hint: " ++ item.hint ++ "\n" else ""
      base-msg ++ hint-msg
    ).join("")
    
    p1 ++ p2 ++ "\n"

  val q-index = max(0, 100 - total)
  
  "=== Hica Code Quality & Functional Debt Report ===\n\n" ++
  parts.join("") ++
  "Summary: " ++ file ++ " | " ++ critical-cnt.show ++ " Critical | " ++ high-cnt.show ++ " High | " ++ medium-cnt.show ++ " Medium\n" ++
  "Total FP Quality Index: " ++ q-index.show ++ "/100\n"

pub fun format-markdown(file: string, source: string, scores: list<function-score>, total: int, num-decls: int, top-n: int) : string
  val non-empty-scores = scores.filter(fn(s) !s.items.is-empty)
  // Sort scores by highest debt first
  val sorted-scores = sort-scores(non-empty-scores)
  val top-scores = sorted-scores.take(top-n)

  val parts = top-scores.map fn(score)
    val func-total = score.items.map(points).sum
    val severity = 
      if func-total >= 10 then "Critical"
      elif func-total >= 6 then "High"
      else "Medium"

    // Resolve line number from span
    val start-pos = score.span.start
    val line-num = source.list.take(start-pos).filter(fn(c) c == '\n').length + 1
    
    val p1 = "## Function Context\n- **Name:** `" ++ score.name ++ "`\n- **Signature:** `" ++ score.signature ++ "`\n- **Location:** `" ++ file ++ ":" ++ line-num.show ++ "`\n- **Debt Score:** " ++ func-total.show ++ " (" ++ severity ++ ")\n\n## Detected FP Anti-Patterns\n"
    
    var idx := 1
    val p2 = score.items.map(fn(item)
      val cat-str = match item.category
        PurityEffects -> "Purity & Effects"
        Immutability -> "Immutability"
        PipelinesAllocation -> "Pipelines & Allocation"
        ErrorHandling -> "Error Handling"
        DoubleWrapping -> "Double Wrapping"
        ClosureLambdaNoise -> "Closure & Lambda Noise"
      val s = idx.show ++ ". **" ++ cat-str ++ ":** " ++ item.message ++ " (score: +" ++ item.points.show ++ ")\n" ++
              (if !item.hint.is-empty then "   - *Hint:* " ++ item.hint ++ "\n" else "")
      idx := idx + 1
      s
    ).join("")
    
    val end-pos = score.span.end
    val func-source = if start-pos < source.count && end-pos <= source.count && start-pos <= end-pos then
      source.list.drop(start-pos).take(end-pos - start-pos).string ++ "\n"
    else ""
    
    p1 ++ p2 ++ "\n## Code Snippet\n```hica\n" ++ func-source ++ "```\n\n---\n\n"
  
  val q-index = max(0, 100 - total)
  val debt-count = non-empty-scores.length
  val summary = if debt-count == 0 then
    "## Summary\n✅ **No functional debt detected** — all " ++ num-decls.show ++ " function(s) are clean.\n\n**FP Quality Index: " ++ q-index.show ++ "/100**\n"
  else
    val shown = top-scores.length
    val intro = if shown < debt-count then
      "Showing top " ++ shown.show ++ " of " ++ debt-count.show ++ " function(s) with debt.\n\n"
    else ""
    "## Summary\n" ++ intro ++ "- **Functions analysed:** " ++ num-decls.show ++ "\n- **Functions with debt:** " ++ debt-count.show ++ "\n- **Total debt score:** " ++ total.show ++ "\n\n**FP Quality Index: " ++ q-index.show ++ "/100**\n"

  "# Hica Analysis Hotspot: `" ++ file ++ "`\n\n" ++ parts.join("") ++ summary

pub fun analyse-program(prog: program, file: string, source: string, format: string, top: maybe<string>, extra-effectful: list<string>) : io ()
  val scores = prog.decls.map(fn(d) analyse-decl(d, extra-effectful))
  val total = scores.map(fn(s) s.items.map(points).sum).sum
  
  if format == "markdown" || format == "md" then
    val top-n = match top
      Just(s) -> match s.parse-int { Just(n) -> n; Nothing -> 1 }
      Nothing -> 1
    println(format-markdown(file, source, scores, total, prog.decls.length, top-n))
  else
    println(format-terminal(file, source, scores, total, prog.decls.length))

fun unwrap-block(n: node) : div node
  match n.expr
    Block(stmts) ->
      match stmts
        Cons(first, Nil) -> unwrap-block(first)
        _ -> n
    _ -> n

// Known effectful functions (mirror from main)
val console-fns = ["println", "eprintln"]
val fsys-fns    = ["read_file", "write_file", "read_lines", "write_lines"]
val io-fns      = ["input", "get_args", "get_env", "set_env", "set_env_nooverwrite"]
val ndet-fns    = ["random"]

// M6.5 — recognise handler-captured `var` bindings.
//
// A common idiom for observing state that only exists inside a handler is:
//
//   var final_count = -1
//   with_counter(() => { … final_count = 42 })
//   println(final_count)
//
// The outer `var` here is intentional — it's the only way in v1 to observe
// state that would otherwise be scoped to (and dropped by) the handler.
// Without this exception the analyser flags every such capture as
// `Immutability: mutable var` debt, which fires on legitimate uses of the
// `actor` sugar and the `with_<name>(fn() …)` helper pattern documented in
// `learn/47-effects-actors.hc`.
//
// The heuristic: a `VarDecl(name, _, _, body)` is handler-captured when
// `body` contains a `Fun(_, fun-body)` (an inline lambda) that assigns to
// `name`. This is deliberately loose — any lambda-capture-and-assign counts,
// not just handler callbacks — because writing that pattern outside a handler
// is rare, and when it does happen the `var` is still doing the same
// "escape hatch for a value that would otherwise be scoped inside a
// closure" job we don't want to penalise.
fun assigns-to-name( n : node, target : string ) : div bool
  match n.expr
    Assign(nm, value)         -> nm == target || assigns-to-name(value, target)
    Let(_, _, init, body)     -> assigns-to-name(init, target) || assigns-to-name(body, target)
    VarDecl(_, _, init, body) -> assigns-to-name(init, target) || assigns-to-name(body, target)
    LetTuple(_, init, body)   -> assigns-to-name(init, target) || assigns-to-name(body, target)
    Block(stmts)              -> stmts.any(fn(s) assigns-to-name(s, target))
    If(c, t, e)               -> assigns-to-name(c, target) || assigns-to-name(t, target) || assigns-to-name(e, target)
    Match(scrut, arms)        ->
      assigns-to-name(scrut, target) ||
      arms.any(fn(a) assigns-to-name(a.body, target)) ||
      arms.any(fn(a) match a.guard { Just(g) -> assigns-to-name(g, target); Nothing -> False })
    Fun(_, body)              -> assigns-to-name(body, target)
    Call(callee, args)        -> assigns-to-name(callee, target) || args.any(fn(a) assigns-to-name(a, target))
    Binary(_, l, r)           -> assigns-to-name(l, target) || assigns-to-name(r, target)
    Unary(_, o)               -> assigns-to-name(o, target)
    Repeat(c, body)           -> assigns-to-name(c, target) || assigns-to-name(body, target)
    ForIn(_, s, e, body)      -> assigns-to-name(s, target) || assigns-to-name(e, target) || assigns-to-name(body, target)
    ForEach(_, coll, body)    -> assigns-to-name(coll, target) || assigns-to-name(body, target)
    While(c, body)            -> assigns-to-name(c, target) || assigns-to-name(body, target)
    Loop(body)                -> assigns-to-name(body, target)
    StringInterp(parts)       -> parts.any(fn(p) assigns-to-name(p, target))
    Tuple(elems)              -> elems.any(fn(e) assigns-to-name(e, target))
    EList(elems)              -> elems.any(fn(e) assigns-to-name(e, target))
    MapLit(entries)           -> entries.any(fn((k, v)) assigns-to-name(k, target) || assigns-to-name(v, target))
    ListIndex(l, i)           -> assigns-to-name(l, target) || assigns-to-name(i, target)
    ListSlice(l, sm, em)      ->
      assigns-to-name(l, target) ||
      sm.map(fn(x) assigns-to-name(x, target)).default(False) ||
      em.map(fn(x) assigns-to-name(x, target)).default(False)
    TupleIndex(t, _)          -> assigns-to-name(t, target)
    ESome(v)                  -> assigns-to-name(v, target)
    EOk(v)                    -> assigns-to-name(v, target)
    EErr(v)                   -> assigns-to-name(v, target)
    FieldAccess(o, _)         -> assigns-to-name(o, target)
    StructLit(_, fields)      -> fields.any(fn((_, v)) assigns-to-name(v, target))
    StructUpdate(_, base, overrides, _) ->
      assigns-to-name(base, target) ||
      overrides.any(fn((_, v)) assigns-to-name(v, target))
    EConstructor(_, cargs)    -> cargs.any(fn(a) assigns-to-name(a, target))
    ETry(inner)               -> assigns-to-name(inner, target)
    EValidateTry(inner)       -> assigns-to-name(inner, target)
    EHandle(_, arms, state, body) ->
      state.any(fn((_, v)) assigns-to-name(v, target)) ||
      arms.any(fn(a) assigns-to-name(a.arm-body, target)) ||
      assigns-to-name(body, target)
    _                         -> False

// True iff `n` contains a lambda (`Fun`) whose body assigns to `target`.
// The lambda itself may be nested inside any expression — Call args, Match
// arms, Let bodies, etc.
fun contains-lambda-assigning-to( n : node, target : string ) : div bool
  match n.expr
    Fun(_, body) ->
      assigns-to-name(body, target) || contains-lambda-assigning-to(body, target)
    Let(_, _, init, body)     -> contains-lambda-assigning-to(init, target) || contains-lambda-assigning-to(body, target)
    VarDecl(_, _, init, body) -> contains-lambda-assigning-to(init, target) || contains-lambda-assigning-to(body, target)
    LetTuple(_, init, body)   -> contains-lambda-assigning-to(init, target) || contains-lambda-assigning-to(body, target)
    Assign(_, value)          -> contains-lambda-assigning-to(value, target)
    Block(stmts)              -> stmts.any(fn(s) contains-lambda-assigning-to(s, target))
    If(c, t, e)               -> contains-lambda-assigning-to(c, target) || contains-lambda-assigning-to(t, target) || contains-lambda-assigning-to(e, target)
    Match(scrut, arms)        ->
      contains-lambda-assigning-to(scrut, target) ||
      arms.any(fn(a) contains-lambda-assigning-to(a.body, target)) ||
      arms.any(fn(a) match a.guard { Just(g) -> contains-lambda-assigning-to(g, target); Nothing -> False })
    Call(callee, args)        -> contains-lambda-assigning-to(callee, target) || args.any(fn(a) contains-lambda-assigning-to(a, target))
    Binary(_, l, r)           -> contains-lambda-assigning-to(l, target) || contains-lambda-assigning-to(r, target)
    Unary(_, o)               -> contains-lambda-assigning-to(o, target)
    Repeat(c, body)           -> contains-lambda-assigning-to(c, target) || contains-lambda-assigning-to(body, target)
    ForIn(_, s, e, body)      -> contains-lambda-assigning-to(s, target) || contains-lambda-assigning-to(e, target) || contains-lambda-assigning-to(body, target)
    ForEach(_, coll, body)    -> contains-lambda-assigning-to(coll, target) || contains-lambda-assigning-to(body, target)
    While(c, body)            -> contains-lambda-assigning-to(c, target) || contains-lambda-assigning-to(body, target)
    Loop(body)                -> contains-lambda-assigning-to(body, target)
    StringInterp(parts)       -> parts.any(fn(p) contains-lambda-assigning-to(p, target))
    Tuple(elems)              -> elems.any(fn(e) contains-lambda-assigning-to(e, target))
    EList(elems)              -> elems.any(fn(e) contains-lambda-assigning-to(e, target))
    MapLit(entries)           -> entries.any(fn((k, v)) contains-lambda-assigning-to(k, target) || contains-lambda-assigning-to(v, target))
    ListIndex(l, i)           -> contains-lambda-assigning-to(l, target) || contains-lambda-assigning-to(i, target)
    ListSlice(l, sm, em)      ->
      contains-lambda-assigning-to(l, target) ||
      sm.map(fn(x) contains-lambda-assigning-to(x, target)).default(False) ||
      em.map(fn(x) contains-lambda-assigning-to(x, target)).default(False)
    TupleIndex(t, _)          -> contains-lambda-assigning-to(t, target)
    ESome(v)                  -> contains-lambda-assigning-to(v, target)
    EOk(v)                    -> contains-lambda-assigning-to(v, target)
    EErr(v)                   -> contains-lambda-assigning-to(v, target)
    FieldAccess(o, _)         -> contains-lambda-assigning-to(o, target)
    StructLit(_, fields)      -> fields.any(fn((_, v)) contains-lambda-assigning-to(v, target))
    StructUpdate(_, base, overrides, _) ->
      contains-lambda-assigning-to(base, target) ||
      overrides.any(fn((_, v)) contains-lambda-assigning-to(v, target))
    EConstructor(_, cargs)    -> cargs.any(fn(a) contains-lambda-assigning-to(a, target))
    ETry(inner)               -> contains-lambda-assigning-to(inner, target)
    EValidateTry(inner)       -> contains-lambda-assigning-to(inner, target)
    EHandle(_, arms, state, body) ->
      state.any(fn((_, v)) contains-lambda-assigning-to(v, target)) ||
      arms.any(fn(a) contains-lambda-assigning-to(a.arm-body, target)) ||
      contains-lambda-assigning-to(body, target)
    _                         -> False

pub fun analyse-decl(decl: fun-decl, extra-effectful: list<string>) : div function-score
  fun is-list-op(node: node) : bool
    match node.typ { Just(TList(_)) -> True; _ -> False }

  fun is-nested-list-call(node: node, depth: int) : div bool
    if depth >= 3 then True
    else match node.expr
      Call(_, args) ->
        match args.head
          Just(arg1) -> 
            if is-list-op(arg1) then is-nested-list-call(arg1, depth + 1)
            else False
          Nothing -> False
      _ -> False

  fun add-debt-pure(state: (list<debt-item>, bool, bool), cat: rule-category, msg: string, pts: int, sp: span, hint: string) : (list<debt-item>, bool, bool)
    val (items, io, cons-eff) = state
    (Cons(Debt-item(cat, msg, pts, sp, hint), items), io, cons-eff)

  fun walk(n: node, in-pipeline: bool, state: (list<debt-item>, bool, bool)) : div (list<debt-item>, bool, bool)
    match n.expr
      Let(_name, _t, init, body) ->
        val s1 = walk(init, False, state)
        walk(body, False, s1)
      VarDecl(name, _t, init, body) ->
        // Batch 3: Immutability rule (VarDecl)
        // M6.5 exception: if the var is captured-and-assigned by an inline
        // lambda somewhere in its scope (typical for `with_<actor>(fn() {
        // captured = … })` and handler-callback patterns), the `var` is the
        // sanctioned way to observe post-handler state and should not accrue
        // debt. See learn/47-effects-actors.hc for the pattern.
        val is-handler-capture = contains-lambda-assigning-to(body, name)
        val s1 =
          if is-handler-capture then state
          else add-debt-pure(state, Immutability, "Mutable 'var' declaration used", 5, n.span, "Suggest using 'map', 'filter', 'fold', or lazy streams instead.")
        val s2 = walk(init, False, s1)
        walk(body, False, s2)
      Assign(_name, value) ->
        walk(value, False, state)
      Fun(params, body) ->
        // Batch 3: Lambda Noise rule
        // Only flag as noise if the call is NOT using UFCS dot-notation.
        // If args[0].span is before callee.span, the user wrote `arg.callee()`, which is an intentional style choice.
        val unwrapped-body = unwrap-block(body)
        val s1 = match unwrapped-body.expr
          Call(callee, args) ->
            if args.length == params.length && !params.is-empty then
              match args.head
                Just(first-arg) ->
                  val is-ufcs = first-arg.span.start < callee.span.start
                  if !is-ufcs then
                    val is-noise = args.zip(params).all fn((a, p))
                      match a.expr { Var(name) -> name == p; _ -> False }
                    if is-noise then
                      add-debt-pure(state, ClosureLambdaNoise, "Redundant lambda wrapper (Lambda Noise)", 3, n.span, "Convert to point-free style (e.g. filter(is_even) instead of filter((x) => is_even(x))).")
                    else state
                  else state
                Nothing -> state
            else state
          _ -> state
        walk(body, False, s1)
      Call(callee, args) ->
        // Batch 4: Pipelines & Allocation
        // Check for eager list pipelines with >2 operations
        val is-lop = is-list-op(n)
        val is-pipe = is-lop && is-nested-list-call(n, 1)
        val matched-here = is-pipe && !in-pipeline
        val s1 = if matched-here then
          add-debt-pure(state, PipelinesAllocation, "Eager list pipeline with >2 operations", 10, n.span, "Wrap input with 'stream(xs)' from 'std/stream' or use pipeline transducers from 'std/xform' to eliminate intermediate list allocations.")
        else state

        // Batch 4: Purity & Effects
        val (items, io, cons-eff) = s1
        val next-io = match callee.expr
          Var(name) -> io || io-fns.any(fn(f) f == name) || fsys-fns.any(fn(f) f == name) || extra-effectful.any(fn(f) f == name)
          _ -> io
        val next-con = match callee.expr
          Var(name) -> cons-eff || console-fns.any(fn(f) f == name)
          _ -> cons-eff
        val s2 = (items, next-io, next-con)

        val s3 = walk(callee, False, s2)
        match args
          Nil -> s3
          Cons(first, rest) ->
            val s4 = walk(first, is-lop || in-pipeline, s3)
            rest.foldl(s4, fn(acc, a) walk(a, False, acc))
      Binary(_op, lhs, rhs) ->
        val s1 = walk(lhs, False, state)
        walk(rhs, False, s1)
      Unary(_op, operand) ->
        walk(operand, False, state)
      If(cond, then-e, else-e) ->
        val s1 = walk(cond, False, state)
        val s2 = walk(then-e, False, s1)
        walk(else-e, False, s2)
      Block(stmts) ->
        stmts.foldl(state, fn(acc, s) walk(s, False, acc))
      Match(scrut, arms) ->
        // Batch 4: Error Handling (Nested match on Maybe/Result)
        val is-wrapper = match scrut.typ
          Just(TMaybe(_)) -> True
          Just(TResult(_, _)) -> True
          _ -> False
        
        val s1 = if is-wrapper then
          val has-nested = arms.any fn(a)
            val unwrapped-arm-body = unwrap-block(a.body)
            match unwrapped-arm-body.expr
              Match(inner-scrut, _) ->
                match inner-scrut.typ
                  Just(TMaybe(_)) -> True
                  Just(TResult(_, _)) -> True
                  _ -> False
              _ -> False
          if has-nested then
            add-debt-pure(state, ErrorHandling, "Nested 'match' on maybe/result", 8, n.span, "Suggest using '?' operator or combinators (like 'and_then'/'and_then_result') to reduce nested block depth.")
          else state
        else state

        val s2 = walk(scrut, False, s1)
        arms.foldl(s2) fn(acc, a)
          val s3 = match a.guard { Just(g) -> walk(g, False, acc); Nothing -> acc }
          walk(a.body, False, s3)
      Repeat(count, body) ->
        val s1 = walk(count, False, state)
        walk(body, False, s1)
      ForIn(_name, start-e, end-e, body) ->
        // Batch 3: Immutability rule (ForIn)
        val s1 = add-debt-pure(state, Immutability, "Imperative 'for' loop used", 5, n.span, "Refactor to standard list combinators like 'map', 'filter', or 'fold'.")
        val s2 = walk(start-e, False, s1)
        val s3 = walk(end-e, False, s2)
        walk(body, False, s3)
      ForEach(_name, coll, body) ->
        val s1 = walk(coll, False, state)
        walk(body, False, s1)
      While(cond, body) ->
        // Batch 3: Immutability rule (While)
        val s1 = add-debt-pure(state, Immutability, "Imperative 'while' loop used", 5, n.span, "Refactor using tail recursion or standard combinators.")
        val s2 = walk(cond, False, s1)
        walk(body, False, s2)
      Loop(body) ->
        val s1 = add-debt-pure(state, Immutability, "Imperative 'loop' used", 5, n.span, "Refactor using recursive functions.")
        walk(body, False, s1)
      StringInterp(parts) ->
        parts.foldl(state, fn(acc, p) walk(p, False, acc))
      Tuple(elems) ->
        elems.foldl(state, fn(acc, e) walk(e, False, acc))
      EList(elems) ->
        elems.foldl(state, fn(acc, e) walk(e, False, acc))
      MapLit(entries) ->
        entries.foldl(state) fn(acc, (k, v))
          val s1 = walk(k, False, acc)
          walk(v, False, s1)
      ListIndex(lst, idx) ->
        val s1 = walk(lst, False, state)
        walk(idx, False, s1)
      ListSlice(lst, s, e) ->
        val s1 = walk(lst, False, state)
        val s2 = match s { Just(x) -> walk(x, False, s1); Nothing -> s1 }
        match e { Just(x) -> walk(x, False, s2); Nothing -> s2 }
      TupleIndex(tup, _idx) ->
        walk(tup, False, state)
      LetTuple(_names, init, body) ->
        val s1 = walk(init, False, state)
        walk(body, False, s1)
      ESome(value) ->
        walk(value, False, state)
      EOk(value) ->
        walk(value, False, state)
      EErr(value) ->
        walk(value, False, state)
      StructLit(_name, fields) ->
        fields.foldl(state, fn(acc, (_, v)) walk(v, False, acc))
      StructUpdate(_name, base, fields, _def-fields) ->
        val s1 = walk(base, False, state)
        fields.foldl(s1, fn(acc, (_, v)) walk(v, False, acc))
      FieldAccess(obj, _f) ->
        walk(obj, False, state)
      // Handler expression: walk the state initialisers, each arm body, and
      // the handled `in { body }` block so debt inside handlers (mutable
      // vars, loops, nested matches, etc.) is still counted. The `handled`
      // stack is a discovery-time concern, so we ignore it here.
      EHandle(_ename, arms, hstate, hbody) ->
        val s1 = hstate.foldl(state, fn(acc, entry)
          match entry
            (_, init) -> walk(init, False, acc)
        )
        val s2 = arms.foldl(s1, fn(acc, arm) walk(arm.arm-body, False, acc))
        walk(hbody, False, s2)
      _ -> state


  val init-state = ([], False, False)
  val state-with-wrapping = match decl.ret-type
    Just(TMaybe(TMaybe(_))) -> 
      add-debt-pure(init-state, DoubleWrapping, "Function returns nested maybe<maybe<T>>", 6, decl.span, "Use 'and_then' or 'flat_map' to flatten the structure.")
    Just(TResult(TResult(_, _), _)) -> 
      add-debt-pure(init-state, DoubleWrapping, "Function returns nested result<result<T, E>, E>", 6, decl.span, "Use 'and_then_result' to flatten the structure.")
    _ -> init-state

  val (items, has-io, has-console) = walk(decl.body, False, state-with-wrapping)

  val final-items = if has-io && has-console then
    Cons(Debt-item(PurityEffects, "Mixed side effects [io/fsys, console] in function", 8, decl.span, "Encourage isolating pure core logic from impure I/O shell."), items)
  else items

  fun format-params(ps: list<string>, ts: list<hica-type>) : div string
    match (ps, ts)
      (Cons(p, prs), Cons(t, trs)) ->
        val rest = format-params(prs, trs)
        val sep = if rest.is-empty then "" else ", "
        p ++ ": " ++ t.show ++ sep ++ rest
      _ -> ""

  val ret-str = match decl.ret-type
    Just(t) -> " : " ++ t.show
    Nothing -> ""
  val sig = "fun " ++ decl.name ++ "(" ++ format-params(decl.params, decl.param-types) ++ ")" ++ ret-str

  Function-score(decl.name, items.reverse, decl.span, sig)
