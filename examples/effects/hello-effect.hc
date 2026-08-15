// hica — effects smoke test
//
// Declares a tiny `Log` effect with one op, calls it from a helper, and
// installs a handler at the top of `main` that discharges the effect by
// printing to stdout with a "[LOG]" prefix.
//

effect Log {
  fun info(s: string)
}

fun greet(name: string) {
  info("hello, " + name)
}

fun main() {
  handle Log {
    info(s) => println("[LOG] " + s)
  } in {
    greet("world")
    greet("effects")
  }
}
