// hica — smoke test: `handle` on an effect that was never declared
//
// There is no `Terminal` effect in this file. The checker should reject the
// `handle Terminal { ... }` expression with an "unknown effect" error.
//
// Expected error:
//   error: unknown effect: 'Terminal'
//
// Run:
//   hica check examples/effects/log-unknown-effect.hc

fun main() {
  handle Terminal {
    write(s) => println(s)
  } in {
    write("hello")
  }
}
