// hica — N3 named effects: a pool of independent Counter instances
//
// Each worker is a fresh `spawn Counter { … } as wN` — an independent
// instance with its own state. The `bump` helper takes a `ref<Counter>`
// argument, showing that references are first-class values that can be
// passed to functions (design doc §4.4 and §5.5).
//
// After `bump` runs 5×, 3×, 7× on w1/w2/w3, each worker's `get()` returns
// its own count.
//
// See documentation/named-effects-design.md §4.4, §5.5 and §13.2, and
// documentation/named-effects-journal.md N3.

effect Counter {
  fun incr()
  fun get() : int
}

// A helper that dispatches on a `ref<Counter>` parameter. The `ref<E>`
// type is the first-class handle to a named-effect instance. Callers pass
// it in like any other value; hica's checker unifies it nominally
// (design doc §7.4 — Koka spells the same idea as `ev<E>`).
fun bump(c: ref<Counter>, n: int) {
  if n > 0 {
    c.incr()
    bump(c, n - 1)
  }
}

fun report(c: ref<Counter>) {
  println("worker = {show(c.get())}")
}

fun main() {
  spawn Counter {
    incr() => count = count + 1,
    get() => count
  } with var count = 0 as w1

  spawn Counter {
    incr() => count = count + 1,
    get() => count
  } with var count = 0 as w2

  spawn Counter {
    incr() => count = count + 1,
    get() => count
  } with var count = 0 as w3

  // Each worker keeps its own state — no interference between spawns.
  bump(w1, 5)
  bump(w2, 3)
  bump(w3, 7)

  // Direct dispatch also works.
  w1.incr()

  report(w1)   // worker = 6
  report(w2)   // worker = 3
  report(w3)   // worker = 7
}
