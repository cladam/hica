// hica — smoke test: arm-param typing from the op signature
//
// The `Greet` effect declares `hello(name: string) : string`. The handler
// binds the arm parameter simply as `name` — no user-supplied annotation.
//
// This program should print:
//   hello, world
//   hello, effects
//
// Run:
//   hica run examples/effects/greet-typed-op.hc

effect Greet {
  fun hello(name: string) : string
}

fun main() {
  handle Greet {
    hello(name) => "hello, " + name
  } in {
    println(hello("world"))
    println(hello("effects"))
  }
}
