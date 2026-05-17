// step2-messages.kk — Actors from scratch, Step 2: message types + dispatch
//
// Goal: model actor messages as algebraic data types and dispatch via match.
// This is the "receive" block of an actor.
//
// Key insight: if we define messages as a closed type and match exhaustively,
// the Koka compiler will reject any unhandled message at compile time.
// This is something Erlang and Aether cannot do — they fail at runtime.
//
// Run: koka -e documentation/koka-labs/src/actors/step2-messages.kk

module actors/step2-messages

// ── Step 2a: Define message types as algebraic data types ──

type counter-msg
  Increment
  Decrement
  Reset

// ── Step 2b: A "receive" function that dispatches on messages ──
//
// The counter-state effect from Step 1, used to manage actor state.

effect counter-state
  fun get-count() : int
  fun set-count( n : int ) : ()

// The receive function: processes one message.
// Koka's exhaustiveness checker ensures all message variants are handled.
// Try commenting out a branch — the compiler will warn you.
fun counter-receive( msg : counter-msg ) : counter-state ()
  match msg
    Increment -> set-count(get-count() + 1)
    Decrement -> set-count(get-count() - 1)
    Reset     -> set-count(0)

// ── Step 2c: An actor "run loop" — process a list of messages ──
//
// This simulates an actor mailbox: messages arrive in order, get dispatched.

fun run-counter( init : int, messages : list<counter-msg> ) : int
  var st := init
  with handler
    fun get-count()  st
    fun set-count(n) st := n
  messages.foreach fn(msg)
    counter-receive(msg)
  st  // return final state

// ── Step 2d: Query messages ──
//
// Some messages need a reply. Model this as a separate type.
// Fire-and-forget messages vs. request/reply messages.

type counter-query
  GetCount

type counter-action
  Send( msg : counter-msg )
  Ask( query : counter-query )

// A receive function that handles both kinds.
// `Ask(GetCount)` returns the current count; `Send(msg)` modifies state.
fun counter-receive-full( action : counter-action ) : counter-state int
  match action
    Send(msg) ->
      counter-receive(msg)
      get-count()
    Ask(query) ->
      match query
        GetCount -> get-count()

// ── Demo ──

fun demo-messages() : console ()
  val result = run-counter(0, [Increment, Increment, Increment, Decrement, Reset, Increment])
  println("After [Inc, Inc, Inc, Dec, Reset, Inc]: count = " ++ result.show)

fun demo-queries() : console ()
  var st := 0
  with handler
    fun get-count()  st
    fun set-count(n) st := n
  val actions = [Send(Increment), Send(Increment), Ask(GetCount), Send(Decrement), Ask(GetCount)]
  actions.foreach fn(a)
    val result = counter-receive-full(a)
    match a
      Ask(_) -> println("  query result: " ++ result.show)
      _      -> ()

fun main()
  println("=== Step 2: Message types + dispatch ===")
  println("")
  println("--- 2a: Process a mailbox of messages ---")
  demo-messages()
  println("")
  println("--- 2b: Send + Ask (fire-and-forget vs request/reply) ---")
  demo-queries()
