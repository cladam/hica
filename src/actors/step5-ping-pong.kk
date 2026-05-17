// step5-ping-pong.kk — Actors from scratch, Step 5: two communicating actors
//
// Goal: prove that named-effect actors can send messages to each other.
// This is the classic actor "hello world" — Pinger and Ponger rally
// messages back and forth.
//
// Key insight: the ponger handler is installed *inside* the pinger's
// scope, so it can call pinger operations directly. This is the
// effect-based equivalent of passing an ActorRef.
//
// Run: koka -e src/actors/step5-ping-pong.kk

module actors/step5-ping-pong

// ── Message types ──

type ping-msg
  Ping

type pong-msg
  Pong

// ── Two named effects: one per actor ──

named effect pinger
  fun send-to-pinger( msg : pong-msg ) : ()
  fun pinger-count() : int

named effect ponger
  fun send-to-ponger( msg : ping-msg ) : ()
  fun ponger-count() : int

// ── Spawn pinger: receives Pong messages, counts them ──

fun spawn-pinger( action )
  var count := 0
  with p <- named handler
    fun send-to-pinger(msg)
      match msg
        Pong ->
          count := count + 1
          println("  pinger got Pong (#" ++ count.show ++ ")")
    fun pinger-count() count
  action(p)

// ── Spawn ponger: receives Ping messages, sends Pong back ──
//
// Notice: `pr` (the pinger ref) is captured in the handler closure.
// When ponger receives a Ping, it calls pinger's effect operation
// directly — no mailbox, no async, just an effect call.

fun spawn-ponger( pr, action )
  var count := 0
  with p <- named handler
    fun send-to-ponger(msg)
      match msg
        Ping ->
          count := count + 1
          println("  ponger got Ping (#" ++ count.show ++ "), sending Pong back")
          pr.send-to-pinger(Pong)
    fun ponger-count() count
  action(p)

// ── Rally: pinger sends N pings, each triggers a pong back ──

fun rally( pr, po, n : int )
  if n <= 0 then ()
  else
    println("  pinger sends Ping")
    po.send-to-ponger(Ping)      // → ponger receives Ping → sends Pong to pinger
    rally(pr, po, n - 1)

// ── main ──

fun main()
  println("=== Step 5: Ping-Pong ===")
  println("")
  println("--- 5a: 3-round rally ---")
  with pr <- spawn-pinger()
  with po <- spawn-ponger(pr)
  rally(pr, po, 3)
  println("")
  println("Final: pinger received " ++ pr.pinger-count().show ++ " pongs")
  println("Final: ponger received " ++ po.ponger-count().show ++ " pings")
