# Lab Journal: Actors via Algebraic Effects in Koka

**Date**: 18 May 2026
**Author**: Claes Adamsson
**Koka version**: 3.2.3
**Context**: Exploring how hica could support an actor model by leveraging Koka's algebraic effect handlers as the implementation substrate. Inspired by [Aether](https://github.com/aether-lang-org/aether) and conversations with Paul Hammant about the actor model, and informed by prior experience with Akka Typed.

**Source files**: `src/actors/step1-state.kk` through `step5-ping-pong.kk`

---

## Thesis

An actor is fundamentally **state + message dispatch**. Koka algebraic effects give us both:
- **State** → `var` inside an effect handler
- **Message dispatch** → pattern matching on algebraic data types inside effect operations
- **Actor identity** → named effects (each instance gets a unique type-level tag)
- **Compile-time safety** → exhaustive match on message types; effect rows track which actors a function uses

This gives us something Erlang, Akka, and Aether cannot: **unhandled messages are a compile error, not a runtime crash**.

---

## Step 1: State via Effect Handlers

**File**: `step1-state.kk`
**Goal**: Prove that Koka effect handlers can manage mutable state — the foundation of any actor.

Define an abstract state interface:

```koka
effect counter-state
  fun get-count() : int
  fun set-count( n : int ) : ()
```

Handle it with a mutable variable:

```koka
fun with-counter( init : int, action : () -> <counter-state|e> a ) : e a
  var st := init
  with handler
    fun get-count() st
    fun set-count(n) st := n
  action()
```

**Key insight**: The `var st` lives inside the handler. It's the handler's private state — invisible to client code. Client code just calls `get-count()` and `set-count(n)` without knowing how state is stored.

**Bonus**: A `return` clause can pair the result with final state — useful for "what did the actor end up with?"

```koka
fun with-counter-result( init, action )
  var st := init
  with handler
    return(x)  (x, st)
    fun get-count() st
    fun set-count(n) st := n
  action()
```

**Output**: `Final count: 2` and `Result: 3, Final state: 3` ✓

---

## Step 2: Messages as Algebraic Data Types

**File**: `step2-messages.kk`
**Goal**: Model actor messages as closed types and dispatch via exhaustive pattern matching.

```koka
type counter-msg
  Increment
  Decrement
  Reset
```

A receive function dispatches on the message type:

```koka
fun counter-receive( msg : counter-msg ) : counter-state ()
  match msg
    Increment -> set-count(get-count() + 1)
    Decrement -> set-count(get-count() - 1)
    Reset     -> set-count(0)
```

**Key insight**: If you add a new variant to `counter-msg` and forget to handle it in `counter-receive`, Koka gives you a compile-time warning. Erlang and Aether would silently drop the message or crash at runtime.

Also introduced the **send vs ask** pattern:

```koka
type counter-action
  Send( msg : counter-msg )     // fire-and-forget
  Ask( query : counter-query )  // request/reply
```

**Output**: `count = 1` after [Inc,Inc,Inc,Dec,Reset,Inc]; query results: 2, 1 ✓

---

## Step 3: The Actor Effect

**File**: `step3-actor-effect.kk`
**Goal**: Combine state + messages into a single `effect` — the unified actor abstraction.

```koka
effect counter
  fun send-counter( msg : counter-msg ) : ()
  fun ask-count() : int
```

Client code uses the actor without knowing its implementation:

```koka
fun do-counting() : <counter,console> ()
  send-counter(Increment)
  send-counter(Increment)
  val count = ask-count()
  println("Count: " ++ count.show)
```

The handler is the actor runtime:

```koka
fun with-counter-actor( init : int, action : () -> <counter|e> a ) : e a
  var st := init
  with handler
    fun send-counter(msg)
      match msg
        Increment -> st := st + 1
        Decrement -> st := st - 1
        Reset     -> st := 0
    fun ask-count() st
  action()
```

**Key insight**: The effect type `<counter,console>` in `do-counting`'s signature tells you exactly which actors this function touches. If you forget to install a handler, you get a compile error — not a runtime "actor not found" crash.

**Testability demo**: Swap the real handler for a mock that logs operations and returns dummy values. Client code (`do-counting`) doesn't change at all.

```koka
fun with-logging-counter( action : () -> <counter,console|e> a ) : <console|e> a
  with handler
    fun send-counter(msg)
      println("  [log] send: " ++ msg.show-msg)
    fun ask-count()
      42  // mock value
  action()
```

**Output**: Real actor returns 2 and 0; mock actor logs all operations and returns 42 ✓

---

## Step 4: Multiple Instances via Named Effects

**File**: `step4-named-instances.kk`
**Goal**: Run multiple independent actors of the same type, each with private state.

**Problem**: With plain `effect counter`, there's only one counter in scope. Nesting handlers shadows the outer one — you can't address two counters independently.

**Solution**: Koka's `named effect` — each instance gets its own identity, like an `ActorRef` in Akka.

```koka
named effect counter
  fun send-counter( msg : counter-msg ) : ()
  fun ask-count() : int
```

Spawn creates a fresh instance:

```koka
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
```

Callers use `with c <- spawn-counter(0)` — flat, composable:

```koka
fun demo-two-counters()
  with c1 <- spawn-counter(0)
  with c2 <- spawn-counter(100)
  c1.send-counter(Increment)
  c2.send-counter(Decrement)
  println(c1.ask-count().show)  // 1
  println(c2.ask-count().show)  // 99
```

**Syntax lesson learned**: The correct Koka syntax is `with c <- named handler` (not `named handler c`). Found by studying Koka's official `samples/handlers/named/ask.kk`.

**Three demos proved**:
- **4a**: Two independent counters with isolated state (c1=3, c2=98)
- **4b**: Actor references passed to helper functions (`increment-n-times(c, 5)`)
- **4c**: Actor references stored in a list and iterated over — foundation for actor registries

**Output**: All values match expectations ✓

---

## Step 5: Ping-Pong — Two Communicating Actors

**File**: `step5-ping-pong.kk`
**Goal**: Prove that named-effect actors can send messages to each other.

Two named effects, one per actor:

```koka
named effect pinger
  fun send-to-pinger( msg : pong-msg ) : ()
  fun pinger-count() : int

named effect ponger
  fun send-to-ponger( msg : ping-msg ) : ()
  fun ponger-count() : int
```

The ponger's handler captures the pinger reference in its closure — when it receives a Ping, it sends a Pong back directly:

```koka
fun spawn-ponger( pr, action )
  var count := 0
  with p <- named handler
    fun send-to-ponger(msg)
      match msg
        Ping ->
          count := count + 1
          pr.send-to-pinger(Pong)   // cross-actor call!
    fun ponger-count() count
  action(p)
```

The rally loop kicks off the exchange:

```koka
fun main()
  with pr <- spawn-pinger()
  with po <- spawn-ponger(pr)
  rally(pr, po, 3)
```

**Key insight**: Cross-actor communication is just an effect operation call. The ponger handler is installed *inside* the pinger's scope, so `pr` is in scope for the closure. No mailbox, no async, no `replyTo` fields embedded in messages — just lexical scoping + effects.

**Output**:
```
pinger sends Ping
  ponger got Ping (#1), sending Pong back
  pinger got Pong (#1)
pinger sends Ping
  ponger got Ping (#2), sending Pong back
  pinger got Pong (#2)
pinger sends Ping
  ponger got Ping (#3), sending Pong back
  pinger got Pong (#3)
Final: pinger received 3 pongs
Final: ponger received 3 pings
```
✓

---

## Comparison: Akka Typed vs Effects-Based Actors

| | Akka Typed | Koka Effects |
|---|---|---|
| Actor identity | `ActorRef[T]` — runtime value | Named effect instance — compile-time tracked |
| State model | Return new `Behavior[T]` (immutable state) | `var` in handler (mutable, handler-scoped) |
| Message dispatch | Async mailbox, FIFO | Synchronous effect operation call |
| Reply mechanism | `replyTo: ActorRef[Reply]` in message | `ask-count() : int` — returns directly |
| Spawn | `context.spawn(behavior, name)` | `with c <- spawn-counter(0)` |
| Testing | `ActorTestKit`, async probes | Swap the handler — synchronous, instant |
| Concurrency | Real threads + dispatcher pools | Sequential (Phase 1) |
| Exhaustiveness | `sealed trait` + Scala match | `type` + Koka match — same guarantee |
| Effect tracking | None — `ActorRef` is opaque | `<counter,console>` in function signature |

**Akka wins on**: real concurrency, distribution, supervision trees, mature ecosystem.
**Effects win on**: compile-time effect tracking, zero-cost handler swapping, no runtime overhead, simpler reply pattern, no framework boot.

---

## Koka Syntax Lessons Learned

1. **`final` is reserved** — can't use as a variable name (step 2 fix)
2. **Named handler syntax**: `with c <- named handler` (not `named handler c`)
3. **No type annotations needed** on spawn functions — Koka infers everything
4. **`with` flattens nesting** — `with c1 <- spawn(0); with c2 <- spawn(100)` instead of nested callbacks
5. **Inline `match` in string concat fails** — extract to a helper function (step 3 fix)
6. **Tail-resumptive `fun` ops** are efficient for actors — no stack capture, always resume exactly once

---

## What This Proves for hica

The five steps demonstrate that Koka's algebraic effects are a natural substrate for actors:

1. **Actor = effect handler with state** (step 1 + 3)
2. **Messages = algebraic data types with exhaustive match** (step 2)
3. **Actor identity = named effect instance** (step 4)
4. **Cross-actor communication = effect operation calls** (step 5)
5. **Mock actors for testing = alternative handlers** (step 3b)

The proposed hica syntax from `actors-ideation.md` maps cleanly:

| hica syntax | Koka codegen |
|---|---|
| `actor Counter { ... }` | `named effect counter` + `spawn-counter` handler |
| `spawn(Counter)` | `with c <- spawn-counter(0)` |
| `send(c, Increment)` | `c.send-counter(Increment)` |
| `ask(c, GetCount)` | `c.ask-count()` |

**Next steps**: Phase 2 (cooperative concurrency via yield effect), hica syntax design for `actor`/`spawn`/`send` keywords, codegen implementation.

---

## Step 6: Translation Test — mental-process.hc

**File**: `examples/mental-process.hc`
**Date**: 20 May 2026
**Goal**: Translate a Koka program using custom `effect brain` and `effect weekend` (with `ctl` handlers and `resume`) into idiomatic hica using the Phase 1 actor model.

### Original Koka design

The Koka version defines two custom effects:
- `effect brain` with `fun thoughts()` and `ctl flush-buffer()` (resumes after clearing state)
- `effect weekend` with `fun is-sunny()` and `ctl step-away()` (never resumes — terminates)

A recursive `mental-process()` calls `thoughts()`, checks the stack depth, and either overflows (flush + step-away) or processes the head thought and recurses.

### hica translation

Effects become actors: message types (`BrainMsg`, `WeekendMsg`), state structs (`BrainState`, `WeekendState`), and receive functions (`brain_receive`, `weekend_receive`).

```hica
type BrainMsg { Think, FlushBuffer }
struct BrainState { thoughts: list<string> }

type WeekendMsg { StepAway }
struct WeekendState { sunny: bool }
```

The orchestrator (`mental_process`) uses `process_messages` for the recursive-think path and inlines the overflow path.

### Findings

1. **Effects → actors maps well for state + messages**: The `effect brain` with `thoughts()` and `flush-buffer()` maps naturally to `BrainMsg { Think, FlushBuffer }` + `brain_receive(state, msg)`.

2. **Non-resuming `ctl` has no actor equivalent**: The Koka `ctl step-away()` never calls `resume` — execution stops. In hica's actor model, receive functions always return state. The overflow path had to be inlined as direct `println` calls to get unit return and avoid leaking the `WeekendState` as main's return value.

3. **Two `process_messages` calls with different actor types in the same function cause type unification errors**: hica's type inference pins the generic `process_messages` to the first actor type used, then rejects the second. Workaround: separate into different functions, or call receive functions directly.

4. **Receive functions with side effects need inferred return types**: Adding an explicit `: BrainState` return annotation on `brain_receive` fails because Koka sees `console` effects from `println` but the annotation promises `total`. Removing the annotation lets hica infer the correct effectful type.

5. **Struct constructors use named-field syntax**: `BrainState { thoughts: [] }` not `BrainState([])`.

6. **`let` inside `if/else` branches is still broken** — extracted `handle_overflow` as a separate function to avoid the codegen bug.

### Implications for actor design

- Phase 1 actors (state machines) handle the **state + message dispatch** part of effects well.
- They do **not** model control flow effects (non-resuming `ctl`, `resume` with values). This is expected — hica intentionally hides effect handlers.
- For programs that mix state transitions with I/O, the receive function ends up doing side effects. This works but produces unused return values when the state isn't needed. A future `send` function (fire-and-forget, discards state) would help.
- The type unification issue with multiple actor types in one function is a real ergonomic gap that would block multi-actor orchestration patterns.
