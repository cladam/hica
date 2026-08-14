/*
 * hica – named effects (v2): milestone N1 tests
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
 * Deferred to N2:
 *   - `ref<E>` method dispatch (`c1.incr()`) — needs checker rewrite
 *   - Escape rule on `TRef(E)` values
 *   - `hica check` row reporting for spawn use
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

val two-counters-src = "effect Counter {\n  fun incr()\n  fun get() : int\n}\n\nfun main() {\n  spawn Counter {\n    incr() => count = count + 1,\n    get() => count\n  } with var count = 0 as c1\n\n  spawn Counter {\n    incr() => count = count + 1,\n    get() => count\n  } with var count = 100 as c2\n\n  println(\"ok\")\n}\n"

pub fun main() : io ()
  println(bold("Named effects tests (N1)"))
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


    // --- (c) Codegen — N1 §7.2 shape ------------------------------------
    dtest("codegen: two-counters emits 'named effect counter' (N1 promotion)")
      val kk = emit-typed-program(two-counters-src)
      // Effect must be promoted to `named effect` — see design doc §7.6.
      val has-named-effect = kk.contains("named effect counter")
      // Ops must switch from `ctl` to `fun` — see design doc §7.2.
      val has-fun-op       = kk.contains("fun hc_incr")
      val no-ctl-op        = !kk.contains("ctl hc_incr")
      assert/is-true(has-named-effect && has-fun-op && no-ctl-op)

    dtest("codegen: spawn emits 'with c1 <- named handler'")
      val kk = emit-typed-program(two-counters-src)
      val has-c1 = kk.contains("with c1 <- named handler")
      val has-c2 = kk.contains("with c2 <- named handler")
      // Named-handler arms are `fun hc_<op>(...) <body>` — no `resume(...)`
      // wrapping, because named-effect ops are tail-resumptive (§7.2).
      val no-resume = !kk.contains("resume(count)")
      assert/is-true(has-c1 && has-c2 && no-resume)

    // --- (d) Non-spawn effects still emit v1 shape ----------------------
    dtest("codegen: effect only used with handle stays `effect` + `ctl`")
      val src = "effect Log { fun info(s: string) }\nfun main() {\n  handle Log { info(s) => println(s) } in { info(\"hi\") }\n}\n"
      val kk = emit-typed-program(src)
      // No spawn — effect must NOT be promoted.
      assert/is-true(kk.contains("effect log") && kk.contains("ctl hc_info") && !kk.contains("named effect log"))
