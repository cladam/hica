// hica — smoke test: arm-param typing against the op signature
//
// In this example the `Counter` effect declares `add(n: int)`; the handler's
// `add(n) => count = count + n` arm uses `n` in an integer expression and
// the checker resolves `n : int` from the op signature.
//
// This program should print:
//   final = 6
//
// Run:
//   hica run examples/effects/counter-typed-ops.hc

effect Counter {
  fun add(n: int)
  fun get() : int
}

fun main() {
  let final = handle Counter {
    add(n) => count = count + n,
    get()  => count
  } with var count = 0 in {
    add(1)
    add(2)
    add(3)
    get()
  }
  println("final = {show(final)}")
}
