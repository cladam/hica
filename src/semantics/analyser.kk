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

pub fun analyse-program(prog: program) : io ()
  val scores = prog.decls.map(analyse-decl)
  val total = scores.map(fn(s) s.items.map(points).sum).sum
  
  scores.foreach fn(score)
    if !score.items.is-empty then
      println("Function: " ++ score.name)
      score.items.foreach fn(item)
        println("  - [" ++ item.points.show ++ "] " ++ item.message)

  println("\nAnalysis complete. Processed " ++ prog.decls.length.show ++ " declarations.")
  println("Total debt: " ++ total.show)

// Known effectful functions (mirror from main)
val console-fns = ["println", "eprintln"]
val fsys-fns    = ["read_file", "write_file", "read_lines", "write_lines"]
val io-fns      = ["input", "get_args", "get_env", "set_env", "set_env_nooverwrite"]
val ndet-fns    = ["random"]

pub fun analyse-decl(decl: fun-decl) : div function-score
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

  fun walk(n: node)
    match n.expr
      Let(_name, _t, init, body) ->
        walk(init)
        walk(body)
      VarDecl(_name, _t, init, body) ->
        // Batch 3: Immutability rule (VarDecl)
        add-debt(Immutability, "Mutable 'var' declaration used", 5, n.span)
        walk(init)
        walk(body)
      Assign(_name, value) ->
        walk(value)
      Fun(params, body) ->
        // Batch 3: Lambda Noise rule
        match body.expr
          Call(_callee, args) ->
            if args.length == params.length && !params.is-empty then
              val is-noise = args.zip(params).all fn((a, p))
                match a.expr { Var(name) -> name == p; _ -> False }
              if is-noise then
                add-debt(ClosureLambdaNoise, "Redundant lambda wrapper (Lambda Noise)", 3, n.span)
          _ -> ()
        walk(body)
      Call(callee, args) ->
        // Batch 4: Pipelines & Allocation
        // Check for eager list pipelines with >2 operations
        if is-list-op(n) && is-nested-list-call(n, 1) then
          add-debt(PipelinesAllocation, "Eager list pipeline with >2 operations (suggest 'std/stream')", 10, n.span)

        // Batch 4: Purity & Effects
        match callee.expr
          Var(name) ->
            if io-fns.any(fn(f) f == name) || fsys-fns.any(fn(f) f == name) then has-io := True
            if console-fns.any(fn(f) f == name) then has-console := True
          _ -> ()

        walk(callee)
        args.foreach(walk)
      Binary(_op, lhs, rhs) ->
        walk(lhs)
        walk(rhs)
      Unary(_op, operand) ->
        walk(operand)
      If(cond, then-e, else-e) ->
        walk(cond)
        walk(then-e)
        walk(else-e)
      Block(stmts) ->
        stmts.foreach(walk)
      Match(scrut, arms) ->
        // Batch 4: Error Handling (Nested match on Maybe/Result)
        val is-wrapper = match scrut.typ
          Just(TMaybe(_)) -> True
          Just(TResult(_, _)) -> True
          _ -> False
        
        if is-wrapper then
          val has-nested = arms.any fn(a)
            match a.body.expr
              Match(inner-scrut, _) ->
                match inner-scrut.typ
                  Just(TMaybe(_)) -> True
                  Just(TResult(_, _)) -> True
                  _ -> False
              _ -> False
          if has-nested then
            add-debt(ErrorHandling, "Nested 'match' on maybe/result (suggest '?' operator or combinators)", 8, n.span)

        walk(scrut)
        arms.foreach fn(a)
          match a.guard { Just(g) -> walk(g); Nothing -> () }
          walk(a.body)
      Repeat(count, body) ->
        walk(count)
        walk(body)
      ForIn(_name, start-e, end-e, body) ->
        // Batch 3: Immutability rule (ForIn)
        add-debt(Immutability, "Imperative 'for' loop used", 5, n.span)
        walk(start-e)
        walk(end-e)
        walk(body)
      ForEach(_name, coll, body) ->
        walk(coll)
        walk(body)
      While(cond, body) ->
        // Batch 3: Immutability rule (While)
        add-debt(Immutability, "Imperative 'while' loop used", 5, n.span)
        walk(cond)
        walk(body)
      Loop(body) ->
        add-debt(Immutability, "Imperative 'loop' used", 5, n.span)
        walk(body)
      StringInterp(parts) ->
        parts.foreach(walk)
      Tuple(elems) ->
        elems.foreach(walk)
      EList(elems) ->
        elems.foreach(walk)
      MapLit(entries) ->
        entries.foreach fn((k, v))
          walk(k)
          walk(v)
      ListIndex(lst, idx) ->
        walk(lst)
        walk(idx)
      ListSlice(lst, s, e) ->
        walk(lst)
        match s { Just(x) -> walk(x); Nothing -> () }
        match e { Just(x) -> walk(x); Nothing -> () }
      TupleIndex(tup, _idx) ->
        walk(tup)
      LetTuple(_names, init, body) ->
        walk(init)
        walk(body)
      ESome(value) ->
        walk(value)
      EOk(value) ->
        walk(value)
      EErr(value) ->
        walk(value)
      StructLit(_name, fields) ->
        fields.foreach fn((_, v))
          walk(v)
      StructUpdate(_name, base, fields, _def-fields) ->
        walk(base)
        fields.foreach fn((_, v))
          walk(v)
      FieldAccess(obj, _f) ->
        walk(obj)
      _ -> ()

  walk(decl.body)

  if has-io && has-console then
    add-debt(PurityEffects, "Mixed side effects [io/fsys, console] in function (suggest isolating pure core logic)", 8, decl.span)

  Function-score(decl.name, items.reverse, decl.span)
