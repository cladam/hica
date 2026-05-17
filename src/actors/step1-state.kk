// step1-state.kk — Actors from scratch, Step 1: state via effect handlers
//
// Goal: understand how Koka effect handlers manage state.
// An actor is fundamentally "state + message dispatch". Let's start with state.
//
// Key concepts:
//   - `effect` declares an abstract set of operations
//   - `fun` operations are tail-resumptive (always resume once)
//   - `with handler { ... }` installs a concrete implementation
//   - `var` inside a handler gives the handler mutable state
//
// Run: koka -e documentation/koka-labs/src/actors/step1-state.kk

module actors/step1-state

// ── Step 1a: A simple counter using a custom state effect ──
//
// We define get/set operations, then handle them with a var.
// This is the foundation: an actor's internal state.

effect counter-state
  fun get-count() : int
  fun set-count( n : int ) : ()

// A function that uses counter state — it doesn't know how state is managed.
fun increment() : counter-state ()
  val c = get-count()
  set-count(c + 1)

fun decrement() : counter-state ()
  val c = get-count()
  set-count(c - 1)

fun reset() : counter-state ()
  set-count(0)

// Handle the state effect with a mutable variable.
// This is the "actor runtime" in miniature.
fun with-counter( init : int, action : () -> <counter-state|e> a ) : e a
  var st := init
  with handler
    fun get-count() st
    fun set-count(n) st := n
  action()

// ── Step 1b: Compose operations freely ──

fun demo-counter() : console ()
  with-counter(0)
    increment()
    increment()
    increment()
    decrement()
    val final-count = get-count()
    println("Final count: " ++ final-count.show)  // expect: 2

// ── Step 1c: Return state alongside the result ──
//
// Use a `return` clause to pair the result with final state.

fun with-counter-result( init : int, action : () -> <counter-state|e> a ) : e (a, int)
  var st := init
  with handler
    return(x)  (x, st)
    fun get-count() st
    fun set-count(n) st := n
  action()

fun demo-counter-result() : console ()
  val (result, final-state) = with-counter-result(0)
    increment()
    increment()
    increment()
    get-count()   // returns 3 as the action result
  println("Result: " ++ result.show ++ ", Final state: " ++ final-state.show)

// ── main ──

fun main()
  println("=== Step 1: State via effect handlers ===")
  println("")
  println("--- 1a: Basic counter ---")
  demo-counter()
  println("")
  println("--- 1b: Counter with result ---")
  demo-counter-result()
