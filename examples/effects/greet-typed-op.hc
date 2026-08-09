// hica — M2 smoke test: arm-param typing from the op signature
//
// The `Greet` effect declares `hello(name: string) : string`. The handler
// binds the arm parameter simply as `name` — no user-supplied annotation.
//
// M2's checker unifies the arm's parameters against the declared op
// signature, so inside the arm body `name` is already typed as `string`
// and the concatenation `"hello, " + name` type-checks cleanly.
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
