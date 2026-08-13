---
layout: default
title: Algebraic Effects - hica
---

# Algebraic Effects

**Status: experimental, since v0.48.X — `effect` and `handle` are fully parsed, type-checked, and compiled to native Koka. The surface syntax is stable; some advanced features (effect-row polymorphism, stateful handlers) are still in progress.**

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

Operations are called exactly like ordinary functions — no special punctuation. Inside any block where the effect is handled, the call resolves to the installed handler arm.

```hica
fun render(lines: list<string>) {
  clear_screen()
  foreach(lines, (line) => write(line + "\n"))
}
```

`render` requires the `<Terminal>` effect. `hica check render.hc` will show `[<Terminal, console>]` in the effect row once M3 lands; until then you can verify with `hica build --generate`.

## Installing a handler

```hica
handle EffectName {
  op1(args) => body,
  op2()     => body
} in {
  // code that may call op1, op2, …
}
```

**Rules:**

1. Every operation declared by the effect must have exactly one arm. Missing an op is a compile error.
2. An arm for an op that doesn't belong to the effect is a compile error.
3. Duplicate arms for the same op are a compile error.
4. The whole `handle … in { … }` is an *expression* — it evaluates to the value of the `in` block.

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

`handle … in { … }` evaluates to the value of the `in` block:

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

Real-world handlers often need to keep a running value: a counter, a buffer, an accumulator, a message queue. The `with var …` clause after the arm list declares one or more mutable bindings that live for the duration of the surrounding `handle … in { … }` expression:

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
3. Bindings die when the `in` block returns — there is no way for the state to escape the handler.
4. Every `handle … in { … }` gets a fresh binding. Calling the same handler-installing function twice does not share state between calls.

Assign to state bindings the same way you would to any `var`:

```hica
incr() => count = count + 1     // arm body is an assignment
```

The handler internally splits the assignment out from the auto-resume so both the mutation and the `()` return value happen, in that order. If you want a value from the arm, put the value expression *last*:

```hica
add(n) => { count = count + n; count }   // mutate, then return the new value
```

### Why this matters for testing

Because the state lives inside the handler expression, tests never need a `beforeEach` reset — every test creates a fresh handler with fresh state:

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

Arm bodies can be plain expressions, `{ … }` blocks that mutate state, or
`match` expressions with block-shaped cases (see `buffer.hc`). The compiler
hoists complex arm-body values into a local `val` before calling
`resume(…)` so Koka's layout parser sees a clean expression.


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

The test never touches a real terminal. It cannot flake because of terminal state, TTY settings, or CI environment. The `editor_loop` logic is identical in both cases — the divergence is entirely in the handler.

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

Effect rows are compared **as sets** — `<A, B>` unifies with `<B, A>`.

## The `actor` keyword

An `actor` declaration is sugar over `effect + handle + with var`. Reach for it when you have a chunk of stateful, message-driven logic that would otherwise clutter every call site with a hand-written `handle Actor { … } with var … in { … }`.

```hica
type CounterMsg { Incr, Decr, Reset }

actor Counter {
  var count = 0

  receive(msg: CounterMsg) => match msg {
    Incr  => count = count + 1,
    Decr  => count = count - 1,
    Reset => count = 0
  }
}
```

The declaration above expands to *two* top-level items:

1. `effect Counter { fun send_counter(msg: CounterMsg) : () }`
2. `pub fun with_counter(action) { handle Counter { send_counter(msg) => <receive body> } with var count = 0 in { action() } }`

You install the actor via `with_<name>(fn() { … })`, then send messages inside:

```hica
fun main() {
  with_counter(() => {
    send_counter(Incr)
    send_counter(Incr)
    send_counter(Incr)
    send_counter(Decr)
    println("done")
  })
}
```

**Rules and constraints:**

- Actor names are **PascalCase** (like `struct` and `effect`).
- State fields are declared as `var name = init` (with optional `: T` annotation), one per line.
- The `receive(msg: MsgType) => body` header is required, and the `msg` parameter must carry an explicit type annotation; hica needs it to figure out what messages the actor accepts.
- Each actor gets one op named `send_<name>` (e.g. `send_counter`, `send_pinger`). This convention sidesteps the flat effect-op namespace so multiple actors coexist without collision. When named effects is implemented, the surface will collapse to `counter.send(Incr)`.
- Actor sends are unit-typed. If you need to observe state after the callback, capture it into an outer `var` (see `learn/47-effects-actors.hc`).

**Two-actor example:**

```hica
type PingerMsg { Pong }
type PongerMsg { Ping }

actor Pinger {
  var pongs = 0
  receive(msg: PingerMsg) => match msg {
    Pong => pongs = pongs + 1
  }
}

actor Ponger {
  var pings = 0
  receive(msg: PongerMsg) => match msg {
    Ping => pings = pings + 1
  }
}

fun main() {
  with_pinger(() => {
    with_ponger(() => {
      send_ponger(Ping)
      send_pinger(Pong)
    })
  })
}
```

See `examples/effects/counter-actor.hc` (single actor) and `examples/effects/ping-pong-actor.hc` (two actors, one file) for the full pattern.

## See also

- [`documentation/effects-design.md`](../documentation/effects-design.md) — full spec with Koka mapping details
- [`examples/effects/`](../examples/effects/) — runnable examples for every milestone
- [`learn/44-effects-intro.hc`](../learn/44-effects-intro.hc) — interactive intro tutorial
- [`documentation/security-type-boundaries.md`](../documentation/security-type-boundaries.md) — capability security use case (M4)
