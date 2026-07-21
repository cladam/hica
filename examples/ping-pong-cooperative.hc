// hica — Cooperative Concurrent Actor Example: Ping-Pong
//
// Demonstrates Step B (Cooperative Concurrency) via an asynchronous
// FIFO event-loop scheduler, fully interleaving two actors concurrently.

import "std/actor"

// --- Message types ---

type PingerMsg {
  Pong
}

type PongerMsg {
  Ping
}

// --- First-Class Actors ---

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

// --- Asynchronous Scheduler Event Loop ---

type Event {
  SendPinger(msg: PingerMsg),
  SendPonger(msg: PongerMsg)
}

// Helper: append an element to a list
fun append_event(xs: list<Event>, x: Event) : list<Event> => match xs {
  [] => [x],
  [h, ..t] => [h] + append_event(t, x)
}

// The cooperative event-loop scheduler
fun dispatch(pinger: PingerState, ponger: PongerState, events: list<Event>) : () {
  match events {
    [] => {
      println("Final: pinger received {pinger.pongs} pongs");
      println("Final: ponger received {ponger.pings} pings")
    },
    [ev, ..rest] => match ev {
      SendPinger(msg) => {
        let next_pinger = pinger_receive(pinger, msg);
        if next_pinger.pongs < 3 {
          println("pinger sends Ping");
          // Queue a Ping to Ponger at the end of the queue
          let next_events = append_event(rest, SendPonger(Ping));
          dispatch(next_pinger, ponger, next_events)
        } else {
          dispatch(next_pinger, ponger, rest)
        }
      },
      SendPonger(msg) => {
        let next_ponger = ponger_receive(ponger, msg);
        // Reply with a Pong to Pinger at the end of the queue
        let next_events = append_event(rest, SendPinger(Pong));
        dispatch(pinger, next_ponger, next_events)
      }
    }
  }
}

fun main() {
  let init_pinger = PingerState { pongs: 0 }
  let init_ponger = PongerState { pings: 0 }

  // Kick off the concurrent event loop with an initial event
  println("Kicking off concurrent cooperative rally loop...");
  dispatch(init_pinger, init_ponger, [SendPonger(Ping)])
}
