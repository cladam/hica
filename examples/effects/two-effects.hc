// hica — N4 named effects: two effects, two spawn instances, one call chain
//
// This example demonstrates that `hica check` correctly reports a cross-effect
// row (`[<Counter, Log>]`) when a program spawns instances of two different
// effects and calls both through a single helper.
//
// The `step` helper takes two references — one per effect — and dispatches
// on both. `hica check` should see `Counter` and `Log` in the reported row,
// alongside `console` for the `println` calls inside the Log arm.
//
// See documentation/named-effects-design.md §11.1 (interactions), and
// documentation/named-effects-journal.md N4.

effect Counter {
  fun incr()
  fun get() : int
}

effect Log {
  fun info(s: string)
}

// A helper that dispatches on two different ref types. The `<Counter, Log>`
// obligation is what `hica check` should report on the enclosing function.
fun step(c: ref<Counter>, l: ref<Log>, msg: string) {
  c.incr()
  l.info(msg)
}

fun main() {
  spawn Counter {
    incr() => count = count + 1,
    get() => count
  } with var count = 0 as c

  spawn Log {
    info(s) => println("[LOG] " + s)
  } as l

  step(c, l, "bump 1")
  step(c, l, "bump 2")
  step(c, l, "bump 3")

  println("final counter = {show(c.get())}")
}
