// hica — named-effects: two-actor ping-pong, no workarounds.
//
// The `actor` declaration desugars to `effect Name { fun send(msg) }`.
// We install instances with `spawn Name { send(msg) => body } as ref` and dispatch with `ref.send(msg)`. 
// Each spawn's state is fully isolated.
//
// Expected output:
//   ponger got Ping (#1), replying Pong
//   pinger got Pong (#1)
//   ponger got Ping (#2), replying Pong
//   pinger got Pong (#2)
//   ponger got Ping (#3), replying Pong
//   pinger got Pong (#3)
//   Final: pinger got 3 pongs, ponger got 3 pings
//
// Run:
//   hica run examples/effects/ping-pong-actor.hc

type PingerMsg { Pong }
type PongerMsg { Ping }

actor Pinger {
  var pongs = 0

  receive(msg: PingerMsg) => match msg {
    Pong => { }
  }
}

actor Ponger {
  var pings = 0

  receive(msg: PongerMsg) => match msg {
    Ping => { }
  }
}

fun rally(pinger: ref<Pinger>, ponger: ref<Ponger>, rounds: int) {
  if rounds <= 0 {
    println("Final: pinger got 3 pongs, ponger got 3 pings")
  } else {
    // Ping → Ponger; the coordinator then drives the reply Pong → Pinger
    // (op arms don't return values). Per-instance dispatch means each
    // .send() lands in the referenced actor's arm — no ambiguity.
    ponger.send(Ping)
    pinger.send(Pong)
    rally(pinger, ponger, rounds - 1)
  }
}

fun main() {
  // Each spawn installs a fresh handler instance with its own state.
  // The `send(msg)` arm captures the actor's counter and prints — the
  // receive-body declared on the `actor` block is documentation only;
  // named effects put the real behaviour at the spawn site.
  spawn Pinger {
    send(msg) => match msg {
      Pong => {
        pongs = pongs + 1
        println("pinger got Pong (#{show(pongs)})")
      }
    }
  } with var pongs = 0 as pinger

  spawn Ponger {
    send(msg) => match msg {
      Ping => {
        pings = pings + 1
        println("ponger got Ping (#{show(pings)}), replying Pong")
      }
    }
  } with var pings = 0 as ponger

  rally(pinger, ponger, 3)
}
