// hica — N1 named effects (experimental): two independent Counter instances
//
// Two `spawn Counter { … } as c1|c2` handlers coexist in a single function.
// Each instance carries its own `count` state. Parsing + codegen for the
// `spawn`/`ref<E>` shape landed in N1; per-instance method dispatch
// (`c1.incr()`, `c1.get()`) lands in N2. Until then, this file only exercises
// the parser + codegen pipeline.
//
// See documentation/named-effects-design.md §4.2 and
// documentation/named-effects-journal.md N1.
//
// Run (once N2 lands):
//   hica run examples/effects/two-counters.hc

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

  println("N1: spawn parses and emits named-handler Koka")
}
