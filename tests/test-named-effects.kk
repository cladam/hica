/*
* hica – named effects (v2): milestone N1 + N2 tests
 *
 * This source file is part of the hica open source project
 * Copyright (C) 2026 Claes Adamsson <claes.adamsson@gmail.com>
 *
 * See https://github.com/cladam/hica/blob/main/LICENSE for license information
 *
 * Milestone N1 goal (see documentation/named-effects-journal.md):
 *   - `spawn` and `as` lex as keywords
 *   - `spawn Name { arms } with var … as ident` parses
 *   - Effects that appear in any `spawn` are emitted as `named effect …`
 *     with `fun`-shaped ops (design doc §7.6)
 *   - `spawn` expressions emit `with <binder> <- named handler` + `fun hc_<op>`
 *
 * Milestone N2 goal:
 *   - `ref.op(args)` fully type-checks: unknown-method + wrong-arg-type carry spans.
 *   - Codegen emits `<recv>.hc_<op>(<args>)` for tagged calls.
 *   - two-counters example runs and prints `c1 = 3` / `c2 = 101`.
 *
 * Deferred to N3:
 *   - `ref<E>` in function signatures (needs parser support)
 *   - Escape rule on `TRef(E)` values
 *
 * Deferred to N4:
 *   - `hica check` row reporting for spawn use in cross-effect scenarios
 *   - handle+spawn on the same effect promotion (untested here)
*/
import kunit
import syntax/ast
import syntax/lexer
import syntax/parser
import semantics/checker
import diagnostics/diagnostics
import emit/codegen
import transform/desugar

fun first-kind-is-spawn-kw( source : string ) : div bool
  match lex(source)
    Cons(t, _) -> match t.kind
      TkSpawn -> True
      _       -> False
    _ -> False

fun first-kind-is-as-kw( source : string ) : div bool
  match lex(source)
    Cons(t, _) -> match t.kind
      TkAs -> True
      _    -> False
    _ -> False

fun parse-error-count( source : string ) : div int
  val tokens = lex(source)
  val (_, errs) = run-parser-program-with-errors(tokens)
  errs.length

fun emit-program-show( source : string ) : <div,console> string
  val tokens = lex(source)
  val prog = run-parser-program(tokens)
  emit-program(prog)

fun emit-typed-program( source : string ) : <div,console> string
  val tokens = lex(source)
  val prog = run-parser-program(tokens)
  val desugared = desugar-program(prog)
  val (typed-prog, _) = collect-diagnostics
    run-fresh
      check-program(desugared)
  emit-program(typed-prog)

// Return the checker's diagnostic list for a given source.
fun check-diagnostics( source : string ) : <div,console> list<diagnostic>
  val tokens = lex(source)
  val prog = run-parser-program(tokens)
  val desugared = desugar-program(prog)
  val (_, ds) = collect-diagnostics
    run-fresh
      check-program(desugared)
  ds

val two-counters-src = "effect Counter {\n  fun incr()\n  fun get() : int\n}\n\nfun main() {\n  spawn Counter {\n    incr() => count = count + 1,\n    get() => count\n  } with var count = 0 as c1\n\n  spawn Counter {\n    incr() => count = count + 1,\n    get() => count\n  } with var count = 100 as c2\n\n  c1.incr()\n  c2.incr()\n\n  println(\"ok\")\n}\n"

pub fun main() : io ()
  println(bold("Named effects tests (N1 + N2)"))
  println("")
  defaultKDivHandler
    // --- (a) Lexer knows the new keywords -------------------------------
    dtest("lex: 'spawn' keyword produces TkSpawn")
      assert/is-true(first-kind-is-spawn-kw("spawn"))

    dtest("lex: 'as' keyword produces TkAs")
      assert/is-true(first-kind-is-as-kw("as"))

    // --- (b) Parser accepts a minimal spawn expression ------------------
    dtest("parse: minimal spawn expression")
      val src = "effect Counter { fun incr() }\nfun main() { spawn Counter { incr() => 0 } as c }"
      assert/is-true(parse-error-count(src) == 0)

    dtest("parse: spawn with state clause and multiple arms")
      val src = "effect Counter {\n  fun incr()\n  fun get() : int\n}\nfun main() {\n  spawn Counter {\n    incr() => count = count + 1,\n    get() => count\n  } with var count = 0 as c\n}"
      assert/is-true(parse-error-count(src) == 0)


    // --- (c) Codegen — N1 §7.2 shape, updated for N5 op-qualification --
    // N5: named-effect op names are effect-qualified (`hc_counter_incr`),
    // avoiding Koka's `hc_<op>/@select` collision when two named effects
    // share an op name. See documentation/named-effects-journal.md N5.
    dtest("codegen: two-counters emits 'named effect counter' (N1 promotion, N5-qualified ops)")
      val kk = emit-typed-program(two-counters-src)
      // Effect must be promoted to `named effect` — see design doc §7.6.
      val has-named-effect = kk.contains("named effect counter")
      // Ops must switch from `ctl` to `fun` AND get the effect-qualified
      // name — see design doc §7.1 / §7.2 and journal N5.
      val has-fun-op       = kk.contains("fun hc_counter_incr")
      val no-ctl-op        = !kk.contains("ctl hc_counter_incr") && !kk.contains("ctl hc_incr")
      // Un-qualified `hc_incr` must not appear as a bare op declaration
      // — only the qualified `hc_counter_incr` should reach codegen for
      // named-effect ops.
      val no-unqual-decl   = !kk.contains("fun hc_incr(")
      assert/is-true(has-named-effect && has-fun-op && no-ctl-op && no-unqual-decl)

    dtest("codegen: spawn emits 'with c1 <- named handler'")
      val kk = emit-typed-program(two-counters-src)
      val has-c1 = kk.contains("with c1 <- named handler")
      val has-c2 = kk.contains("with c2 <- named handler")
      // Named-handler arms are `fun hc_<effect>_<op>(...) <body>` (N5) —
      // no `resume(...)` wrapping, because named-effect ops are
      // tail-resumptive (§7.2).
      val no-resume = !kk.contains("resume(count)")
      val has-qualified-arm = kk.contains("fun hc_counter_incr")
      assert/is-true(has-c1 && has-c2 && no-resume && has-qualified-arm)


    // --- (d) Non-spawn effects still emit v1 shape ----------------------
    dtest("codegen: effect only used with handle stays `effect` + `ctl`")
      val src = "effect Log { fun info(s: string) }\nfun main() {\n  handle Log { info(s) => println(s) } in { info(\"hi\") }\n}\n"
      val kk = emit-typed-program(src)
      // No spawn — effect must NOT be promoted.
      assert/is-true(kk.contains("effect log") && kk.contains("ctl hc_info") && !kk.contains("named effect log"))

    // --- (e) N2 codegen: ref.op(args) dispatches on the binder ----------
    // N5 updates the emitted shape: dispatch is now
    // `c1.hc_<effect>_<op>(...)` — effect-qualified so two named effects
    // with the same op name don't collide. See documentation/
    // named-effects-journal.md N5.
    dtest("codegen: c1.incr() emits c1.hc_counter_incr()")
      val kk = emit-typed-program(two-counters-src)
      val has-c1-dispatch = kk.contains("c1.hc_counter_incr()")
      val has-c2-dispatch = kk.contains("c2.hc_counter_incr()")
      // Guard against N1's raw-tag leak: the emitted Koka must NOT
      // contain the internal `hc-ref-op:` marker anywhere.
      val no-raw-tag = !kk.contains("hc-ref-op:")
      assert/is-true(has-c1-dispatch && has-c2-dispatch && no-raw-tag)

    // --- (k) N5: two named effects with same-named op don't collide ----
    // The Koka error this guards against: "definition hc_send/@select is
    // already defined in this module". Effect-qualified op names
    // (`hc_pinger_send`, `hc_ponger_send`) are the fix.
    dtest("codegen: two spawned effects with the same op name compile (N5)")
      val src = "effect Pinger { fun send(msg: int) }\neffect Ponger { fun send(msg: int) }\nfun main() {\n  spawn Pinger { send(msg) => println(show(msg)) } as p\n  spawn Ponger { send(msg) => println(show(msg)) } as q\n  p.send(1)\n  q.send(2)\n}\n"
      val kk = emit-typed-program(src)
      val has-pinger-op = kk.contains("fun hc_pinger_send")
      val has-ponger-op = kk.contains("fun hc_ponger_send")
      val has-p-dispatch = kk.contains("p.hc_pinger_send(1)")
      val has-q-dispatch = kk.contains("q.hc_ponger_send(2)")
      assert/is-true(has-pinger-op && has-ponger-op && has-p-dispatch && has-q-dispatch)


    // --- (f) N2 checker: type-mismatch errors carry spans ---------------
    // Passing a string where the op declares an int should produce a
    // hica-level type-mismatch error with the standard message shape.
    dtest("check: ref.op(wrong-type) produces a type-mismatch diagnostic")
      val src = "effect Counter {\n  fun add(n: int)\n  fun get() : int\n}\nfun main() {\n  spawn Counter {\n    add(n) => count = count + n,\n    get() => count\n  } with var count = 0 as c\n  c.add(\"hello\")\n}\n"
      val ds = check-diagnostics(src)
      val errs = ds.filter(fn(d) match d.severity { Error -> True; _ -> False })
      val hit = errs.any(fn(d) d.message.contains("type mismatch"))
      assert/is-true(hit)

    // --- (g) N2 checker: unknown-op on a ref falls through cleanly ------
    // Calling a method that doesn't exist on the effect currently falls
    // through to the ordinary UFCS/generic path (a Var("unknown") lookup
    // will report "undefined variable"). This is a smoke-test: the check
    // must not crash, and it must produce *some* diagnostic. A dedicated
    // "not an operation of effect E" message lands in a later polish pass.
    dtest("check: ref.unknown_op() surfaces at least one diagnostic")
      val src = "effect Counter {\n  fun incr()\n  fun get() : int\n}\nfun main() {\n  spawn Counter {\n    incr() => count = count + 1,\n    get() => count\n  } with var count = 0 as c\n  c.does_not_exist()\n}\n"
      val ds = check-diagnostics(src)
      val errs = ds.filter(fn(d) match d.severity { Error -> True; _ -> False })
      assert/is-true(!errs.is-nil)

    // --- (h) N3 parser: `ref<E>` accepted in parameter position ---------
    // The parser should accept `ref<Counter>` inside a type annotation.
    // No parse errors should surface.
    dtest("parse: ref<E> in function parameter type")
      val src = "effect Counter {\n  fun incr()\n  fun get() : int\n}\nfun bump(c: ref<Counter>, n: int) {\n  if n > 0 { c.incr(); bump(c, n - 1) }\n}\nfun main() {\n  spawn Counter {\n    incr() => count = count + 1,\n    get() => count\n  } with var count = 0 as c\n  bump(c, 3)\n  println(show(c.get()))\n}\n"
      assert/is-true(parse-error-count(src) == 0)

    // --- (i) N3 escape rule: return-position escape is rejected ---------
    // A function that spawns locally and returns the binder must be
    // rejected — the handler goes out of scope with the enclosing block.
    // See documentation/named-effects-design.md §5.5.
    dtest("check: returning a locally-spawned ref escapes and errors")
      val src = "effect Counter {\n  fun incr()\n  fun get() : int\n}\nfun make() : ref<Counter> {\n  spawn Counter {\n    incr() => count = count + 1,\n    get() => count\n  } with var count = 0 as c\n  c\n}\nfun main() {\n  let x = make()\n  x.incr()\n}\n"
      val ds = check-diagnostics(src)
      val errs = ds.filter(fn(d) match d.severity { Error -> True; _ -> False })
      val hit = errs.any(fn(d) d.message.contains("escapes its handler"))
      assert/is-true(hit)

    // --- (j) N3 escape rule: parameter refs may be returned or passed --
    // Refs that come in as function parameters belong to the caller, so
    // returning or passing them does NOT trigger the escape rule.
    dtest("check: parameter ref is not treated as an escape")
      val src = "effect Counter {\n  fun incr()\n  fun get() : int\n}\nfun bump(c: ref<Counter>, n: int) {\n  if n > 0 { c.incr(); bump(c, n - 1) }\n}\nfun main() {\n  spawn Counter {\n    incr() => count = count + 1,\n    get() => count\n  } with var count = 0 as c\n  bump(c, 3)\n  println(show(c.get()))\n}\n"
      val ds = check-diagnostics(src)
      val errs = ds.filter(fn(d) match d.severity { Error -> True; _ -> False })
      val escape-errs = errs.filter(fn(d) d.message.contains("escapes its handler"))
      assert/is-true(escape-errs.is-nil)
