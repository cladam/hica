// hica — stateful handlers (`with var …`)
//
// A handler can carry local mutable state via the `with var …` clause.
// State bindings are hoisted above the `with handler` block, so every op
// arm and the `in { … }` body share the same mutable references. When the
// `in` block returns, the state is dropped.
//
// This example implements a simple counter:
//   * `incr()`   — bump the count by one
//   * `decr()`   — decrement the count by one
//   * `get()`    — read the current count
//
// The handler installs a fresh `count = 0` for each invocation. 
//
// Expected output:
//   final = 2
//
// Run:
//   hica run examples/effects/counter.hc

effect Counter {
  fun incr()
  fun decr()
  fun get() : int
}

fun main() {
  let n = handle Counter {
    incr() => count = count + 1,
    decr() => count = count - 1,
    get()  => count
  } with var count = 0 in {
    incr()
    incr()
    incr()
    decr()
    get()
  }
  println("final = {show(n)}")
}
