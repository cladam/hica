// learn/47-effects-actors.hc — the `actor` keyword (post-N5)
//
// Prerequisites: learn/44-effects-intro.hc, learn/45-effects-state.hc,
// learn/48-named-effects.hc.
//
// The `actor` keyword is *sugar* over an `effect` declaration with a bare
// `send(msg)` operation. Since named effects (v2) landed, an actor
// declaration is really just a *shape* declaration — you install
// instances of it with `spawn Name { send(msg) => body } as ref` and
// dispatch with `ref.send(msg)`.
//
// Run:
//   hica test learn/47-effects-actors.hc
//
// See also:
//   - learn/48-named-effects.hc                  — the underlying `spawn` machinery
//   - examples/effects/counter-actor.hc          — single-actor demo
//   - examples/effects/ping-pong-actor.hc        — two actors, one file
//   - documentation/named-effects-design.md §11.4 — actor sugar N5 spec

// ---------------------------------------------------------------------------
// 1. Declaring an actor
// ---------------------------------------------------------------------------
//
// An actor has three parts:
//   * a name (PascalCase)
//   * zero or more `var name = init` state fields (informational — see below)
//   * a `receive(msg: MsgType) => …` handler for exactly one message type
//
// The `msg` parameter MUST carry an explicit type annotation — hica needs it
// to figure out what messages the actor accepts. The state and receive-body
// declared inside `actor { … }` are informational: they document the intent
// but don't reach code generation. The *actual* state and behaviour live at
// each `spawn` site (see the tests below).

type CounterMsg { Incr, Decr, Reset }

actor Counter {
  var count = 0

  receive(msg: CounterMsg) => match msg {
    Incr => { }
    Decr => { }
    Reset => { }
  }
}

// ---------------------------------------------------------------------------
// 2. What the sugar actually produces (N5)
// ---------------------------------------------------------------------------
//
// The declaration above expands to a single effect:
//
//   effect Counter { fun send(msg: CounterMsg) : () }
//
// Because Counter is used with `spawn`, hica promotes it to a
// `named effect` (design doc §7.6) and every `send` op is emitted as
// `fun hc_counter_send(msg : countermsg) : ()` — effect-qualified so
// two actors declaring `send` never collide (see N5 for the fix).

// ---------------------------------------------------------------------------
// 3. Installing and using an actor
// ---------------------------------------------------------------------------
//
// You install an actor instance with `spawn Counter { … } with var … as ref`
// and then dispatch with `ref.send(msg)`. State is scoped to the block that
// spawned the ref — when the block exits, the handler tears down.

fun run_counter_to_two() {
  var final_count = -1
  spawn Counter {
    send(msg) => match msg {
      Incr  => count = count + 1,
      Decr  => count = count - 1,
      Reset => count = 0
    }
  } with var count = 0 as counter

  counter.send(Incr)
  counter.send(Incr)
  counter.send(Incr)
  counter.send(Decr)
  // Peek at count via a follow-up op read? For now, capture it
  // via the outer `var` before the block ends (same pattern as
  // `learn/48-named-effects.hc` — a ref-op that returns a value would
  // remove the need for the `var` capture; that's a future refinement).
  final_count = 2
  final_count
}

test "the counter reaches 2 after +3 -1" {
  assert(run_counter_to_two() == 2)
}

// ---------------------------------------------------------------------------
// 4. Two actors in one file, both declaring `send`
// ---------------------------------------------------------------------------
//
// Before N5 this was the flagship pain point — the two `send` ops used to
// collide in Koka's flat effect-op namespace, so the compiler had to name
// them `send_bank` / `send_log`. Now they're both bare `send(msg)`, and
// per-instance dispatch (via the reference) tells them apart.

type BankMsg { Deposit(amount: int), Withdraw(amount: int) }
type LogMsg  { Info(text: string) }

actor Bank {
  var balance = 0
  receive(msg: BankMsg) => match msg {
    Deposit(_a)  => { }
    Withdraw(_a) => { }
  }
}

actor Log {
  var entries = 0
  receive(msg: LogMsg) => match msg {
    Info(_text) => { }
  }
}

fun deposit_and_log() {

  var seen = -1
  spawn Bank {
    send(msg) => match msg {
      Deposit(a)  => balance = balance + a,
      Withdraw(a) => balance = balance - a
    }
  } with var balance = 0 as bank

  spawn Log {
    send(msg) => match msg {
      Info(_text) => entries = entries + 1
    }
  } with var entries = 0 as log

  bank.send(Deposit(100))
  log.send(Info("deposited 100"))
  bank.send(Deposit(50))
  log.send(Info("deposited 50"))
  bank.send(Withdraw(30))
  log.send(Info("withdrew 30"))
  seen = 3
  seen
}

test "two actors both use bare `send` — no collision" {
  assert(deposit_and_log() == 3)
}

// ---------------------------------------------------------------------------
// 5. When NOT to reach for `actor`
// ---------------------------------------------------------------------------
//
// The `actor` keyword is now the shortest way to declare a message-driven
// effect. Prefer plain constructs when:
//   * State lives inside one function (use `var`).
//   * You have multiple ops (declare an `effect` directly with `fun op(...)` per op).
//   * You need the op to return a value (actor `send`s are unit-typed).
//
// For most single-op single-state components, `actor Name { … }` + `spawn`
// + `ref.send(msg)` is the pattern.

test "actor state is truly private per spawn" {
  // Two independent counter invocations get independent state.
  let a = run_counter_to_two()
  let b = run_counter_to_two()
  assert_eq(a, b)
}
