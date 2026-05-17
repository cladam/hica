# Actors in Hica — Ideation

Inspired by [Aether](https://github.com/aether-lang-org/aether) (Paul Hammant et al.) and the classic actor model (Erlang/OTP, Pony, Akka).

## The Unique Angle: Actors via Algebraic Effects

Aether compiles to C with a native multi-core scheduler, lock-free mailboxes, and a runtime actor system. It's fast systems programming.

Hica has a different superpower: **Koka's algebraic effect handlers**. Effects give us actors that are:
- **Type-safe at compile time** — the type system tracks which messages an actor can send/receive
- **Composable** — handlers compose freely; no monad transformer headaches
- **Semantically clean** — an actor is *just* a handler with state, receive is *just* pattern matching on effect operations

This means we could have actors where **unhandled messages are a compile error**, not a runtime crash.

---

## Proposed Syntax

### Message types (already supported — just Hica enums)

```rust
type CounterMsg {
  Increment,
  Decrement,
  Reset,
  GetCount
}
```

### Actor declaration

```rust
actor Counter {
  var count = 0

  receive(msg) => match msg {
    Increment => count = count + 1,
    Decrement => count = count - 1,
    Reset     => count = 0,
    GetCount  => reply(count)
  }
}
```

### Spawning and sending

```rust
fun main() {
  let c = spawn(Counter)
  send(c, Increment)
  send(c, Increment)
  send(c, Decrement)
  let n = ask(c, GetCount)   // synchronous request/reply
  println(n)                  // 1
}
```

### Alternate: lightweight `!` operator (Aether/Erlang style)

```rust
  c ! Increment
  c ! Increment
  let n = c ? GetCount       // ? for ask (request + wait for reply)
```

---

## How It Maps to Koka

### Core idea: an actor is a named effect handler with state

```koka
// Generated Koka for the Counter actor
effect counter-actor {
  ctl send-counter(msg : counter-msg) : ()
  ctl ask-counter(msg : counter-msg) : int
}

fun counter-handler(action) {
  var count := 0
  with handler {
    ctl send-counter(msg) {
      match msg {
        Increment -> { count := count + 1; resume(()) }
        Decrement -> { count := count - 1; resume(()) }
        Reset     -> { count := 0; resume(()) }
      }
    }
    ctl ask-counter(msg) {
      match msg {
        GetCount -> resume(count)
      }
    }
  }
  action()
}
```

### What this buys you

| Property | Aether (runtime) | Hica (effect-based) |
|----------|------------------|---------------------|
| Unhandled message | Runtime panic or dead letter | **Compile error** (non-exhaustive match) |
| Message type safety | Compile-time types | Compile-time types + effect row |
| Concurrency | Real multi-core | Single-threaded cooperative (initially) |
| Mailbox ordering | FIFO with optimizations | Determined by handler scoping |
| Effect tracking | N/A | `actor<Counter>` appears in function type |

---

## Phased Approach

### Phase 1: Sequential actors (effect handlers, no real concurrency)

This is achievable **now** with Hica's existing features + a small syntax addition:
- `actor` keyword → generates an effect + handler
- `send`/`ask` → effect operations
- `spawn` → installs the handler (scoped)
- No threads, no scheduler — purely sequential message processing

**Value**: teaches the actor pattern, type-safe, works today on Koka 3.2.3.

### Phase 2: Cooperative concurrency (interleaving via effects)

Add a `yield` effect so multiple actors can be interleaved:
- A simple round-robin scheduler as an effect handler
- Each `send` yields to let other actors process
- Still single-threaded but concurrent (like Lua coroutines)

### Phase 3: True parallelism (future, Koka async primitives)

Koka's roadmap includes async/parallel primitives. When those land:
- Actors map to lightweight green threads
- Mailboxes become channels
- The effect types still guarantee message safety

---

## Design Questions

1. **Scoped vs. first-class actors?**
   - Scoped (like `with handler`) = simpler, lifetime tied to lexical scope
   - First-class (actor references) = more flexible, needs named effects (Koka has these)

2. **Reply mechanism?**
   - `ask` (synchronous) is simplest — maps to a `ctl` that resumes with a value
   - Async reply (callbacks, futures) = Phase 2+

3. **Supervision / error handling?**
   - Hica already has `Result`/`Maybe` — actor death = `Err` propagation
   - OTP-style supervisors = a handler that restarts child handlers

4. **Actor state visibility?**
   - Fully private (encapsulated) — only messages can query state
   - Or expose via `ask` operations that return state projections

5. **Multiple actor instances?**
   - Named effects (Koka feature) allow multiple instances of the same effect type
   - `let c1 = spawn(Counter); let c2 = spawn(Counter)` — two independent handlers

---

## What Hica Already Has That Helps

- `type` enums → message types ✓
- `match` with exhaustiveness → receive blocks ✓
- `var` (mutable local state, effect-safe) → actor state ✓
- `struct` → actor state records ✓
- Effect tracking in `hica check` → will show `actor<X>` effects ✓
- Pipe operator → message routing chains ✓

## What Needs to Be Added

- `actor` keyword (parser + AST node)
- `spawn` / `send` / `ask` builtins (or prelude functions)
- Codegen: actor → Koka named effect handler
- Optional: `!` and `?` operators for send/ask sugar

---

## Example: Ping-Pong (the actor hello world)

```rust
type PingMsg { Ping }
type PongMsg { Pong }

actor Pinger {
  var count = 0

  receive(msg) => match msg {
    Pong => {
      count = count + 1
      if count < 10 {
        send(ponger, Ping)
      }
    }
  }
}

actor Ponger {
  receive(msg) => match msg {
    Ping => send(pinger, Pong)
  }
}

fun main() {
  let pinger = spawn(Pinger)
  let ponger = spawn(Ponger)
  send(pinger, Pong)  // kick it off
  // With cooperative scheduling, this interleaves
}
```

---

## Comparison with Aether

| | Aether | Hica |
|---|--------|------|
| **Target** | C (native) | Koka (effects → C/JS/WASM) |
| **Scheduling** | Multi-core, work-stealing | Effect handlers (cooperative) |
| **Memory** | Arenas, manual + defer | Perceus ref-counting (automatic) |
| **Message passing** | Lock-free SPSC queues | Effect operations (zero-cost when sequential) |
| **Safety model** | Capability sandboxing | Effect type rows |
| **Maturity** | v0.173, production-grade HTTP | Research-stage |
| **Sweet spot** | High-perf concurrent servers | Teaching, safe DSLs, correctness-first |

---

## Why This Is Interesting

1. **Effect-typed actors are novel** — no mainstream language does this. Frank (Edinburgh) and some academic papers explore it, but no one ships it in a beginner-friendly surface.

2. **Hica's teaching mission** — actors are a great pedagogical tool (state machines + message passing = how distributed systems actually work). Making them type-safe lowers the learning cliff.

3. **Paul's TBD angle** — actors with typed messages + exhaustive receive = fewer runtime surprises = trunk-based development is safer. You catch protocol violations at compile time, not in production.

4. **Progressive disclosure** — Phase 1 actors work in a REPL with no concurrency concepts. Phase 2 adds interleaving. Phase 3 adds real parallelism. Same syntax throughout.

---

## Next Steps

- [ ] Write a `examples/actor-counter.hc` sketch (using current syntax to simulate)
- [ ] Prototype in pure Koka: write the effect handler manually, see how it feels
- [ ] Design the `actor` AST node and discuss parse rules
- [ ] Check Koka named effects for multi-instance support
- [ ] Look at Daan Leijen's "Structured Asynchrony with Algebraic Effects" paper
