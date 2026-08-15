---
layout: default
title: Algebraic Effects - hica
---

# Algebraic Effects

hica exposes Koka's effect system in two ways. First, it surfaces built-in effects *implicitly*: `println` gives your function the `<console>` effect, `read_file` gives it `<fsys>`, and so on. Second, you can *define your own effects* and *install handlers* for them. This is what algebraic effects actually are: a way to name an abstract capability, use it like a plain function call, and choose at the call site how to fulfil it.

## The problem effects solve

Consider a logging function baked directly into business logic:

```hica
fun process_order(order: Order) {
  println("[LOG] processing " + order.id)   // IO baked in
  let result = apply_discounts(order)
  println("[LOG] done, total = " + show(result.total))
  result
}
```

You cannot test `process_order` without seeing stdout output. You cannot swap the logging backend (file, structured JSON, silent) without changing the function. The IO and the logic are entangled.

With an effect, you name the capability your logic needs and let the *caller* decide how to fulfil it:

```hica
effect Log {
  fun info(s: string)
}

fun process_order(order: Order) {
  info("processing " + order.id)     // abstract — no IO here
  let result = apply_discounts(order)
  info("done, total = " + show(result.total))
  result
}
```

`process_order` is now pure with respect to logging. You install a real handler at the application boundary and a silent or collecting handler in tests.

## Declaring an effect

```hica
effect Name {
  fun op1(param: Type) : ReturnType
  fun op2()                           // return type defaults to ()
  fun op3(a: int, b: int) : bool
}
```

- Effect names are **PascalCase**.
- Operation names are **snake_case**, exactly like top-level functions.
- A missing return type defaults to `()`.
- An effect declaration lives at the top level, alongside `struct` and `type`.

```hica
effect Terminal {
  fun read_key() : Key
  fun write(s: string)
  fun move_cursor(row: int, col: int)
  fun clear_screen()
}

effect Db {
  fun query(sql: string) : list<Row>
  fun exec(sql: string)
}
```

## Calling operations

Operations are called exactly like ordinary functions, no special punctuation. Inside any block where the effect is handled, the call resolves to the installed handler arm.

```hica
fun render(lines: list<string>) {
  clear_screen()
  foreach(lines, (line) => write(line + "\n"))
}
```

`render` requires the `<Terminal>` effect. `hica check render.hc` will show `[<Terminal, console>]` in the effect row.

## Installing a handler

```hica
handle EffectName {
  op1(args) => body,
  op2()     => body
} in {
  // code that may call op1, op2, ...
}
```

**Rules:**

1. Every operation declared by the effect must have exactly one arm. Missing an op is a compile error.
2. An arm for an op that doesn't belong to the effect is a compile error.
3. Duplicate arms for the same op are a compile error.
4. The whole `handle ... in { ... }` is an *expression*, it evaluates to the value of the `in` block.

```hica
fun main() {
  handle Terminal {
    read_key()         => decode_key(raw_stdin()),
    write(s)           => print(s),
    move_cursor(r, c)  => print("\e[{r + 1};{c + 1}H"),
    clear_screen()     => print("\e[2J")
  } in {
    render(["hello", "world"])
  }
}
```

### Error examples

```
// Missing an op:
handle Terminal {
  write(s) => print(s)      // forgot the others
} in { render(buf) }

error: handler for effect 'Terminal' is missing operation 'read_key'
  at editor.hc:14:1
       handle Terminal {
       ^^^^^^^^^^^^^^^^^
```

```
// Unknown op:
handle Log {
  info(s)    => println(s),
  warning(s) => println("[WARN] " + s)   // warning is not in Log
} in { … }

error: 'warning' is not an operation of effect 'Log'
  at editor.hc:16:3
         warning(s) => println("[WARN] " + s)
         ^^^^^^^
```

## Arm-parameter typing

Handler arm parameters are typed automatically from the effect declaration. You do not need to annotate them:

```hica
effect Math {
  fun add(a: int, b: int) : int
}

handle Math {
  add(a, b) => a + b    // a and b are already int — no annotation needed
} in {
  println(show(add(2, 3)))     // prints 5
}
```

The checker looks up `add`'s declared signature `(int, int) -> int`, freshens the type variables, and binds `a` and `b` to `int` before inferring the arm body. If you return the wrong type from the arm, you get a hica-level error at the handler definition, not a confusing Koka error.

## Handlers are expressions

`handle ... in { ... }` evaluates to the value of the `in` block:

```hica
let result = handle Math {
  add(a, b) => a + b,
  mul(a, b) => a * b
} in {
  add(mul(2, 3), mul(4, 5))   // 6 + 20 = 26
}
println(show(result))         // 26
```

This composes with `let`, `if`, `match`, and everywhere else expressions are expected.

## Handlers with local state

Real-world handlers often need to keep a running value: a counter, a buffer, an accumulator, a message queue. The `with var ...` clause after the arm list declares one or more mutable bindings that live for the duration of the surrounding `handle ... in { ... }` expression:

```hica
effect Counter {
  fun incr()
  fun get() : int
}

fun main() {
  let n = handle Counter {
    incr() => count = count + 1,
    get()  => count
  } with var count = 0 in {
    incr()
    incr()
    incr()
    get()
  }
  println("counter = {show(n)}")   // counter = 3
}
```

Rules:

1. Each `var name = expr` is a separate binding. Multiple bindings share one `with var` clause and are separated by commas: `with var items = [], var size = 0`.
2. Bindings are visible to **every arm** and to the `in { … }` block.
3. Bindings die when the `in` block returns. There is no way for the state to escape the handler.
4. Every `handle ... in { ... }` gets a fresh binding. Calling the same handler-installing function twice does not share state between calls.

Assign to state bindings the same way you would to any `var`:

```hica
incr() => count = count + 1     // arm body is an assignment
```

The handler internally splits the assignment out from the auto-resume so both the mutation and the `()` return value happen, in that order. If you want a value from the arm, put the value expression *last*:

```hica
add(n) => { count = count + n; count }   // mutate, then return the new value
```

### Why this matters for testing

Because the state lives inside the handler expression, tests never need a `beforeEach` reset. 
Every test creates a fresh handler with fresh state:

```hica
test "counter starts at zero" {
  let n = handle Counter {
    incr() => count = count + 1,
    get()  => count
  } with var count = 0 in {
    get()
  }
  assert_eq(0, n)
}

test "counter counts three" {
  let n = handle Counter {
    incr() => count = count + 1,
    get()  => count
  } with var count = 0 in {
    incr(); incr(); incr()
    get()
  }
  assert_eq(3, n)
}
```

See:
- `examples/effects/counter.hc` — the minimal single-var handler
- `examples/effects/buffer.hc`  — multi-var state with a match-shaped `pop()` arm
- `learn/45-effects-state.hc`  — a longer walk-through with fresh-state and non-zero-start examples

Arm bodies can be plain expressions, `{ ... }` blocks that mutate state, or
`match` expressions with block-shaped cases (see `buffer.hc`). The compiler
hoists complex arm-body values into a local `val` before calling
`resume(...)` so Koka's layout parser sees a clean expression.


## Testing with different handlers

The same function can be tested by swapping the handler. No production code changes:

```hica
// Production — real ANSI terminal
fun main() {
  handle Terminal { … real ANSI ops … } in {
    editor_loop(empty_buffer())
  }
}

// Test — scripted keystream, no terminal required
test "arrow-down moves cursor" {
  var key_idx = 0
  val keys = [Arrow(Down), Ctrl('q')]

  let final = handle Terminal {
    read_key()         => { val k = keys[key_idx]; key_idx = key_idx + 1; k },
    write(_s)          => (),
    move_cursor(_r, _c) => (),
    clear_screen()     => ()
  } in {
    editor_loop(Buffer { lines: ["hello", "world"], row: 0, col: 0 })
  }

  assert(final.row == 1)
}
```

The test never touches a real terminal. It cannot flake because of terminal state, TTY settings, or CI environment. The `editor_loop` logic is identical in both cases, the divergence is entirely in the handler.

## Nesting handlers

Effects stack. Code inside an inner `handle` can use both the outer and inner effects:

```hica
handle Log {
  info(s) => println("[LOG] " + s)
} in {
  handle Db {
    query(sql) => run_query(conn, sql),
    exec(sql)  => run_exec(conn, sql)
  } in {
    info("querying…")                    // uses Log
    let rows = query("SELECT * FROM t")  // uses Db
    info("got " + show(length(rows)) + " rows")
    rows
  }
}
```

The innermost matching handler wins for each operation.

## Effect rows in function types (M4)

Function type annotations can restrict which user-defined effects a callback is allowed to use. The row goes between the parameter list and the return type:

```hica
(A, B) -> <E1, E2> R
```

An **empty row (or no row)** is a wildcard: the function accepts any effects the checker can infer. This is the pre-M4 default and keeps every existing hica program working unchanged. A **non-empty row** is authoritative: the argument passed at every call site must call only ops declared in that row (plus built-in effects — `console`, `fsys`, `div`, etc. — which are always allowed in v1).

The canonical use case is a **capability-based sandbox**: a library accepts a callback and guarantees that the callback can only use one specific effect:

```hica
effect Db {
  fun query(sql: string) : int
  fun exec(sql: string)
}

// The `f: () -> <Db> int` type says: `f` may only use <Db>.
pub fun with_db(f: () -> <Db> int) : int {
  handle Db {
    query(sql) => run_query(sql),
    exec(sql)  => run_exec(sql)
  } in {
    f()
  }
}

// This callback is compliant — it only uses <Db>.
fun list_users() : <Db> int {
  exec("UPDATE stats SET last_scan = now()")
  query("SELECT count(*) FROM users")
}

fun main() {
  let count = with_db(list_users)
  println("users = " + show(count))
}
```

If the callback tries to use another user-defined effect, the checker rejects the *call site*:

```hica
effect Log {
  fun audit(msg: string)
}

fun leaky_write() : int {
  audit("touching users table")        // uses <Log> — not permitted
  exec("INSERT INTO audit VALUES ('leak')")
  0
}

fun main() {
  let n = with_db(leaky_write)         // ← error here
}
```

```
error: effect row mismatch — callback passed to 'with_db' may use
  <Log, Db>, not permitted by <Db>
 41 |   let n = with_db(leaky_write)
    |                   ^^^^^^^^^^^
```

The check follows references: passing a top-level function like `leaky_write` walks that function's body; passing an inline lambda walks the lambda body directly. See `examples/effects/db-sandbox.hc` (positive) and `examples/effects/db-sandbox-leak.hc` (negative) for the full motivator.

**Empty row `<>`** means "no user-defined effects". Any call to a user-defined effect op inside such a callback is rejected.

Effect rows are compared **as sets**: `<A, B>` unifies with `<B, A>`.

## The `actor` keyword

An `actor` declaration is sugar over `effect + spawn + ref.op()`. Reach for it when you have a chunk of stateful, message-driven logic and want a compact way to declare the *shape* of the effect; the actor name, message type, and receive contract.

The actor sugar expands to a single item, an effect declaration with a bare `send(msg)` operation. You install instances with `spawn Name { ... } as ref` and dispatch with `ref.send(msg)`:

```hica
type CounterMsg { Incr, Decr, Reset }

actor Counter {
  var count = 0

  receive(msg: CounterMsg) => match msg {
    Incr  => { }
    Decr  => { }
    Reset => { }
  }
}
```

The declaration expands to:

```hica
effect Counter { fun send(msg: CounterMsg) : () }
```

The `var` and `receive` body inside `actor { ... }` are informational (they describe intent) but the real state and behaviour live at each `spawn` site. Users install an instance and drive it top-to-bottom:

```hica
fun main() {
  spawn Counter {
    send(msg) => match msg {
      Incr  => count = count + 1,
      Decr  => count = count - 1,
      Reset => count = 0
    }
  } with var count = 0 as counter

  counter.send(Incr)
  counter.send(Incr)
  counter.send(Decr)
  println("done")
}
```

**Rules and constraints:**

- Actor names are **PascalCase** (like `struct` and `effect`).
- State fields are declared as `var name = init` on the actor block; they document the shape, but each `spawn` site declares its own concrete state via `with var ... = ...`.
- The `receive(msg: MsgType) => body` header is required, and the `msg` parameter must carry an explicit type annotation; hica needs it to figure out what messages the actor accepts.
- The generated op is a bare `send(msg)`, per-instance dispatch (`counter.send(m)`, `bank.send(m)`) tells two actors apart by reference, not by op name.
- Actor sends are unit-typed. If you need to observe state after the block, capture it into an outer `var`.

**Two-actor example: no name-suffix workaround, no callback tower:**

```hica
type PingerMsg { Pong }
type PongerMsg { Ping }

actor Pinger {
  var pongs = 0
  receive(msg: PingerMsg) => match msg {
    Pong => { }
  }
}

actor Ponger {
  var pings = 0
  receive(msg: PongerMsg) => match msg {
    Ping => { }
  }
}

fun main() {
  spawn Pinger {
    send(msg) => match msg {
      Pong => pongs = pongs + 1
    }
  } with var pongs = 0 as pinger

  spawn Ponger {
    send(msg) => match msg {
      Ping => pings = pings + 1
    }
  } with var pings = 0 as ponger

  ponger.send(Ping)
  pinger.send(Pong)
}
```

Both actors declare `send(msg)`, the reference (`pinger` vs `ponger`) disambiguates. Under the hood the codegen emits `pinger.hc_pinger_send(...)` / `ponger.hc_ponger_send(...)` (effect-qualified op names) so Koka's `hc_<op>/@select` selectors don't collide.

See `examples/effects/counter-actor.hc` (single actor) and `examples/effects/ping-pong-actor.hc` (two actors, one file) for the full pattern.

## Named effects

Every `handle Name { ... }` gives you **one** handler instance per lexical
scope. That's enough for capability sandboxes and one-shot state, but
breaks the moment you need two independent instances of the same effect: a worker pool, a ping-pong actor, two Db connections. **Named effects
fix that.** The full design lives in
[`documentation/named-effects-design.md`](../documentation/named-effects-design.md);
this section is the user-facing quick-start.

### `spawn Name { arms } as ref`

Install a fresh handler instance and bind the reference:

```hica
effect Counter {
  fun incr()
  fun get() : int
}

fun main() {
  spawn Counter {
    incr() => count = count + 1,
    get() => count
  } with var count = 0 as c1

  spawn Counter {
    incr() => count = count + 1,
    get() => count
  } with var count = 100 as c2

  c1.incr(); c1.incr(); c1.incr()   // c1 = 3
  c2.incr()                          // c2 = 101

  println("c1 = {show(c1.get())}")
  println("c2 = {show(c2.get())}")
}
```

### `ref.op(args)` — per-instance dispatch

Each reference points at its own handler. Dispatch is by reference, not
by lexical shadow: `c1.incr()` mutates `c1`'s counter, `c2.incr()`
mutates `c2`'s. State is fully isolated.

### Interoperability with `handle`

The same effect can be used both ways in the same program. When any
`spawn E` appears in a program, `E` is promoted to Koka's `named effect`
shape, this is invisible at the hica surface but flows through cleanly to codegen.

### `ref<Name>` in function signatures

References are first-class values. Pass a `ref<Counter>` to any helper
that needs to dispatch on it:

```hica
fun bump(c: ref<Counter>, n: int) {
  if n > 0 {
    c.incr()
    bump(c, n - 1)
  }
}

fun main() {
  spawn Counter {
    incr() => count = count + 1,
    get() => count
  } with var count = 0 as w1

  bump(w1, 5)                        // pass ref to helper
  println("w1 = {show(w1.get())}")   // w1 = 5
}
```

The `ref<Counter>` type parses in any type-annotation position (function
parameters, return types, `let` annotations). Internally it's `TRef(Counter)`
and lowers to Koka's `ev<counter>` (evidence for the named effect).

### The escape rule

`spawn Name … as r` binds `r` for the rest of the enclosing block. The
underlying Koka handler is torn down when the block exits, so a locally
spawned reference cannot outlive its scope:

```hica
fun make_counter() : ref<Counter> {
  spawn Counter {
    incr() => count = count + 1,
    get() => count
  } with var count = 0 as c
  c                       // ← error: escapes its handler's scope
}
```

The checker rejects this at check-time:

```
error: reference of type 'ref<…>' escapes its handler's scope
  note: 'c' was spawned locally and its handler ends when the
        enclosing block exits
```

Refs that arrive as **function parameters** belong to the caller and can
be returned or passed onward freely, only locally spawned refs are restricted.

### Known limitation: inline `.op()` inside untyped `foreach` lambdas

The checker's per-instance dispatch fires when the receiver's inferred
type is `TRef(E)`. Inside a `foreach((w) => w.incr())` lambda, the
parameter `w` starts as a fresh type variable; the type isn't unified
back to `ref<E>` in time, so the dispatch falls through to the ordinary
UFCS path and reports a mismatch. 
Workaround: declare a `ref<E>`-typed helper and call it from the lambda:

```hica
// Instead of this (currently unsupported):
// workers.foreach((w) => w.incr())

// Use a helper:
fun bump(c: ref<Counter>, n: int) {
  if n > 0 { c.incr(); bump(c, n - 1) }
}

workers.foreach((w) => bump(w, 1))
```

Broader inference into `foreach`-style callbacks is queued for N4.

### What's still deferred

- **`hica check` output for spawned effects.** Row reporting currently
  doesn't add `<Counter>` for ref-dispatched calls in every scenario.
  Lands in N4.
- **Ref dispatch inside untyped lambdas.** See the limitation above.

See the runnable examples
[`examples/effects/two-counters.hc`](../examples/effects/two-counters.hc)
and [`examples/effects/counter-pool.hc`](../examples/effects/counter-pool.hc),
and the tutorial
[`learn/48-named-effects.hc`](../learn/48-named-effects.hc).

## See also

- [`documentation/effects-design.md`](../documentation/effects-design.md) — full spec with Koka mapping details
- [`documentation/named-effects-design.md`](../documentation/named-effects-design.md) — v2 named effects (`spawn` + `ref.op()`)
- [`examples/effects/`](../examples/effects/) — runnable examples for every milestone
- [`learn/44-effects-intro.hc`](../learn/44-effects-intro.hc) — interactive intro tutorial
- [`documentation/security-type-boundaries.md`](../documentation/security-type-boundaries.md) — capability security use case (M4)
