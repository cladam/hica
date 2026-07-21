// hica — Actor pattern: Ping-Pong
//
// Demonstrates Step 5 concept (two actors communicating)
// using the Phase 1 sequential actor pattern.
// A coordinator loop alternates messages between two actors.

import "std/actor"

// --- Message types ---

type PingerMsg {
  Pong
}

type PongerMsg {
  Ping
}

// --- State structs ---

struct PingerState {
  pongs: int
}

struct PongerState {
  pings: int
}

// --- Receive functions (actor behaviors) ---

fun pinger_receive(state: PingerState, msg: PingerMsg) : PingerState => match msg {
  Pong => {
    let next_pongs = state.pongs + 1;
    println("  pinger got Pong (#{next_pongs})");
    PingerState { pongs: next_pongs }
  }
}

fun ponger_receive(state: PongerState, msg: PongerMsg) : PongerState => match msg {
  Ping => {
    let next_pings = state.pings + 1;
    println("  ponger got Ping (#{next_pings}), sending Pong back");
    PongerState { pings: next_pings }
  }
}

// --- Coordinator loop ---

fun rally(pinger_state: PingerState, ponger_state: PongerState, rounds: int) : (PingerState, PongerState) {
  if rounds <= 0 {
    (pinger_state, ponger_state)
  } else {
    println("pinger sends Ping");
    let next_ponger = ponger_receive(ponger_state, Ping);
    let next_pinger = pinger_receive(pinger_state, Pong);
    rally(next_pinger, next_ponger, rounds - 1)
  }
}

// --- Main entrypoint ---

fun main() {
  let init_pinger = PingerState { pongs: 0 }
  let init_ponger = PongerState { pings: 0 }

  let (final_pinger, final_ponger) = rally(init_pinger, init_ponger, 3)

  println("Final: pinger received {final_pinger.pongs} pongs")
  println("Final: ponger received {final_ponger.pings} pings")
}
