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

pub struct function-score
  name  : string
  items : list<debt-item>
  span  : span

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
    val line-num = source.slice.extend(start-pos).string.lines.length
    
    val p1 = severity-label ++ " " ++ file ++ ":" ++ line-num.show ++ " (score: " ++ func-total.show ++ ")\n  fun " ++ score.name ++ "(...)\n"
    
    val p2 = score.items.map(fn(item)
      val cat-str = match item.category
        PurityEffects -> "Effects"
        Immutability -> "Immutability"
        PipelinesAllocation -> "Allocation"
        ErrorHandling -> "ErrorHandling"
        DoubleWrapping -> "DoubleWrapping"
        ClosureLambdaNoise -> "Style"
      "  - [" ++ cat-str ++ "] " ++ item.message ++ "\n"
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
    val line-num = source.slice.extend(start-pos).string.lines.length
    
    val p1 = "## Function Context\n- **Name:** `" ++ score.name ++ "`\n- **Location:** `" ++ file ++ ":" ++ line-num.show ++ "`\n- **Debt Score:** " ++ func-total.show ++ " (" ++ severity ++ ")\n\n## Detected FP Anti-Patterns\n"
    
    var idx := 1
    val p2 = score.items.map(fn(item)
      val cat-str = match item.category
        PurityEffects -> "Purity & Effects"
        Immutability -> "Immutability"
        PipelinesAllocation -> "Pipelines & Allocation"
        ErrorHandling -> "Error Handling"
        DoubleWrapping -> "Double Wrapping"
        ClosureLambdaNoise -> "Closure & Lambda Noise"
      val s = idx.show ++ ". **" ++ cat-str ++ ":** " ++ item.message ++ "\n"
      idx := idx + 1
      s
    ).join("")
    
    val end-pos = score.span.end
    val func-source = if start-pos < source.count && end-pos <= source.count && start-pos <= end-pos then
       source.slice.extend(end-pos).drop(start-pos).string ++ "\n"
    else ""
    
    p1 ++ p2 ++ "\n## Code Snippet\n```hica\n" ++ func-source ++ "```\n\n---\n\n"
  
  "# Hica Analysis Hotspot: `" ++ file ++ "`\n\n" ++ parts.join("")

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

pub fun analyse-decl(decl: fun-decl, extra-effectful: list<string>) : div function-score
  var items : list<debt-item> := []
  
  fun add-debt(cat: rule-category, msg: string, pts: int, sp: span)
    items := Cons(Debt-item(cat, msg, pts, sp), items)

  // Batch 4: Double-wrapping
  match decl.ret-type
    Just(TMaybe(TMaybe(_))) -> 
      add-debt(DoubleWrapping, "Function returns nested maybe<maybe<T>> (suggest 'and_then'/'flat_map')", 6, decl.span)
    Just(TResult(TResult(_, _), _)) -> 
      add-debt(DoubleWrapping, "Function returns nested result<result<T, E>, E> (suggest 'and_then_result')", 6, decl.span)
    _ -> ()

  var has-io := False
  var has-console := False

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

  fun walk(n: node, in-pipeline: bool)
    match n.expr
      Let(_name, _t, init, body) ->
        walk(init, False)
        walk(body, False)
      VarDecl(_name, _t, init, body) ->
        // Batch 3: Immutability rule (VarDecl)
        add-debt(Immutability, "Mutable 'var' declaration used", 5, n.span)
        walk(init, False)
        walk(body, False)
      Assign(_name, value) ->
        walk(value, False)
      Fun(params, body) ->
        // Batch 3: Lambda Noise rule
        // Only flag as noise if the call is NOT using UFCS dot-notation.
        // If args[0].span is before callee.span, the user wrote `arg.callee()`, which is an intentional style choice.
        val unwrapped-body = unwrap-block(body)
        match unwrapped-body.expr
          Call(callee, args) ->
            if args.length == params.length && !params.is-empty then
              match args.head
                Just(first-arg) ->
                  val is-ufcs = first-arg.span.start < callee.span.start
                  if !is-ufcs then
                    val is-noise = args.zip(params).all fn((a, p))
                      match a.expr { Var(name) -> name == p; _ -> False }
                    if is-noise then
                      add-debt(ClosureLambdaNoise, "Redundant lambda wrapper (Lambda Noise)", 3, n.span)
                Nothing -> ()
          _ -> ()
        walk(body, False)
      Call(callee, args) ->
        // Batch 4: Pipelines & Allocation
        // Check for eager list pipelines with >2 operations
        val is-lop = is-list-op(n)
        val is-pipe = is-lop && is-nested-list-call(n, 1)
        val matched-here = is-pipe && !in-pipeline
        if matched-here then
          add-debt(PipelinesAllocation, "Eager list pipeline with >2 operations (suggest 'std/stream')", 10, n.span)

        // Batch 4: Purity & Effects
        match callee.expr
          Var(name) ->
            if io-fns.any(fn(f) f == name) || fsys-fns.any(fn(f) f == name) || extra-effectful.any(fn(f) f == name) then has-io := True
            if console-fns.any(fn(f) f == name) then has-console := True
          _ -> ()

        walk(callee, False)
        match args
          Nil -> ()
          Cons(first, rest) ->
            walk(first, is-lop || in-pipeline)
            rest.foreach(fn(a) walk(a, False))
      Binary(_op, lhs, rhs) ->
        walk(lhs, False)
        walk(rhs, False)
      Unary(_op, operand) ->
        walk(operand, False)
      If(cond, then-e, else-e) ->
        walk(cond, False)
        walk(then-e, False)
        walk(else-e, False)
      Block(stmts) ->
        stmts.foreach(fn(s) walk(s, False))
      Match(scrut, arms) ->
        // Batch 4: Error Handling (Nested match on Maybe/Result)
        val is-wrapper = match scrut.typ
          Just(TMaybe(_)) -> True
          Just(TResult(_, _)) -> True
          _ -> False
        
        if is-wrapper then
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
            add-debt(ErrorHandling, "Nested 'match' on maybe/result (suggest '?' operator or combinators)", 8, n.span)

        walk(scrut, False)
        arms.foreach fn(a)
          match a.guard { Just(g) -> walk(g, False); Nothing -> () }
          walk(a.body, False)
      Repeat(count, body) ->
        walk(count, False)
        walk(body, False)
      ForIn(_name, start-e, end-e, body) ->
        // Batch 3: Immutability rule (ForIn)
        add-debt(Immutability, "Imperative 'for' loop used", 5, n.span)
        walk(start-e, False)
        walk(end-e, False)
        walk(body, False)
      ForEach(_name, coll, body) ->
        walk(coll, False)
        walk(body, False)
      While(cond, body) ->
        // Batch 3: Immutability rule (While)
        add-debt(Immutability, "Imperative 'while' loop used", 5, n.span)
        walk(cond, False)
        walk(body, False)
      Loop(body) ->
        add-debt(Immutability, "Imperative 'loop' used", 5, n.span)
        walk(body, False)
      StringInterp(parts) ->
        parts.foreach(fn(p) walk(p, False))
      Tuple(elems) ->
        elems.foreach(fn(e) walk(e, False))
      EList(elems) ->
        elems.foreach(fn(e) walk(e, False))
      MapLit(entries) ->
        entries.foreach fn((k, v))
          walk(k, False)
          walk(v, False)
      ListIndex(lst, idx) ->
        walk(lst, False)
        walk(idx, False)
      ListSlice(lst, s, e) ->
        walk(lst, False)
        match s { Just(x) -> walk(x, False); Nothing -> () }
        match e { Just(x) -> walk(x, False); Nothing -> () }
      TupleIndex(tup, _idx) ->
        walk(tup, False)
      LetTuple(_names, init, body) ->
        walk(init, False)
        walk(body, False)
      ESome(value) ->
        walk(value, False)
      EOk(value) ->
        walk(value, False)
      EErr(value) ->
        walk(value, False)
      StructLit(_name, fields) ->
        fields.foreach fn((_, v))
          walk(v, False)
      StructUpdate(_name, base, fields, _def-fields) ->
        walk(base, False)
        fields.foreach fn((_, v))
          walk(v, False)
      FieldAccess(obj, _f) ->
        walk(obj, False)
      _ -> ()

  walk(decl.body, False)

  if has-io && has-console then
    add-debt(PurityEffects, "Mixed side effects [io/fsys, console] in function (suggest isolating pure core logic)", 8, decl.span)

  Function-score(decl.name, items.reverse, decl.span)
