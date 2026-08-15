// hica — named-effects: single-actor counter, no callback wrapper.
//
// This example demonstrates the flat-block style: `spawn` binds `counter`
// for the rest of the enclosing block, then subsequent statements dispatch
// on it.
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
    Incr => { }
    Decr => { }
    Reset => { }
  }
}

fun main() {
  spawn Counter {
    send(msg) => match msg {
      Incr => {
        count = count + 1
        println("[counter] Incr → {show(count)}")
      },
      Decr => {
        count = count - 1
        println("[counter] Decr → {show(count)}")
      },
      Reset => {
        count = 0
        println("[counter] Reset → 0")
      }
    }
  } with var count = 0 as counter

  counter.send(Incr)
  counter.send(Incr)
  counter.send(Incr)
  counter.send(Decr)
  counter.send(Reset)
  counter.send(Incr)
  println("done")
}
