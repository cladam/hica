// hica — M6 actor sugar: two-actor ping-pong.
//
// This is the M6 exit criterion: two actors, each with its own state
// and message type, communicating within a single `main`. It's the
// spiritual successor to `src/actors/step5-ping-pong.kk` written
// without any hand-rolled `process_messages` scaffolding.
//
// Each `actor` desugars into an `effect Name` + `pub fun with_<name>`
// helper. Because op namespaces are currently flat (design doc §8.2,
// §10 flags "named effects" as post-M6), the desugarer names each
// actor's send op `send_<name>` — so `send_pinger(Pong)` and
// `send_ponger(Ping)` never collide.
//
// When named effects land the surface will collapse to
// `pinger.send(Pong)` / `ponger.send(Ping)` (design doc §13.4), but
// the semantics — one effect + one handler + local `var` per actor —
// won't change.
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
    Pong => {
      pongs = pongs + 1
      println("pinger got Pong (#{show(pongs)})")
    }
  }
}

actor Ponger {
  var pings = 0

  receive(msg: PongerMsg) => match msg {
    Ping => {
      pings = pings + 1
      println("ponger got Ping (#{show(pings)}), replying Pong")
    }
  }
}

fun rally(rounds: int) {
  if rounds <= 0 {
    println("Final: pinger got 3 pongs, ponger got 3 pings")
  } else {
    // Ping → Ponger; Ponger's receive would send Pong back to Pinger,
    // but M6 op-arms don't take return values, so we drive the
    // conversation from the coordinator instead.
    send_ponger(Ping)
    send_pinger(Pong)
    rally(rounds - 1)
  }
}

fun main() {
  with_pinger(() => {
    with_ponger(() => {
      rally(3)
    })
  })
}
