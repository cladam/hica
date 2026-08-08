# User-Facing Algebraic Effects in hica

**A design proposal for `effect` definitions, `handle` blocks, and effect-row polymorphic function types**

Status: Draft — pre-implementation design
Owners: hica core
Related: [`backlog.md`](backlog.md) (P3, P4), [`security-type-boundaries.md`](security-type-boundaries.md), [`../src/actors/actors-ideation.md`](../src/actors/actors-ideation.md)

---

## 1. Executive Summary

hica today surfaces Koka's effect system **implicitly**: `println` gets you `<console>`, `read_file` gets you `<fsys>`, `?` gets you an early-return effect, and so on. Users can *observe* effects (via `hica check`) but they cannot *define* their own. This document proposes the language additions needed to close that gap.

The proposal introduces three surface constructs:

1. `effect Name { fun op(...) : T ... }` — declares an effect and the operations that belong to it.
2. `handle Name { op(args) => body, ... } in { block }` — installs a handler that discharges the effect for the enclosed block.
3. `(params) -> <E1, E2> Ret` — optional effect row in function type syntax so signatures can require or restrict effects.

Together these unlock three concrete use cases already documented in the hica repository:

- **Typed capability-based security** (see §2.2 and [`security-type-boundaries.md`](security-type-boundaries.md)) — a library can accept a callback whose type says "you may only use `<Db>` inside me".
- **Testable IO** (see §6) — a terminal editor's pure logic runs against real ANSI in production and against a scripted keystream in tests, using the same code path.
- **First-class actors** (see [`../src/actors/actors-ideation.md`](../src/actors/actors-ideation.md)) — the existing actor prototype currently simulates handlers with plain functions; effects give it real semantics with compile-time exhaustiveness on `receive`.

The feature is delivered in **six milestones** (§9). Milestone 1 alone — parse-and-passthrough — is enough to start building the terminal editor against.

---

## 2. Motivation — Three Scenarios That Are Painful Today

### 2.1 A terminal editor whose IO is tangled into its logic

Without user-defined effects, the loop that responds to keystrokes has to call `print`, `input`, and ANSI escape helpers directly. The editor logic and the terminal driver are the same function. There is no way to test the logic without a real terminal. There is no way to swap the driver for a mock without touching the logic itself.

```hica
// Untestable — IO baked in
fun editor_loop(buf: Buffer) {
  print("\e[2J")               // clear screen
  render(buf)
  let raw = input("")
  match decode(raw) {
    Ctrl('q')  => (),
    Char(c)    => editor_loop(insert(buf, c)),
    Arrow(d)   => editor_loop(move(buf, d)),
    _          => editor_loop(buf)
  }
}
```

### 2.2 A sandbox callback that silently accepts any effect

The backlog entry P4 highlights this exact case:

```hica
// Today — <Db> is not expressible in the signature
pub fun with_sqlite(path: string, f: (Conn) -> ()) : result<bool, string> {
  let conn = open(path)
  f(conn)                       // f may print, spawn processes, read files
  Ok(true)
}
```

The library author *intends* `f` to only touch the database, but the type system has no way to say so. A hostile or careless callback can do anything.

### 2.3 The actor prototype simulates handlers with plain functions

`src/actors/actors-ideation.md` acknowledges this directly:

> **What needs to be added**: `actor` keyword (parser + AST node); `spawn`/`send`/`ask` builtins; codegen: actor → Koka named effect handler.

The current prototype threads state through `process_messages(state, mailbox, receive_fn)`. Every actor invents its own dispatch loop. Two calls with different actor types in the same function fail because hica's generics are locked to the first call site. Real effect handlers eliminate all of this scaffolding.

---

## 3. Design Principles

The proposal commits to five rules. Every syntax choice below follows from these.

**P1 — Operations feel like ordinary function calls at the use site.** No `perform`, no `!`, no distinguished punctuation. If `Terminal` defines `fun move_cursor(row, col)`, then user code just writes `move_cursor(3, 5)` inside a block where `Terminal` is handled. This matches how hica already exposes `println` and `read_file`.

**P2 — Handler exhaustiveness is a compile error, not a runtime crash.** The `match` keyword's exhaustiveness check for enums extends to `handle` blocks over effect operations. Missing an op is a hica error with a span, not a Koka error the user has to decode.

**P3 — Effect rows are optional in function signatures.** Every hica program written today keeps working unchanged. Effect annotations are additive: they *narrow* what a callback may do; the absence of an annotation is unconstrained (matches today's behaviour).

**P4 — Handlers are expressions.** `handle Name { … } in { body }` evaluates to the value of `body`. This matches `if`, `match`, and blocks, and it composes cleanly:

```hica
let final_buffer = handle Terminal { … } in { editor_loop(empty_buffer()) }
```

**P5 — Keywords: `effect` + `handle`.** Matches Koka's terminology (which any escaped error message will use), matches the backlog prose, matches published academic papers. Not `capability`, not `provide`, not `try … with`.

---

## 4. Surface Syntax

### 4.1 Effect declarations

```
effect-def  ::= 'effect' Name '{' op-decl* '}'
op-decl     ::= 'fun' name '(' param-list ')' (':' type)?
param-list  ::= (name (':' type)? (',' name (':' type)?)*)?
```

An effect declaration lives at the top level, alongside `struct` and `type`. The operations are typed just like top-level functions, with two rules specific to effects:

1. **A missing return type defaults to `()`** — same as today's top-level `fun`.
2. **Operation parameters may be typed or untyped.** Untyped parameters get inferred from the handler; typed ones are checked against handler op arms and against call sites.

Effect names are `PascalCase` (like `struct` and `type`); operation names are `snake_case`.

```hica
effect Terminal {
  fun move_cursor(row: int, col: int)
  fun clear_screen()
  fun read_key() : Key
  fun write(s: string)
  fun get_size() : (int, int)
}

effect Db {
  fun query(sql: string, params: list<SqlParam>) : Rows
  fun exec(sql: string, params: list<SqlParam>)
}
```

### 4.2 Calling operations

No new syntax. Operations are invoked exactly like ordinary function calls. The checker recognises the name as an operation and records the effect requirement on the enclosing function.

```hica
fun draw_status(row: int, msg: string) {
  move_cursor(row, 0)     // requires <Terminal>
  clear_screen()          // requires <Terminal>
  write(msg)              // requires <Terminal>
}
```

The inferred type of `draw_status` is `(int, string) -> <Terminal> ()`. The `<Terminal>` shows up in `hica check` output alongside the existing `<console, fsys>` labels.

### 4.3 Handler installation

```
handle-expr ::= 'handle' Name '{' op-arm (',' op-arm)* ','? '}'
                ('with' 'var' name '=' expr (',' 'var' name '=' expr)*)?
                'in' block
op-arm      ::= name '(' param-list ')' '=>' expr
```

The `handle … in { … }` form is an expression. It:

- Discharges the named effect for the code inside the `in` block.
- Requires every operation of the effect to have exactly one arm (exhaustiveness is checked at compile time).
- Evaluates to the value of the block.

```hica
let final = handle Terminal {
  move_cursor(row, col) => print("\e[{row + 1};{col + 1}H"),
  clear_screen()        => print("\e[2J"),
  read_key()            => decode_key(input("")),
  write(s)              => print(s),
  get_size()            => term_size()
} in {
  editor_loop(empty_buffer())
}
```

Missing an op:

```
error: handler for effect 'Terminal' is missing operation 'get_size'
  at editor.hc:47:1
       handle Terminal {
       ^^^^^^^^^^^^^^^^^
```

An op arm that doesn't belong to the effect:

```
error: 'draw_frame' is not an operation of effect 'Terminal'
  at editor.hc:52:3
         draw_frame(f) => ...
         ^^^^^^^^^^
```

### 4.4 Stateful handlers — `with var …`

Many useful handlers need local state: a counter, a buffer, a message queue. The `with var` clause declares one or more mutable bindings visible to every op arm. State is scoped to the handler — it dies when the `in` block returns.

```hica
handle Counter {
  incr() => count = count + 1,
  decr() => count = count - 1,
  get()  => count
} with var count = 0 in {
  incr(); incr(); incr(); decr()
  println(get())        // 2
}
```

Multiple state variables:

```hica
handle Buffer {
  push(x)  => { items = items + [x]; size = size + 1 },
  pop()    => match items {
    []          => None,
    [x, ..rest] => { items = rest; size = size - 1; Some(x) }
  },
  count()  => size
} with var items = [], var size = 0 in {
  push(1); push(2); push(3)
  println(pop())        // Some(3)
}
```

This is the mechanism the actor prototype needs to shed its `process_messages` scaffolding.

### 4.5 Effect rows in function types

Function type syntax gains an optional effect row between the parameter list and the return type.

```
fun-type    ::= '(' type-list ')' '->' effect-row? type
effect-row  ::= '<' effect-name (',' effect-name)* '>'
```

The row is a comma-separated list of effect names inside angle brackets. When present it *requires* those effects and *forbids* any other user-defined effects; built-in effects (`console`, `fsys`, `div`, `ndet`, `exn`, `io`) are always allowed by default in v1.

```hica
// Callback may use <Db>. No other user-defined effect is permitted inside f.
pub fun with_sqlite(path: string, f: () -> <Db> ()) : result<bool, string> {
  let conn = open(path)
  handle Db {
    query(sql, ps) => sqlite_query(conn, sql, ps),
    exec(sql, ps)  => sqlite_exec(conn, sql, ps)
  } in {
    f()
  }
  Ok(true)
}
```

An empty effect row `<>` means "no user-defined effects" — the pure-callback contract.

Absence of an effect row (today's default) is a wildcard: the function admits any effects the checker can infer. This is what keeps the change backwards-compatible.

---

## 5. Semantics

### 5.1 Effect scoping

An effect is *in scope* — that is, its operations may be called — inside the `in` block of a matching `handle`. Nesting works as expected: handlers stack, and the innermost matching handler for an operation is the one that runs.

```hica
handle Terminal { ... } in {
  handle Db { ... } in {
    // both Terminal and Db operations are callable here
    let rows = query("SELECT ...", [])
    write("found {length(rows)} rows")
  }
}
```

An operation call outside any matching handler is a **compile-time** error — the type checker sees that the enclosing function's effect row was never discharged, and refuses to compile `main` (or any top-level function whose effect row is not empty).

### 5.2 Exhaustiveness

Every operation declared in the effect must appear exactly once in the handler. This reuses the `match` exhaustiveness engine — the effect is treated as an enumeration whose "variants" are its operations, and the handler arms are its "cases". Duplicate arms and missing arms both produce hica-level errors with source spans.

### 5.3 Resumption is implicit in v1

In Koka, every `ctl` operation receives a `resume` continuation which it may call zero, one, or many times. hica v1 restricts this: **every handler arm resumes exactly once, automatically, with the value of the arm's body**. The `resume` keyword is not user-facing yet.

Consequences:

- `handle X { op() => body } in { … }` behaves as: run the `in` block; whenever `op()` is called, evaluate `body` and use its value as the result of the call.
- Non-resuming handlers (early termination, coroutines) are deferred. The one case where hica needs non-resumption today — the `?` operator — is already handled internally by the compiler via `hica-early-*` effects and is not exposed as a user-defined pattern.
- Multi-shot resumption (backtracking search, non-determinism) is a v2+ topic.

This restriction covers every use case in the motivating scenarios (§2) and keeps the design surface small.

### 5.4 Handler-local state semantics

`with var x = init` binds `x` for the duration of the `handle … in { … }` expression. Ops read and write `x` freely; the `in` block does *not* see `x` directly. When the `in` block returns, `x` is dropped.

Semantically this desugars to a Koka `var x := init` scoped inside the generated handler function (see §7.3).

### 5.5 Effect visibility in `hica check`

`hica check` already prints a list of inferred effects at the tail of a successful analysis. User-defined effects join the list:

```
$ hica check editor.hc
check: editor.hc — ok (7 declarations, 0 errors) [<Terminal, console, fsys>]
```

Functions with an explicit effect row in their signature are trusted (the row is authoritative). Functions without a row have effects inferred by the analyser as they do today.

---

## 6. The Terminal Editor Walk-through

This is the artefact your motivating use case turns into once Milestone 1 lands.

```hica
// editor.hc
import "std/term"

// -------------------------------------------------------------------
// Domain types
// -------------------------------------------------------------------

type Direction { Up, Down, Left, Right }

type Key {
  Char(c: char),
  Arrow(d: Direction),
  Ctrl(c: char),
  Esc
}

struct Buffer {
  lines: list<string>,
  row: int,
  col: int
}

// -------------------------------------------------------------------
// The Terminal capability
// -------------------------------------------------------------------

effect Terminal {
  fun read_key() : Key
  fun write(s: string)
  fun move_cursor(row: int, col: int)
  fun clear_screen()
  fun get_size() : (int, int)
}

// -------------------------------------------------------------------
// Pure editor logic — parameterised over <Terminal>
// -------------------------------------------------------------------

fun render(buf: Buffer) : <Terminal> () {
  clear_screen()
  foreach(buf.lines, (line) => write(line + "\n"))
  move_cursor(buf.row, buf.col)
}

fun editor_loop(buf: Buffer) : <Terminal> Buffer {
  render(buf)
  match read_key() {
    Ctrl('q')  => buf,
    Char(c)    => editor_loop(insert(buf, c)),
    Arrow(d)   => editor_loop(move(buf, d)),
    _          => editor_loop(buf)
  }
}

// insert / move are ordinary pure functions — omitted for brevity
fun insert(buf: Buffer, c: char) : Buffer => buf
fun move(buf: Buffer, d: Direction) : Buffer => buf

// -------------------------------------------------------------------
// Production entry point — installs the real ANSI handler
// -------------------------------------------------------------------

fun main() {
  let final = handle Terminal {
    read_key()       => decode_key(raw_stdin()),
    write(s)         => print(s),
    move_cursor(r,c) => print("\e[{r + 1};{c + 1}H"),
    clear_screen()   => print("\e[2J"),
    get_size()       => term_size()
  } in {
    editor_loop(empty_buffer())
  }
  println("edited {length(final.lines)} lines")
}
```

Every keystroke, every escape sequence, every terminal query flows through the handler. The `editor_loop` never touches IO directly. That means the same function is trivially testable:

```hica
test "arrow-down moves cursor to next line" {
  var scripted_keys = [Arrow(Down), Ctrl('q')]

  let final = handle Terminal {
    read_key() => match scripted_keys {
      []          => Ctrl('q'),
      [k, ..rest] => { scripted_keys = rest; k }
    },
    write(_s)        => (),
    move_cursor(_,_) => (),
    clear_screen()   => (),
    get_size()       => (24, 80)
  } in {
    editor_loop(Buffer { lines: ["hello", "world"], row: 0, col: 0 })
  }

  assert(final.row == 1)
}
```

Two things to notice:

1. The test never touches a real terminal. It cannot flake because of terminal state, TTY settings, or a stray CI environment.
2. The exact same `editor_loop` runs. There is no test-only branch inside the editor code — the divergence lives entirely in the handler.

This is the pattern that becomes hard or impossible without proper effect definitions.

---

## 7. Codegen — Mapping to Koka

### 7.1 Effect declaration

hica:
```hica
effect Terminal {
  fun read_key() : Key
  fun write(s: string)
  fun move_cursor(row: int, col: int)
  fun clear_screen()
  fun get_size() : (int, int)
}
```

Koka:
```koka
effect terminal
  ctl read-key()                             : key
  ctl write(s : string)                      : ()
  ctl move-cursor(row : int, col : int)      : ()
  ctl clear-screen()                         : ()
  ctl get-size()                             : (int, int)
```

Name mangling:
- Effect name: `Terminal` → `terminal` (lowercase; existing hica convention for user-defined type-level names). The `hc-` prefix is *not* applied — effects live in their own namespace and cannot clash with Koka's builtins.
- Operation name: `read_key` → `read-key` (existing `_`→`-` rewriting).

### 7.2 Operation call

hica:
```hica
let k = read_key()
```

Koka:
```koka
val k = read-key()
```

The checker records that the enclosing function needs the `terminal` effect. Codegen omits any return-type annotation on functions that transitively call user-defined effect ops without an explicit effect-row annotation on the function (same rule already used for `div` and `console`).

### 7.3 Handler installation

hica:
```hica
handle Terminal {
  read_key()       => decode_key(raw_stdin()),
  write(s)         => print(s),
  move_cursor(r,c) => print("\e[{r + 1};{c + 1}H"),
  clear_screen()   => print("\e[2J"),
  get_size()       => term_size()
} in {
  editor_loop(empty_buffer())
}
```

Koka:
```koka
with handler
  ctl read-key()             -> resume(decode-key(raw-stdin()))
  ctl write(s)               -> resume(print(s))
  ctl move-cursor(r, c)      -> resume(print("\e[" ++ (r + 1).show ++ ";" ++ (c + 1).show ++ "H"))
  ctl clear-screen()         -> resume(print("\e[2J"))
  ctl get-size()             -> resume(term-size())
editor-loop(empty-buffer())
```

Two invariants:

- Every arm is wrapped in `resume(...)` because §5.3 mandates auto-resumption.
- The body of the `in` block follows the `with handler` — this is Koka's standard trailing-block form.

### 7.4 Stateful handler

hica:
```hica
handle Counter {
  incr() => count = count + 1,
  decr() => count = count - 1,
  get()  => count
} with var count = 0 in {
  incr(); incr(); println(get())
}
```

Koka:
```koka
var count := 0
with handler
  ctl incr() -> { count := count + 1; resume(()) }
  ctl decr() -> { count := count - 1; resume(()) }
  ctl get()  -> resume(count)
incr(); incr(); println(get())
```

The `var` declaration is hoisted **outside** the `with handler` so both the handler arms and the `in` block share a stable binding. This works because the handler discharges the effect for the entire `in` block, and Koka's `var` is scoped by lexical block. The value is dropped as soon as the surrounding block ends.

### 7.5 Effect rows in function types

hica:
```hica
pub fun with_sqlite(path: string, f: () -> <Db> ()) : result<bool, string> { … }
```

Koka:
```koka
pub fun with-sqlite(path : string, f : () -> <db> ()) : <db> result<bool, string>
```

Note the *inner* `<db>` on the function's own return effect: since `with_sqlite` handles the `<db>` effect internally, its own effect row does not need `<db>` — but if the user has written `<db>` on the callback, it must appear at the callback position, not on the outer function. The codegen handles this automatically.

---

## 8. Type-Checker Sketch

### 8.1 Symbol tables

Alongside the existing struct and type registries, the checker maintains an **effect registry**:

```koka
// pseudo-code sketched against src/semantics/checker.kk
struct effect-info
  name : string
  ops  : list<(string, list<hica-type>, hica-type)>   // (op-name, param-types, return-type)
```

Effect definitions from prelude, imports, and user code all populate this registry. Duplicate effect names across modules follow the same rule as struct duplicates (last one wins with a warning; may be tightened later).

### 8.2 Operation resolution

Operations live in a **separate namespace** from top-level functions. When the checker resolves a bare identifier at a call site, the lookup order is:

1. Local variable
2. Parameter
3. Top-level function / prelude
4. Effect operation (across all defined effects in scope)

If an identifier matches an operation but no matching handler is currently in the checker's effect context, the call succeeds locally and the operation's effect is added to the enclosing function's inferred effect row. It becomes an error only when a top-level entry (`main`, `test`) is reached with un-discharged user effects.

If two effects declare an operation with the same name, the call site must disambiguate: `handle` context resolves it; outside a `handle`, the checker asks for an explicit `EffectName::op(args)` form (deferred until we hit the case in practice).

### 8.3 Handler checking

For each `handle E { arms } in { body }`:

1. Look up effect `E` in the registry. Error if unknown.
2. Check that the set of arm names equals the set of op names of `E`. Report missing ops and unknown ops with spans.
3. For each arm, unify param types with the op signature.
4. Type-check the arm body under the same env as the surrounding code, unified against the op's return type.
5. Type-check `body` under an env that removes `E` from the required-effect row.
6. The whole expression's type equals `body`'s type.

### 8.4 Effect-row unification (M4)

`TFun` gains an effect-row field:

```koka
TFun(params : list<hica-type>, effects : list<string>, result : hica-type)
```

Existing call sites default to an empty effect row (wildcard behaviour). Unification is set-based: `<A, B>` unifies with `<B, A>`. When a function signature has an explicit row, the checker enforces that all operations called within its body belong to that row (union with built-in effects, which are always allowed in v1).

---

## 9. Milestone Plan

| # | Milestone | Files touched | Exit criteria |
|---|-----------|---------------|---------------|
| **M1** | **Parser passthrough** | `syntax/lexer.kk` (add `TkEffect`, `TkHandle`, `TkIn`, `TkWith` is already there); `syntax/ast.kk` (add `effect-def`, `EHandle` expr variant, `program.effects` field); `syntax/parser.kk` (parse `effect` decl at top level, `handle … in` as postfix expr); `emit/codegen.kk` (naïve emit of Koka `effect` and `with handler`) | An `.hc` file with `effect` + `handle` type-checks under lenient rules and produces runnable Koka. Terminal-editor example (§6) runs against a hand-rolled handler. |
| **M2** | **Effect symbol table + exhaustiveness** | `semantics/checker.kk` (effect registry, op resolution, handler exhaustiveness check, error messages with spans) | Missing/extra op arms produce hica-level errors, not Koka errors. Unit tests: 6 regression cases in `tests/test-effects.kk`. |
| **M3** | **Effect names in `hica check` output** | `semantics/analyser.kk` (register user effects; merge into effect-row report) | `hica check editor.hc` prints `[<Terminal, console, fsys>]`. |
| **M4** | **Effect-row polymorphic function types** | `syntax/ast.kk` (`TFun` gets `effects` field); `syntax/parser.kk` (parse `(…) -> <E> T`); `syntax/lexer.kk` (nothing new — `<` and `>` already tokens); `semantics/checker.kk` (row-set unification); `emit/codegen.kk` (emit effect rows in Koka type annotations) | `with_sqlite(path, f: () -> <Db> ())` compiles. Passing a `<Terminal>` callback where `<Db>` is required errors. |
| **M5** | **Stateful handlers — `with var …`** | `syntax/parser.kk` (parse `with var` clauses after `handle` body); `emit/codegen.kk` (hoist `var` outside the `with handler` block) | Counter and Buffer examples run. Actor demo compiles without `process_messages` boilerplate. |
| **M6** | **`actor` keyword as sugar** | `syntax/parser.kk` and `transform/desugar.kk` (rewrite `actor Name { var … receive(msg) => match … }` to `effect Name + handle Name … with var … in …`) | Ping-pong actor example (`src/actors/step5-ping-pong.kk` equivalent) runs. Actor lab-journal step 6 revisited with the new sugar. |

Milestones **M1–M3** cover the terminal-editor use case. **M4** covers the security-boundary sandbox use case. **M5–M6** cover the actor use case.

Each milestone ships with:
- Regression tests in `tests/`.
- One `examples/*.hc` file demonstrating the new capability end-to-end.
- A changelog line.
- (For M2 onward) an `hica check` visible improvement.

---

## 10. Non-Goals for v1

The following are deliberately deferred until concrete demand appears:

- **Non-resuming control flow.** Handlers that `abort` instead of resuming (early termination, coroutines). The one case hica needs today — `?` operator — is compiler-internal and does not motivate the surface feature.
- **Multi-shot resumption.** Backtracking search, non-deterministic choice, list monad style. High implementation cost, no motivator in the current backlog.
- **Named / instantiated effects.** `let c1 = spawn(Counter); let c2 = spawn(Counter)` — two independent handlers of the same effect. Needed for the full actor story; slotted for a phase after M6.
- **Operation-level effect polymorphism.** An operation whose signature mentions an effect variable. Adds significant complexity to the checker; no motivator today.
- **Effect aliases.** `effect Console = { fun log(s: string) }` — sugar for grouping. Can be layered on later without breaking changes.
- **Explicit `resume` in user code.** See §5.3.

---

## 11. Interaction With Existing Features

### 11.1 The `?` operator

`?` currently lowers to a compiler-internal `hica-early-maybe` / `hica-early-result` effect. User-defined effects live in the same Koka effect row as these internal effects, but the two do not conflict: the internal effects have reserved names (`hica-early-*`) that the parser refuses to accept in user `effect` declarations.

A recursive function using `?` and also calling a user effect op ends up in a Koka function with both effects in its inferred row. This is fine — Koka handles it.

### 11.2 Built-in effect inference (`div`, `console`, `fsys`, `ndet`, `exn`, `io`)

The analyser stays authoritative for built-in effects; user effects are added as a parallel channel. When printing the effect row in `hica check` output, built-ins appear first (alphabetical) followed by user effects (declaration order in the file).

### 11.3 Opaque structs and `Trusted`

The sandbox pattern from `security-type-boundaries.md` §7 was previously described as "Planned (P3)". Once M4 ships, the pattern becomes fully expressible:

```hica
import "std/trusted"

effect Sql {
  fun query(sql: Trusted, params: list<SqlParam>) : Rows
}

pub fun with_read_only_db(path: string, f: () -> <Sql> ()) : result<(), string> {
  handle Sql {
    query(sql, ps) => run_readonly(path, trusted_value(sql), ps)
  } in {
    f()
  }
  Ok(())
}
```

Now the callback `f` is doubly constrained: it may only use the `Sql` effect, and every SQL string it produces must have passed through the `Trusted` boundary. Neither constraint can be bypassed without an explicit `trust()` call that appears visibly in code review.

### 11.4 The `actor` prototype

M6 rewrites the existing `actor` keyword (`src/actors/`) as syntactic sugar over `effect` + `handle` + `with var`. The lab-journal experiments already validated that the actor pattern maps cleanly onto handlers; M6 formalises the desugar and removes the `process_messages` scaffolding.

---

## 12. Open Questions

These are intentionally deferred to implementation-time discussion:

1. **Cross-module effect identity.** Structs and enums cross module boundaries by name. Effects need Koka to see a *single* declaration site — importing an effect twice under different names would generate two Koka effects that don't unify. Assumed policy: an effect must be defined exactly once in a module graph; imports refer to that definition. Enforced by the checker at module load.

2. **`pub` visibility on effects and operations.** Does `pub effect Db { … }` export all its ops? Or does each op need its own `pub`? Assumed: `pub` on the effect exports everything (matches `struct`, avoids per-op boilerplate). Revisit if there's demand for private ops.

3. **Formatter rules for `handle` blocks.** Arms on separate lines, trailing comma optional. `with var` clause on its own line before `in`. Match `struct` and `type` conventions.

4. **REPL support.** Can you define an effect at the REPL and use it? M1 says yes for the definition; M2 says yes for handlers. Effect-row polymorphism in the REPL (M4) needs the REPL evaluator to carry effect context between inputs — likely deferred.

5. **`hica fmt` on effect definitions.** Should ops within an effect be aligned? Probably follow the same rules as struct field alignment.

---

## 13. Appendix — Worked Examples

### 13.1 `examples/terminal-effect.hc` (see §6)

The editor walk-through above becomes a runnable example file at M1.

### 13.2 `examples/db-sandbox.hc` (M4 exit criterion)

```hica
import "std/trusted"

struct SqlParam { data: string }
struct Rows     { count: int, cells: list<string> }

effect Db {
  fun query(sql: string, params: list<SqlParam>) : Rows
  fun exec(sql: string, params: list<SqlParam>)
}

pub fun with_sqlite(path: string, f: () -> <Db> ()) : result<bool, string> {
  handle Db {
    query(sql, ps) => Rows { count: 0, cells: [] },   // stub
    exec(sql, ps)  => ()
  } in {
    f()
  }
  Ok(true)
}

fun list_users() : <Db> () {
  let rows = query("SELECT name FROM users", [])
  foreach(rows.cells, (name) => println(name))
}

fun main() {
  match with_sqlite("app.db", list_users) {
    Ok(_)  => println("done"),
    Err(e) => println("error: {e}")
  }
}
```

`list_users` compiles because its inferred effect row `<Db, console>` matches the callback contract `() -> <Db> ()` — `console` is a built-in and always permitted. Passing a function that calls `read_file` would fail: `<fsys>` is not `<Db>`.

### 13.3 `examples/counter-effect.hc` (M5 exit criterion)

```hica
effect Counter {
  fun incr()
  fun decr()
  fun get() : int
}

fun bump_three_times() : <Counter> int {
  incr(); incr(); incr()
  get()
}

fun main() {
  let n = handle Counter {
    incr() => count = count + 1,
    decr() => count = count - 1,
    get()  => count
  } with var count = 0 in {
    bump_three_times()
  }
  println("counter = {n}")   // counter = 3
}
```

### 13.4 Ping-pong actor rewritten with effects (M6 preview)

```hica
type PingMsg { Ping, Pong }

effect Pinger { fun on_message(m: PingMsg) : maybe<PingMsg> }
effect Ponger { fun on_message(m: PingMsg) : maybe<PingMsg> }

fun ping_pong_round(msg: PingMsg) : <Pinger, Ponger> () {
  var current = msg
  while is_some(current) {
    let next = on_message(current.unwrap)  // dispatched by scope; see §8.2
    current = next
  }
}

fun main() {
  handle Pinger {
    on_message(m) => match m {
      Pong => { count = count + 1
                if count < 10 { Some(Ping) } else { None } },
      Ping => None
    }
  } with var count = 0 in {
    handle Ponger {
      on_message(m) => match m {
        Ping => Some(Pong),
        Pong => None
      }
    } in {
      ping_pong_round(Pong)
    }
  }
}
```

(The name-collision on `on_message` is resolved by handler nesting order per §8.2. Named effects — the phase after M6 — would let each actor keep its own operation names cleanly.)

---

## 14. Summary

hica gets three surface constructs:

- `effect Name { fun op(...) : T ... }` — declare a capability.
- `handle Name { op => body, ... } (with var …)? in { block }` — install a handler that discharges the capability.
- `(A, B) -> <E1, E2> R` — optional effect row in function type syntax so signatures can restrict what callbacks may do.

Six milestones, each shippable independently, each with its own regression tests and one runnable example. Milestone 1 alone is enough to start building your terminal editor. Milestone 4 unlocks the compile-time capability-based security story that `security-type-boundaries.md` §7 currently lists as "Planned". Milestone 6 finishes the actor story.

Backwards compatibility: **100%**. Every hica program written today keeps working. Effect rows are additive; the absence of a row is the current wildcard behaviour.

Ready to implement M1.
