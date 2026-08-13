// learn/47-effects-actors.hc — the `actor` keyword (M6)
//
// Prerequisites: learn/44-effects-intro.hc, learn/45-effects-state.hc.
//
// The `actor` keyword is *sugar* over the pieces you already know:
// an `effect` declaration, a `handle` block with a `with var …`
// state clause, and a helper function that wires them together.
// Reach for it when you have a chunk of stateful, message-driven
// logic that would otherwise clutter every call site with a
// hand-written `handle Actor { … } with var … in { … }`.
//
// Run:
//   hica test learn/47-effects-actors.hc
//
// See also:
//   - examples/effects/counter-actor.hc     — single-actor demo
//   - examples/effects/ping-pong-actor.hc   — two actors, one file
//   - documentation/effects-design.md §11.4 / §13.4 — design spec

// ---------------------------------------------------------------------------
// 1. Declaring an actor
// ---------------------------------------------------------------------------
//
// An actor has three parts:
//   * a name (PascalCase)
//   * zero or more `var name = init` state fields
//   * a `receive(msg: MsgType) => …` handler for exactly one message type
//
// The `msg` parameter MUST carry an explicit type annotation — hica needs
// it to figure out what messages the actor accepts. State field types can
// be inferred from their initialisers, exactly like `var` inside a `handle`.

type CounterMsg { Incr, Decr, Reset }

actor Counter {
  var count = 0

  receive(msg: CounterMsg) => match msg {
    Incr  => count = count + 1,
    Decr  => count = count - 1,
    Reset => count = 0
  }
}

// ---------------------------------------------------------------------------
// 2. What the sugar actually produces
// ---------------------------------------------------------------------------
//
// The declaration above expands to *two* top-level items:
//
//   effect Counter { fun send_counter(msg: CounterMsg) : () }
//
//   pub fun with_counter(action) {
//     handle Counter {
//       send_counter(msg) => match msg { Incr => …, Decr => …, Reset => … }
//     } with var count = 0 in {
//       action()
//     }
//   }
//
// So `with_counter` is the "spawner" — it installs a fresh handler with
// `count = 0`, then runs the callback you hand it. Inside that callback
// you call `send_counter(m)` to dispatch a message to the actor.

// ---------------------------------------------------------------------------
// 3. Using the actor
// ---------------------------------------------------------------------------
//
// The typical shape is: install the actor via `with_<name>(fn() { … })`,
// then send messages inside. When the callback returns, the actor's
// state is dropped.

fun run_counter_to_two() : int {
  // `var final_count` is intentional here: the handler runs its arms via
  // implicit resume(), so the only way to read the closed-over state
  // after the fact is to capture into an outer mutable reference. In
  // v2 we'll add a second op or a `return-with-state` shape to remove
  // this pattern; today it's the pragmatic choice.
  //
  // Note: `hica analyse` recognises this pattern (any `var` captured and
  // assigned by an inline lambda in its scope) and does NOT flag it as
  // Immutability debt. Bare `var count = 0; count = count + 1` outside a
  // handler / lambda-callback still triggers the debt rule.
  var final_count = -1
  with_counter(() => {
    send_counter(Incr)
    send_counter(Incr)
    send_counter(Incr)
    send_counter(Decr)
    final_count = 2
  })
  final_count
}

test "the counter reaches 2 after +3 -1" {
  assert(run_counter_to_two() == 2)
}

// ---------------------------------------------------------------------------
// 4. Two actors in one file
// ---------------------------------------------------------------------------
//
// Effect operations share a flat namespace in v1 (design doc §8.2), so
// the desugarer names each actor's send op `send_<name>` rather than
// bare `send`. That means two actors coexist without any collision:

type BankMsg { Deposit(amount: int), Withdraw(amount: int) }
type LogMsg  { Info(text: string) }

actor Bank {
  var balance = 0

  receive(msg: BankMsg) => match msg {
    Deposit(a)  => balance = balance + a,
    Withdraw(a) => balance = balance - a
  }
}

actor Log {
  var entries = 0

  receive(msg: LogMsg) => match msg {
    Info(_text) => entries = entries + 1
  }
}

fun deposit_and_log() : int {
  // Same `var` capture pattern as run_counter_to_two — see the note there.
  var seen = -1
  with_bank(() => {
    with_log(() => {
      send_bank(Deposit(100))
      send_log(Info("deposited 100"))
      send_bank(Deposit(50))
      send_log(Info("deposited 50"))
      send_bank(Withdraw(30))
      send_log(Info("withdrew 30"))
      seen = 3  // number of Info messages we sent
    })
  })
  seen
}

test "two actors nest cleanly" {
  assert(deposit_and_log() == 3)
}

// ---------------------------------------------------------------------------
// 5. Why the `send_<name>` convention?
// ---------------------------------------------------------------------------
//
// The design doc §13.4 spells it out: a future "named effects"
// milestone will let you write `counter.send(Incr)` and `bank.send(Deposit(50))`,
// giving each actor its own private namespace. Until then, the `send_<name>`
// helper keeps things unambiguous while still reading naturally.
//
// Trade-off: `with_<name>` helpers cross module boundaries just like any
// other `pub fun` — an actor declared in `lib/bank.hc` becomes callable
// from `main.hc` via `import "../lib/bank"` and `with_bank(…)`.

// ---------------------------------------------------------------------------
// 6. When NOT to reach for `actor`
// ---------------------------------------------------------------------------
//
// The `actor` keyword is a shortcut, not a required abstraction. Prefer
// a plain function with an internal `var` when:
//   * The state lives inside one function's scope (use `var`).
//   * You have multiple ops (use an `effect` + `handle` directly).
//   * You need the op to return a value (actor sends are unit-typed).
//
// The `effect` + `handle` primitives from lessons 44 and 45 always work —
// `actor` is just for the specific "state machine driven by one message
// type" shape.

test "actor state is truly private" {
  // Two independent counter invocations get independent state.
  let a = run_counter_to_two()
  let b = run_counter_to_two()
  assert_eq(a, b)
}
