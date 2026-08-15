// hica — named effects: two independent Counter instances
//
// Each `spawn Counter { … } as cN` binds a fresh reference. `cN.incr()`
// and `cN.get()` dispatch on the reference — the counters keep their
// state fully isolated.
//

effect Counter {
  fun incr()
  fun get() : int
}

fun main() {
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

  println("c1 = {show(c1.get())}")   // c1 = 3
  println("c2 = {show(c2.get())}")   // c2 = 101
}
