// hica — First-Class Actor stdlib enhancements test
//
// Showcases the newly added `send` and `ask` helper functions in "std/actor"
// working perfectly with first-class actor syntax.

import "std/actor"

type CounterMsg {
  Increment,
  Decrement,
  GetCount
}

actor Counter {
  var count = 0

  receive(msg: CounterMsg) => match msg {
    Increment => {
      count = count + 1;
      println("  [Counter] Incremented to {count}")
    }
    Decrement => {
      count = count - 1;
      println("  [Counter] Decremented to {count}")
    }
    GetCount => {
      // Just a dummy to return the state, query is processed via ask projection
      println("  [Counter] Querying count...")
    }
  }
}

fun main() {
  let init_state = CounterState { count: 10 }

  println("Initial State count: {init_state.count}")

  // Test `send` (fire-and-forget, returns unit)
  println("Sending Increment via stdlib 'send'...")
  let s1 = send(init_state, Increment, counter_receive)
  // s1 is of type ()

  // Test `ask` (request-reply, extracts projected field)
  println("Querying state count via stdlib 'ask'...")
  let current_val = ask(init_state, GetCount, counter_receive, (state) => state.count)
  println("Ask returned value: {show(current_val)}")
}
