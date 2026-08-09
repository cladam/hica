---
layout: default
title: Algebraic Effects - hica
---

# Algebraic Effects

**Status: experimental, since v0.X — `effect` and `handle` are fully parsed, type-checked, and compiled to native Koka. The surface syntax is stable; some advanced features (effect-row polymorphism, stateful handlers) are still in progress.**

hica exposes Koka's effect system in two ways. First, it surfaces built-in effects *implicitly*: `println` gives your function the `<console>` effect, `read_file` gives it `<fsys>`, and so on. Second — the feature this page covers — you can *define your own effects* and *install handlers* for them. This is what algebraic effects actually are: a way to name an abstract capability, use it like a plain function call, and choose at the call site how to fulfil it.

The design document lives at [`documentation/effects-design.md`](../documentation/effects-design.md) if you want the full rationale and spec.

---

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

---

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

---

## Calling operations

Operations are called exactly like ordinary functions — no special punctuation. Inside any block where the effect is handled, the call resolves to the installed handler arm.

```hica
fun render(lines: list<string>) {
  clear_screen()
  foreach(lines, (line) => write(line + "\n"))
}
```

`render` requires the `<Terminal>` effect. `hica check render.hc` will show `[<Terminal, console>]` in the effect row once M3 lands; until then you can verify with `hica build --generate`.

---

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

---

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

---

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

---

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

---

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

---

## Coming in later milestones

| Feature | Milestone |
|---|---|
| **Effect-row polymorphism** — `(A) -> <Db> R` function type syntax | M4 |
| **Stateful handlers** — `handle … with var count = 0 in { … }` | M5 |
| **`actor` keyword** — sugar over `effect + handle + with var` | M6 |

The `with var` clause for stateful handlers (e.g. a Counter or Buffer effect) is *parsed* today but not yet emitted. If you need mutable handler state before M5, declare a `var` in the enclosing scope and capture it in the arm.

---

## See also

- [`documentation/effects-design.md`](../documentation/effects-design.md) — full spec with Koka mapping details
- [`examples/effects/`](../examples/effects/) — runnable examples for every milestone
- [`learn/44-effects-intro.hc`](../learn/44-effects-intro.hc) — interactive intro tutorial
- [`documentation/security-type-boundaries.md`](../documentation/security-type-boundaries.md) — capability security use case (M4)
