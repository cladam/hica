// Hica — Actor pattern: Counter
//
// Demonstrates the actor-as-state-machine pattern:
//   1. Define message types as enums
//   2. Define a receive function with exhaustive match
//   3. Process messages through state transitions
//
// This gives compile-time safety: if you add a message variant
// and forget to handle it, the compiler warns you.

import "std/actor"

// --- Message types ---

type CounterMsg {
  Increment,
  Decrement,
  Reset
}

// --- The receive function (actor behavior) ---

fun counter_receive(state: int, msg: CounterMsg) : int => match msg {
  Increment => state + 1,
  Decrement => state - 1,
  Reset     => 0
}

// --- Using the actor ---

fun main() {
  // Process a mailbox of messages
  let messages = [Increment, Increment, Increment, Decrement, Reset, Increment]
  let final_state = process_messages(0, messages, counter_receive)
  println("Counter after mailbox: {final_state}")

  // Multiple independent actors with different initial states
  let counter_a = process_messages(0, [Increment, Increment, Increment], counter_receive)
  let counter_b = process_messages(100, [Decrement, Decrement], counter_receive)
  println("Counter A: {counter_a}")
  println("Counter B: {counter_b}")
}
