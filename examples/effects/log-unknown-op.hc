// hica — M2 smoke test: handler names an operation the effect does not have
//
// `Log` declares one operation, `info`. The handler below adds an arm for
// `debug` — the checker should reject it because `debug` is not part of the
// `Log` effect.
//
// Expected error (per documentation/effects-design.md §4.3):
//   error: 'debug' is not an operation of effect 'Log'
//
// Run:
//   hica check examples/effects/log-unknown-op.hc

effect Log {
  fun info(s: string)
}

fun main() {
  handle Log {
    info(s)  => println("[INFO] " + s),
    debug(s) => println("[DEBUG] " + s)
  } in {
    info("ok")
  }
}
