// learn/48-named-effects.hc — Named effects v2: spawn + ref.op() dispatch
//
// This tutorial builds on learn/44-effects-intro.hc, learn/45-effects-state.hc
// and learn/47-effects-actors.hc — read those first if you haven't.
//
// v1 gave us `handle Name { … } in { body }` — one handler per scope. That's
// enough for capability sandboxes and one-shot state, but breaks down the
// moment you want two independent instances of the same effect in the same
// function. v2 fixes that with three new pieces of surface syntax:
//
//   1. `spawn Name { arms } (with var …)? as ref`
//        — install a fresh handler instance and bind the reference to `ref`.
//   2. `ref.op(args)` — per-instance dispatch. Each spawn's state is fully
//        isolated; two counters with the same effect keep their own count.
//   3. `ref<Name>` — the first-class type of an instance reference
//        (parser support in N3, checker-tag for N2).
//
// See documentation/named-effects-design.md for the full design.

// ---- Setup: a Counter effect ----------------------------------------------

effect Counter {
  fun incr()
  fun get() : int
}

// ---- Test 1: two independent counter instances ----------------------------
//
// Under v1 you could only have ONE Counter handler in scope at a time.
// With `spawn … as ref`, each spawn produces a distinct instance:

test "two counters keep separate state" {
  spawn Counter {
    incr() => count = count + 1,
    get() => count
  } with var count = 0 as c1

  spawn Counter {
    incr() => count = count + 1,
    get() => count
  } with var count = 100 as c2

  c1.incr()
  c1.incr()
  c1.incr()

  c2.incr()

  assert_eq(3, c1.get())
  assert_eq(101, c2.get())
}

// ---- Test 2: ref.op() dispatches on the reference ------------------------
//
// The receiver of `ref.op()` is the *reference*, not any lexical handler.
// A spawned instance's arms see only *that* instance's state — even when
// two instances share the same effect declaration.

test "dispatch routes to the correct instance" {
  spawn Counter {
    incr() => count = count + 1,
    get() => count
  } with var count = 0 as a

  spawn Counter {
    incr() => count = count + 1,
    get() => count
  } with var count = 0 as b

  a.incr()
  b.incr()
  b.incr()

  // Two increments on `b`, one on `a` — totally isolated.
  assert_eq(1, a.get())
  assert_eq(2, b.get())
}

// ---- Test 3: dispatch order across instances ------------------------------
//
// Method-call order is straightforward — each `ref.op()` runs the arm body
// against the referenced instance's state, then returns.

test "interleaved dispatch preserves per-instance order" {
  spawn Counter {
    incr() => count = count + 1,
    get() => count
  } with var count = 0 as x

  spawn Counter {
    incr() => count = count + 1,
    get() => count
  } with var count = 10 as y

  x.incr()   // x = 1
  y.incr()   // y = 11
  x.incr()   // x = 2
  y.incr()   // y = 12
  x.incr()   // x = 3

  assert_eq(3, x.get())
  assert_eq(12, y.get())
}
