// hica — smoke test: handler missing an operation
//
// The `Log` effect declares two operations, `info` and `warn`. The handler
// below only implements `info` — the checker should reject it with a
// hica-level error before Koka ever runs.
//
// Expected error:
//   error: handler for effect 'Log' is missing operation 'warn'
//
// Run:
//   hica check examples/effects/log-missing-op.hc
// Or:
//   hica build examples/effects/log-missing-op.hc

effect Log {
  fun info(s: string)
  fun warn(s: string)
}

fun main() {
  handle Log {
    info(s) => println("[INFO] " + s)
  } in {
    info("hello")
  }
}
