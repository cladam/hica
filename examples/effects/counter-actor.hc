// hica — M6 actor sugar: single-actor counter.
//
// `actor Counter { … }` desugars into TWO top-level items:
//
//   1. effect Counter { fun send_counter(msg: CounterMsg) : () }
//   2. pub fun with_counter(action) {
//        handle Counter {
//          send_counter(msg) => <receive body>
//        } with var count = 0 in {
//          action()
//        }
//      }
//
// Inside the callback passed to `with_counter`, `send_counter(m)` is
// like Erlang's `Actor ! Msg`: fire-and-forget dispatch to the actor
// whose state and receive-body were declared above. The state is
// scoped to the `with_counter` call — every invocation gets a fresh
// counter starting at zero.
//
// Design spec: documentation/effects-design.md §11.4 / §13.4.
//
// Expected output:
//   [counter] Incr → 1
//   [counter] Incr → 2
//   [counter] Incr → 3
//   [counter] Decr → 2
//   [counter] Reset → 0
//   [counter] Incr → 1
//   done
//
// Run:
//   hica run examples/effects/counter-actor.hc

type CounterMsg { Incr, Decr, Reset }

actor Counter {
  var count = 0

  receive(msg: CounterMsg) => match msg {
    Incr  => {
      count = count + 1
      println("[counter] Incr → {show(count)}")
    },
    Decr  => {
      count = count - 1
      println("[counter] Decr → {show(count)}")
    },
    Reset => {
      count = 0
      println("[counter] Reset → 0")
    }
  }
}

fun main() {
  with_counter(() => {
    send_counter(Incr)
    send_counter(Incr)
    send_counter(Incr)
    send_counter(Decr)
    send_counter(Reset)
    send_counter(Incr)
    println("done")
  })
}
