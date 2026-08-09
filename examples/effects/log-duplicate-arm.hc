// hica — M2 smoke test: handler with a duplicate arm
//
// The `Log` effect declares one operation, `info`. The handler below has two
// arms for `info` — the checker should reject the second one.
//
// Expected error (per documentation/effects-design.md §5.2):
//   error: operation 'info' is handled twice
//
// Run:
//   hica check examples/effects/log-duplicate-arm.hc

effect Log {
  fun info(s: string)
}

fun main() {
  handle Log {
    info(s) => println("[INFO A] " + s),
    info(s) => println("[INFO B] " + s)
  } in {
    info("world")
  }
}
