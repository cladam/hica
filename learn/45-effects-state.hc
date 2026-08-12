// learn/45-effects-state.hc — stateful handlers (`with var …`)
//
// Prerequisites: learn/44-effects-intro.hc (basic effects + handlers).
//
// This tutorial covers the M5 addition to the effects surface: handler-local
// mutable state via the `with var …` clause. It's what lets a handler count
// events, buffer values, or keep a running total — without any global `var`,
// class field, or ambient reference.
//
// Every state binding is scoped to the surrounding `handle … in { … }`
// expression: it dies when the block returns. This means every invocation
// of a handler gets a fresh, clean state, which is exactly what makes handler
// stacks so much easier to reason about than global mutable variables.
//
// Run:
//   hica test learn/45-effects-state.hc
//
// See also:
//   - examples/effects/counter.hc  — minimal single-var example
//   - docs/effects.md              — user guide
//   - documentation/effects-design.md §4.4 / §7.4 — design spec

// ---------------------------------------------------------------------------
// 1. The Counter effect
// ---------------------------------------------------------------------------
//
// This is the classical example: two mutating operations (`incr`/`decr`) plus
// one observing one (`get`).

effect Counter {
  fun incr()
  fun decr()
  fun get() : int
}

// A pure helper that only requires the Counter capability — no IO, no logic
// about how counting is *implemented*. That decision lives at the handler.
fun bump_three_and_read() : <Counter> int {
  incr()
  incr()
  incr()
  get()
}

// ---------------------------------------------------------------------------
// 2. Installing the handler with initial state
// ---------------------------------------------------------------------------
//
// `with var count = 0` declares one mutable binding, hoisted before the
// `with handler` block. All arm bodies and the `in { … }` block share it.
//
// The counter starts at zero. Each call to `incr()` runs the arm body:
//   count = count + 1
// which is a single-statement assignment. hica lifts the assignment *out*
// of the handler's `resume(…)` so the mutation actually runs — the arm
// returns `()` via the implicit resume.

fun default_counter() : int {
  handle Counter {
    incr() => count = count + 1,
    decr() => count = count - 1,
    get()  => count
  } with var count = 0 in {
    bump_three_and_read()
  }
}

test "default counter starts at 0 and reaches 3 after three bumps" {
  assert_eq(3, default_counter())
}

// ---------------------------------------------------------------------------
// 3. Fresh state per invocation
// ---------------------------------------------------------------------------
//
// Each `handle … in { … }` invocation gets its own `count = 0`. There is no
// "counter singleton" — the state binding is scoped to the handler expression,
// not to the process.

test "each handler invocation gets a fresh count" {
  let a = default_counter()
  let b = default_counter()
  assert_eq(a, b)          // both start at 0 → both return 3
  assert_eq(3, a + b - 3)  // sanity — not aliasing anything
}

// ---------------------------------------------------------------------------
// 4. Non-zero starting state
// ---------------------------------------------------------------------------
//
// `with var count = <expr>` accepts any expression, so you can seed the
// counter with a value carried in from the surrounding scope.

fun run_counter_from(start: int, ops: int) : int {
  handle Counter {
    incr() => count = count + 1,
    decr() => count = count - 1,
    get()  => count
  } with var count = start in {
    repeat(ops) {
      incr()
    }
    get()
  }
}

test "seed the counter with a non-zero starting value" {
  assert_eq(105, run_counter_from(100, 5))
}

// ---------------------------------------------------------------------------
// 5. Testability: no globals means no reset dance
// ---------------------------------------------------------------------------
//
// Because the state lives inside the handler expression, tests never need
// a `beforeEach` step to reset a shared counter. Every test constructs the
// handler fresh, and there is no observable ordering between them.
//
// This is the everyday version of the design doc's point (§2.1) about the
// terminal editor: putting side effects behind an effect makes the logic
// trivially testable, because the logic never talks to any global state.

test "counters are independent even when called in the same test" {
  let a = run_counter_from(0, 10)
  let b = run_counter_from(0, 5)
  assert_ne(a, b)          // 10 vs 5 — no cross-talk
}
