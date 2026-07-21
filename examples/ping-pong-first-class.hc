// hica — First-Class Actor syntax example: Ping-Pong
//
// Demonstrates Step 5 concept (two actors communicating)
// using the newly introduced first-class `actor` syntax.

import "std/actor"

type PingerMsg {
  Pong
}

type PongerMsg {
  Ping
}

actor Pinger {
  var pongs = 0

  receive(msg: PingerMsg) => match msg {
    Pong => {
      pongs = pongs + 1;
      println("  pinger got Pong (#{pongs})")
    }
  }
}

actor Ponger {
  var pings = 0

  receive(msg: PongerMsg) => match msg {
    Ping => {
      pings = pings + 1;
      println("  ponger got Ping (#{pings}), sending Pong back")
    }
  }
}

// --- Coordinator loop using first-class actors ---

fun rally(pinger_state: PingerState, ponger_state: PongerState, rounds: int) : (PingerState, PongerState) {
  if rounds <= 0 {
    (pinger_state, ponger_state)
  } else {
    println("pinger sends Ping");
    // Send Ping to Ponger actor behavior
    let next_ponger = ponger_receive(ponger_state, Ping);
    // Send Pong back to Pinger actor behavior
    let next_pinger = pinger_receive(pinger_state, Pong);
    rally(next_pinger, next_ponger, rounds - 1)
  }
}

fun main() {
  let init_pinger = PingerState { pongs: 0 }
  let init_ponger = PongerState { pings: 0 }

  let (final_pinger, final_ponger) = rally(init_pinger, init_ponger, 3)

  println("Final: pinger received {final_pinger.pongs} pongs")
  println("Final: ponger received {final_ponger.pings} pings")
}
