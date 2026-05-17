// step4-named-instances.kk — Actors from scratch, Step 4: multiple instances
//
// Goal: prove that Koka named effects let us run multiple independent
// actors of the same type, each with their own private state.
//
// Problem with step 3: there's only one `counter` effect in scope.
// If we want two counters, we can't just nest handlers — the inner
// handler shadows the outer one.
//
// Solution: Koka's `named effect` feature. Each instance gets its own
// identity (like an ActorRef in Akka). We can pass these identities
// around and target operations at a specific instance.
//
// Run: koka -e src/actors/step4-named-instances.kk

module actors/step4-named-instances

// ── Message types (same as step 3) ──

type counter-msg
  Increment
  Decrement
  Reset

// ── Named effect: each instance has its own identity ──
//
// `named effect` creates a type-level tag for each instance.
// The operations take an implicit `ev` evidence parameter that
// identifies which instance to target.

named effect counter
  fun send-counter( msg : counter-msg ) : ()
  fun ask-count() : int

// ── Spawn: create a new actor instance ──
//
// `with c <- named handler` creates a fresh instance and binds it to `c`.
// Callers use `with c <- spawn-counter(0)` — just like Koka's reader example.
// No explicit type annotations needed — Koka infers them.

fun spawn-counter( init, action )
  var st := init
  with c <- named handler
    fun send-counter(msg)
      match msg
        Increment -> st := st + 1
        Decrement -> st := st - 1
        Reset     -> st := 0
    fun ask-count() st
  action(c)

// ── Client code: works with specific actor instances ──

fun demo-two-counters()
  with c1 <- spawn-counter(0)        // counter starting at 0
  with c2 <- spawn-counter(100)      // counter starting at 100
  // send to c1
  c1.send-counter(Increment)
  c1.send-counter(Increment)
  c1.send-counter(Increment)
  // send to c2
  c2.send-counter(Decrement)
  c2.send-counter(Decrement)
  // query both — completely independent state
  val count1 = c1.ask-count()
  val count2 = c2.ask-count()
  println("c1 = " ++ count1.show ++ " (expected 3)")
  println("c2 = " ++ count2.show ++ " (expected 98)")

// ── Demo: passing actor references to functions ──
//
// The actor identity `c` can be passed as a regular value.
// This is like passing an ActorRef in Akka — but the effect
// type ensures the handler is in scope.

fun increment-n-times( c, n : int )
  if n <= 0 then ()
  else
    c.send-counter(Increment)
    increment-n-times(c, n - 1)

fun demo-passing-refs()
  with c <- spawn-counter(0)
  increment-n-times(c, 5)
  val count = c.ask-count()
  println("After 5 increments: " ++ count.show ++ " (expected 5)")

// ── Demo: actors in a list ──
//
// Named effects can be stored in data structures and iterated over.
// This is the foundation for actor registries.

fun demo-actor-list()
  with c1 <- spawn-counter(0)
  with c2 <- spawn-counter(0)
  with c3 <- spawn-counter(0)
  val actors = [c1, c2, c3]
  // send Increment to each actor
  actors.foreach fn(c)
    c.send-counter(Increment)
  // send extra increments to c2 and c3
  c2.send-counter(Increment)
  c3.send-counter(Increment)
  c3.send-counter(Increment)
  // query all
  actors.foreach fn(c)
    val count = c.ask-count()
    println("  actor count = " ++ count.show)

// ── main ──

fun main()
  println("=== Step 4: Named instances (multiple actors) ===")
  println("")
  println("--- 4a: Two independent counters ---")
  demo-two-counters()
  println("")
  println("--- 4b: Passing actor refs to functions ---")
  demo-passing-refs()
  println("")
  println("--- 4c: Actors in a list ---")
  demo-actor-list()
