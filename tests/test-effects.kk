/*
 * hica – user-facing algebraic effects: milestone 1 tests
 *
 * This source file is part of the hica open source project
 * Copyright (C) 2026 Claes Adamsson <claes.adamsson@gmail.com>
 *
 * See https://github.com/cladam/hica/blob/main/LICENSE for license information
 *
 * Milestone 1 goal (see documentation/effects-journal.md):
 *   - `effect Name { fun op(...) : T ... }` parses at top level
 *   - `handle Name { arm, ... } in { body }` parses as an expression
 *   - Both compile to valid Koka via emit-program
 *   - Checker is lenient (Mode B): op names are registered, no exhaustiveness yet
 *
 * These tests are RED at the start of M1 and should turn green step by step
 * as the sequence in the journal is followed.
*/
import kunit
import syntax/ast
import syntax/lexer
import syntax/parser
import semantics/checker
import diagnostics/diagnostics
import emit/codegen
import transform/desugar

// ---- Helpers (mirrors of the ones in test-codegen.kk / test-parser.kk) -----

fun token-string( source : string ) : div string
  lex(source).map(fn(t) t.kind.show).join(" ")

// Structural check: does the first non-EOF token have the given kind?
// We use match on the actual token-kind variant, not the show string,
// because TkIdent("effect") and TkEffect both render as "effect".
fun first-kind-is-effect-kw( source : string ) : div bool
  match lex(source)
    Cons(t, _) -> match t.kind
      TkEffect -> True
      _        -> False
    _ -> False

fun first-kind-is-handle-kw( source : string ) : div bool
  match lex(source)
    Cons(t, _) -> match t.kind
      TkHandle -> True
      _        -> False
    _ -> False

fun parse-program-show( source : string ) : <div,console> string
  val tokens = lex(source)
  val prog = run-parser-program(tokens)
  prog.show

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

fun check-diagnostic-count( source : string ) : <div,console> int
  val tokens = lex(source)
  val prog = run-parser-program(tokens)
  val desugared = desugar-program(prog)
  val (_, ds) = collect-diagnostics
    run-fresh
      check-program(desugared)
  ds.length

fun parse-error-count( source : string ) : div int
  val tokens = lex(source)
  val (_, errs) = run-parser-program-with-errors(tokens)
  errs.length

// ---- Sample source: the canonical M1 "Log" example ------------------------
// (Kept on one line with explicit \n — Koka string literals do not span lines.)

val log-src = "effect Log {\n  fun info(s: string)\n}\n\nfun greet(name: string) {\n  info(\"hello, \" + name)\n}\n\nfun main() {\n  handle Log {\n    info(s) => println(\"[LOG] \" + s)\n  } in {\n    greet(\"world\")\n    greet(\"effects\")\n  }\n}\n"

// ---------------------------------------------------------------------------

pub fun main() : io ()
  println(bold("Effects tests (M1)"))
  println("")
  defaultKDivHandler
    // --- (a) Lexer knows the new keywords ------------------------------
    // NOTE: We MUST pattern-match on the token kind, not on the printed
    // form, because TkIdent("effect") shows as "effect" too — that would
    // give a false green until TkEffect exists as its own variant.
    dtest("lex: 'effect' keyword produces TkEffect")
      assert/is-true(first-kind-is-effect-kw("effect"))

    dtest("lex: 'handle' keyword produces TkHandle")
      assert/is-true(first-kind-is-handle-kw("handle"))

    dtest("lex: 'effect handle' — both new keywords together")
      val toks = lex("effect handle")
      val second-is-handle = match toks
        Cons(_, Cons(t2, _)) -> match t2.kind
          TkHandle -> True
          _        -> False
        _ -> False
      assert/is-true(first-kind-is-effect-kw("effect handle") && second-is-handle)

    // --- (b) Parser accepts a minimal effect declaration ---------------
    dtest("parse: minimal effect declaration")
      val src = "effect Log { fun info(s: string) }"
      // no parse errors
      assert/is-true(parse-error-count(src) == 0)

    dtest("parse: effect declaration with multiple ops")
      val src = "effect Term {\n  fun read_key() : int\n  fun write(s: string)\n  fun clear()\n}"
      assert/is-true(parse-error-count(src) == 0)

    // --- (c) Parser accepts a minimal handle expression ----------------
    dtest("parse: minimal handle expression in main")
      val src = "fun main() {\n  handle Log {\n    info(s) => println(s)\n  } in {\n    info(\"hi\")\n  }\n}"
      assert/is-true(parse-error-count(src) == 0)

    // --- (d) End-to-end: the Log example emits well-formed Koka --------
    dtest("codegen: Log example emits 'effect log' block")
      val kk = emit-program-show(log-src)
      assert/is-true(kk.contains("effect log"))

    dtest("codegen: Log example emits an op declaration for 'info'")
      val kk = emit-program-show(log-src)
      assert/is-true(kk.contains("info"))

    dtest("codegen: Log example emits a 'with handler' block")
      val kk = emit-program-show(log-src)
      assert/is-true(kk.contains("with handler"))

    // --- Checker leniency (Mode B) -------------------------------------
    dtest("check: op call inside handler is not flagged as undefined")
      // With Mode B, the op registry avoids the false 'undefined variable'
      // for known operations. We tolerate diagnostics from OTHER sources
      // by only asserting the specific one we care about is absent.
      val tokens = lex(log-src)
      val prog = run-parser-program(tokens)
      val desugared = desugar-program(prog)
      val (_, ds) = collect-diagnostics
        run-fresh
          check-program(desugared)
      val undefined-info = ds.any(fn(d) d.message.contains("undefined") && d.message.contains("info"))
      assert/is-true(!undefined-info)

    // --- M2: exhaustiveness -------------------------------------------
    // Handler that forgets an op should surface a hica-level error that
    // names the effect AND the missing op, not a Koka error.
    dtest("check: missing op reported with effect + op names")
      val src = "effect Log2 {\n  fun info(s: string)\n  fun warn(s: string)\n}\nfun main() {\n  handle Log2 { info(s) => println(s) } in { info(\"hi\") }\n}"
      val tokens = lex(src)
      val prog = run-parser-program(tokens)
      val desugared = desugar-program(prog)
      val (_, ds) = collect-diagnostics
        run-fresh
          check-program(desugared)
      val hit = ds.any(fn(d) d.message.contains("missing operation 'warn'") && d.message.contains("Log2"))
      assert/is-true(hit)

    // Handler arm that names an op the effect does not declare should
    // surface an "'X' is not an operation of effect 'Y'" error.
    dtest("check: unknown-op arm reported with effect name")
      val src = "effect Log3 {\n  fun info(s: string)\n}\nfun main() {\n  handle Log3 {\n    info(s)  => println(s),\n    debug(s) => println(s)\n  } in {\n    info(\"hi\")\n  }\n}"
      val tokens = lex(src)
      val prog = run-parser-program(tokens)
      val desugared = desugar-program(prog)
      val (_, ds) = collect-diagnostics
        run-fresh
          check-program(desugared)
      val hit = ds.any(fn(d) d.message.contains("'debug' is not an operation of effect 'Log3'"))
      assert/is-true(hit)

    // Two arms for the same op must produce a "handled twice" error.
    dtest("check: duplicate arm reported")
      val src = "effect Log4 {\n  fun info(s: string)\n}\nfun main() {\n  handle Log4 {\n    info(s) => println(s),\n    info(s) => println(s)\n  } in {\n    info(\"hi\")\n  }\n}"
      val tokens = lex(src)
      val prog = run-parser-program(tokens)
      val desugared = desugar-program(prog)
      val (_, ds) = collect-diagnostics
        run-fresh
          check-program(desugared)
      val hit = ds.any(fn(d) d.message.contains("operation 'info' is handled twice"))
      assert/is-true(hit)

    // `handle` on an effect that was never declared: report the
    // unknown-effect error with the offending name.
    dtest("check: unknown effect reported with name")
      val src = "fun main() {\n  handle Terminal {\n    write(s) => println(s)\n  } in {\n    ()\n  }\n}"
      val tokens = lex(src)
      val prog = run-parser-program(tokens)
      val desugared = desugar-program(prog)
      val (_, ds) = collect-diagnostics
        run-fresh
          check-program(desugared)
      val hit = ds.any(fn(d) d.message.contains("unknown effect: 'Terminal'"))
      assert/is-true(hit)

    // --- M4: call-site effect-row enforcement ------------------------
    // A callback ref whose declared effect leak set is a subset of the
    // callee param's row passes cleanly. See db-sandbox.hc for the full
    // motivator example; here we keep it minimal.
    dtest("check: callback with matching row is accepted (M4)")
      val src = "effect Db {\n  fun q() : int\n}\npub fun with_db(f: () -> <Db> int) : int {\n  handle Db { q() => 1 } in { f() }\n}\nfun ok_cb() : <Db> int { q() }\nfun main() {\n  let n = with_db(ok_cb)\n  println(n)\n}"
      val tokens = lex(src)
      val prog = run-parser-program(tokens)
      val desugared = desugar-program(prog)
      val (_, ds) = collect-diagnostics
        run-fresh
          check-program(desugared)
      val errors = ds.filter(fn(d) match d.severity { Error -> True; _ -> False })
      assert/is-true(errors.is-empty)

    // A callback ref that leaks an effect *not* in the callee param's
    // row is rejected at the argument site with the hica-level
    // `effect row mismatch` error naming the offending row.
    dtest("check: callback with extra effect is rejected (M4)")
      val src = "effect Db {\n  fun q() : int\n}\neffect Fs2 {\n  fun r() : string\n}\npub fun with_db(f: () -> <Db> int) : int {\n  handle Db { q() => 1 } in { f() }\n}\nfun leaky() : int {\n  let s = r()\n  0\n}\nfun main() {\n  let n = with_db(leaky)\n  println(n)\n}"
      val tokens = lex(src)
      val prog = run-parser-program(tokens)
      val desugared = desugar-program(prog)
      val (_, ds) = collect-diagnostics
        run-fresh
          check-program(desugared)
      val hit = ds.any(fn(d) d.message.contains("effect row mismatch") && d.message.contains("Fs2") && d.message.contains("<Db>"))
      assert/is-true(hit)

    // --- M4.5: stdlib name-collision guard ----------------------------
    // Effect ops whose names collide with hardcoded codegen intercepts
    // (e.g. `exec` → `run-system-read`, `write` → `write-text-file`, …)
    // must be emitted as `hc_<name>` so the stdlib arms don't hijack
    // them. The checker tags every effect-op call site with an
    // `hc-op:` prefix; codegen's `marshal-name` strips it back to the
    // regular `hc_` marshalling path. See documentation/effects-journal.md
    // M4.5 for the trade-off.
    dtest("codegen: effect op named 'exec' emits as hc_exec (M4.5)")
      val src = "effect Db {\n  fun exec(sql: string)\n}\nfun main() {\n  handle Db {\n    exec(sql) => println(sql)\n  } in {\n    exec(\"SELECT 1\")\n  }\n}"
      val kk = emit-typed-program(src)
      // The op declaration should carry the hc_ prefix.
      val decl-ok = kk.contains("ctl hc_exec")
      // The call site should be marshalled to hc_exec(...) — NOT the
      // stdlib arm `run-system-read(...)`.
      val call-ok = kk.contains("hc_exec(") && !kk.contains("run-system-read")
      assert/is-true(decl-ok && call-ok)

    // --- M5: stateful handlers (`with var …`) ------------------------
    // A single-var state binding is hoisted before `with handler`, and each
    // arm body that mutates state is emitted as a leading statement followed
    // by `resume(())`. See design doc §7.4 and examples/effects/counter.hc.
    dtest("codegen: stateful handler hoists var and splits assign-arm (M5)")
      val src = "effect Counter {\n  fun incr()\n  fun get() : int\n}\nfun main() {\n  let n = handle Counter {\n    incr() => count = count + 1,\n    get()  => count\n  } with var count = 0 in {\n    incr()\n    incr()\n    incr()\n    get()\n  }\n  println(n)\n}"
      val kk = emit-typed-program(src)
      // State variable is hoisted as `var count := 0` before `with handler`.
      val has-var = kk.contains("var count := 0")
      // The mutating arm splits `count := (count + 1)` and `resume(())`.
      val split-ok = kk.contains("count := (count + 1)") && kk.contains("resume(())")
      // The IIFE wrapper appears because the handle is in expression
      // position (`let n = handle …`).
      val iife-ok = kk.contains("(fn()") && kk.contains(")()")
      assert/is-true(has-var && split-ok && iife-ok)

    // A pure-expression arm body still emits the compact single-line form.
    dtest("codegen: pure-expression arm stays compact (M5)")
      val src = "effect Counter {\n  fun get() : int\n}\nfun main() {\n  let n = handle Counter { get() => 42 } with var count = 0 in { get() }\n  println(n)\n}"
      val kk = emit-typed-program(src)
      // Compact form: no newline between `->` and `resume(42)`.
      assert/is-true(kk.contains("ctl hc_get() -> resume(42)"))

    // M5.5 — match-shaped op body (e.g. Buffer.pop) can't sit directly inside
    // `resume(...)` because Koka's layout parser hits the trailing `)` before
    // the inner block closes. Fix: hoist the match to a local `val`, then
    // `resume(val)`. See examples/effects/buffer.hc and the M5.5 milestone
    // in documentation/effects-journal.md.
    dtest("codegen: match-shaped op body is hoisted to val + resume(val) (M5.5)")
      val src = "effect Buffer {\n  fun pop() : maybe<int>\n  fun push(x: int)\n}\nfun main() {\n  let n = handle Buffer {\n    push(x) => items = items + [x],\n    pop() => match items {\n      [] => None,\n      [x, ..rest] => { items = rest; Some(x) }\n    }\n  } with var items = [1, 2, 3] in {\n    pop()\n  }\n  println(n)\n}"
      val kk = emit-typed-program(src)
      // The hoisted local uses the op name as the val suffix: `hc__pop_res`.
      val has-hoist = kk.contains("val hc__pop_res =")
      val resumes-local = kk.contains("resume(hc__pop_res)")
      // Guard against the pre-M5.5 shape: `resume(match items`.
      val no-inline-match = !kk.contains("resume(match ")
      assert/is-true(has-hoist && resumes-local && no-inline-match)

    // --- M6: actor keyword desugars to effect + helper ---------------
    // `actor Counter { var count = 0; receive(msg: CounterMsg) => … }`
    // expands to two top-level items: an `effect Counter { fun
    // send_counter(msg: CounterMsg) }` declaration, and a
    // `pub fun with_counter(action) { … }` helper that installs the
    // handler with `with var count = 0` and calls `action()`. The op
    // name is `send_<name>` (Option A / design doc §13.4) so multiple
    // actors in the same file coexist without namespace collision.
    dtest("codegen: actor Counter emits effect + hc_with_counter helper (M6)")
      val src = "type CounterMsg { Incr, Decr }\nactor Counter {\n  var count = 0\n  receive(msg: CounterMsg) => match msg { Incr => count = count + 1, Decr => count = count - 1 }\n}\nfun main() {\n  with_counter(() => { send_counter(Incr) })\n}"
      val kk = emit-typed-program(src)
      // Effect block for the actor. Effect name is lowercased (matches
      // the M1 rule) and the op carries the hc_ prefix (M4.5 rule).
      val has-effect = kk.contains("effect counter") && kk.contains("ctl hc_send_counter")
      // Helper is emitted as `pub fun hc_with_counter(action)`.
      val has-helper = kk.contains("pub fun hc_with_counter(action)")
      // Handler body carries the state hoist and the `send_counter` arm.
      val has-state  = kk.contains("var count := 0")
      val has-arm    = kk.contains("ctl hc_send_counter(msg)")
      assert/is-true(has-effect && has-helper && has-state && has-arm)

    // A minimal, isolated regression on the name-collision fix from M6:
    // two actors with different message types must produce two effect
    // blocks and two distinct helpers, without op-name overlap.
    //
    // Note: actor names have to be multi-letter here — a single-letter
    // effect name would be lowercased to `a` in Koka, and Koka's
    // parser treats a single lowercase letter as a type-variable name
    // (not an effect name). Filed as a follow-up (see M6 log).
    dtest("codegen: two actors produce distinct send_<name> ops (M6)")
      val src = "type FooMsg { F1 }\ntype BarMsg { B1 }\nactor Foo { var x = 0; receive(m: FooMsg) => match m { F1 => x = 1 } }\nactor Bar { var y = 0; receive(m: BarMsg) => match m { B1 => y = 1 } }\nfun main() { with_foo(() => send_foo(F1)); with_bar(() => send_bar(B1)) }"
      val kk = emit-typed-program(src)
      val ok-foo = kk.contains("ctl hc_send_foo(m)") && kk.contains("pub fun hc_with_foo(action)")
      val ok-bar = kk.contains("ctl hc_send_bar(m)") && kk.contains("pub fun hc_with_bar(action)")
      assert/is-true(ok-foo && ok-bar)

    // --- M6.5: single-letter effect / actor names rejected -----------
    // Koka's parser treats a single lowercase identifier at the
    // effect-header position as a *type variable*, so `effect A { … }`
    // in hica lowers to `effect a` in Koka and fails with the opaque
    // "expected type name (and not type variable)" error. M6.5 catches
    // this at hica-check time with a targeted message. Also covers
    // the `actor` sugar because actor names lower to effect names.
    dtest("check: single-letter effect name is rejected (M6.5)")
      val src = "effect A { fun ping() }\nfun main() { handle A { ping() => println(\"pong\") } in { ping() } }"
      val tokens = lex(src)
      val prog = run-parser-program(tokens)
      val desugared = desugar-program(prog)
      val (_, ds) = collect-diagnostics
        run-fresh
          check-program(desugared)
      val hit = ds.any(fn(d) d.message.contains("too short") && d.message.contains("'A'"))
      assert/is-true(hit)

    dtest("check: single-letter actor name is rejected (M6.5)")
      val src = "type MMsg { Ping }\nactor M { var count = 0; receive(msg: MMsg) => match msg { Ping => count = count + 1 } }\nfun main() { with_m(() => send_m(Ping)) }"
      val tokens = lex(src)
      val prog = run-parser-program(tokens)
      val desugared = desugar-program(prog)
      val (_, ds) = collect-diagnostics
        run-fresh
          check-program(desugared)
      val hit = ds.any(fn(d) d.message.contains("too short") && d.message.contains("'M'"))
      assert/is-true(hit)

    // Multi-letter names still pass — the exact opposite of the check.
    // A regression here would mean the new check has become too eager.
    dtest("check: two-letter effect name is accepted (M6.5)")
      val src = "effect Ab { fun ping() }\nfun main() { handle Ab { ping() => println(\"pong\") } in { ping() } }"
      val tokens = lex(src)
      val prog = run-parser-program(tokens)
      val desugared = desugar-program(prog)
      val (_, ds) = collect-diagnostics
        run-fresh
          check-program(desugared)
      val name-too-short-hit = ds.any(fn(d) d.message.contains("too short"))
      assert/is-true(!name-too-short-hit)



