// step3-actor-effect.kk — Actors from scratch, Step 3: the actor effect
//
// Goal: define a proper `actor` effect that wraps state + message dispatch
// into a single composable abstraction. The user code just calls `send`
// and `ask` without knowing how the actor is implemented.
//
// This is the core of the "actors via algebraic effects" idea:
//   - An actor is an effect handler with internal state
//   - `send` performs a fire-and-forget effect operation
//   - `ask` performs a request/reply effect operation
//   - The effect type tracks which actors a function uses
//
// Run: koka -e documentation/koka-labs/src/actors/step3-actor-effect.kk

module actors/step3-actor-effect

// ── Message types ──

type counter-msg
  Increment
  Decrement
  Reset

// ── The actor effect ──
//
// This declares the abstract API that client code uses.
// `fun` operations are tail-resumptive: they always resume exactly once.
// This is efficient (no stack capture) and safe (no multi-resume surprises).

effect counter
  fun send-counter( msg : counter-msg ) : ()
  fun ask-count() : int

// ── Client code: uses the actor without knowing its implementation ──
//
// Note the effect type: `counter` appears in the inferred type.
// This is tracked by the compiler — if you forget to install a handler,
// you get a compile error, not a runtime crash.

fun do-counting() : <counter,console> ()
  send-counter(Increment)
  send-counter(Increment)
  send-counter(Increment)
  send-counter(Decrement)
  val count = ask-count()
  println("Count after inc,inc,inc,dec: " ++ count.show)
  send-counter(Reset)
  val after-reset = ask-count()
  println("Count after reset: " ++ after-reset.show)

// ── The handler: installs the actor "runtime" ──
//
// This is where messages are actually dispatched.
// The `var st` is the actor's private mutable state.
// The handler defines what each operation does concretely.

fun with-counter-actor( init : int, action : () -> <counter|e> a ) : e a
  var st := init
  with handler
    fun send-counter(msg)
      match msg
        Increment -> st := st + 1
        Decrement -> st := st - 1
        Reset     -> st := 0
    fun ask-count()
      st
  action()

// ── Why this is powerful ──
//
// 1. Type safety: if you add a new message variant to counter-msg
//    but forget to handle it in the handler, Koka warns you.
//
// 2. Composability: multiple actors compose by stacking handlers.
//    Each handler only discharges its own effect.
//
// 3. Testability: swap the handler to test with a mock actor.
//    The client code (do-counting) doesn't change.

// ── Demo: mock handler for testing ──
//
// Instead of real state, this handler logs all operations.

fun show-msg( msg : counter-msg ) : string
  match msg
    Increment -> "inc"
    Decrement -> "dec"
    Reset     -> "reset"

fun with-logging-counter( action : () -> <counter,console|e> a ) : <console|e> a
  with handler
    fun send-counter(msg)
      println("  [log] send: " ++ msg.show-msg)
    fun ask-count()
      println("  [log] ask-count -> 42 (mock)")
      42
  action()

// ── main ──

fun main()
  println("=== Step 3: The actor effect ===")
  println("")
  println("--- 3a: Real counter actor ---")
  with-counter-actor(0)
    do-counting()
  println("")
  println("--- 3b: Same client code, mock handler ---")
  with-logging-counter
    do-counting()
