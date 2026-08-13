# Named / Instantiated Effects in hica

**A design proposal for `spawn Name { … } as ref` and per-instance operation
dispatch — the natural v2 of user-facing algebraic effects.**

Status: Draft — pre-implementation design
Owners: hica core
Related: [`effects-design.md`](effects-design.md) (v1 effects, §10 non-goals),
[`effects-journal.md`](effects-journal.md) (M1–M6.5 shipped),
[`retrospective-effects.md`](retrospective-effects.md),
[`../src/actors/lab-journal.md`](../src/actors/lab-journal.md) (Step 4 & 5),
[`../src/actors/step4-named-instances.kk`](../src/actors/step4-named-instances.kk),
[`../src/actors/step5-ping-pong.kk`](../src/actors/step5-ping-pong.kk).

---

## 1. Executive Summary

hica v1 effects (M1–M6.5) give us one thing: **one handler per effect, per
lexical scope.** That's enough for capability-based security (M4's
`db-sandbox.hc`), stateful handlers (M5's `counter.hc` / `buffer.hc`), and
single-instance actors (M6's `counter-actor.hc`). It is *not* enough for:

- Two counters in one function with independent state.
- Two actors of the same type communicating (the M6 ping-pong workaround
  had to name each actor's op `send_pinger` / `send_ponger` and nest
  `with_pinger(() => with_ponger(…))` to sidestep a single flat namespace).
- Actor registries, actor pools, dynamically-spawned workers.
- Two `Db` handlers over different connections in the same function.

This document proposes the language additions needed to close that gap.

The proposal introduces two surface constructs and one type-level change:

1. **`spawn Name { arms } (with var …)? as ref`** — creates a fresh
   *instance* of an effect handler and binds it to a value.
2. **`ref.op(args)`** — per-instance operation dispatch. Two instances of
   the same effect coexist without name collisions.
3. **`ref<Name>`** — the type of an instance reference. First-class,
   passable to functions, storable in lists, closable-over.

The mechanism maps 1:1 to Koka's `named effect` + `with h <- named handler`
form, already proven in `src/actors/step4-named-instances.kk` and
`step5-ping-pong.kk`.

Three concrete outcomes unlocked by this feature:

- **Actor registries.** `let workers = [spawn Counter { … } as w1,
  spawn Counter { … } as w2, spawn Counter { … } as w3]` — then
  `workers.foreach(w => w.incr())`.
- **Ping-pong without workarounds.** Both actors declare a `send(msg)`
  op; each instance dispatches independently. The M6 `send_<name>`
  workaround retires.
- **Multi-connection Db.** `with_sqlite(prod) as prod_db; with_sqlite(cache)
  as cache_db; …` — capability-based security scales to multi-tenant.

The feature is delivered in **five milestones** (§9). Milestone N1 alone
— parse-and-passthrough with a working two-counters example — validates
the whole approach.

Backwards compatibility: **100%**. Every hica v1 effect program keeps
working. `handle Name { … } in { … }` continues to install a single
implicit-target handler. `spawn` is a new keyword; no existing program
uses it.

---

## 2. Motivation — Three Scenarios v1 Cannot Express

### 2.1 Two counters in one function

With v1 effects, you can have *one* Counter handler in scope at a time.
Nested `handle Counter { … }` blocks shadow: the inner handler wins for
every `incr()` call inside its `in { … }` block, and the outer handler
becomes unreachable.

```hica
// v1 — the inner handler completely masks the outer one.
let outer = handle Counter {
  incr() => count = count + 1,
  get()  => count
} with var count = 0 in {
  handle Counter {          // shadows the outer Counter
    incr() => count = count + 1,
    get()  => count
  } with var count = 100 in {
    incr()                  // hits inner handler → 101
    incr()                  // hits inner handler → 102
    get()                   // returns 102
  }                         // outer count is still 0 here
}
```

There is no way to write `outer.incr()` and `inner.incr()` and have them
target different handlers. The v1 dispatch rule is lexical, not by-reference.

### 2.2 The M6 ping-pong `send_<name>` workaround

`examples/effects/ping-pong-actor.hc` today reads:

```hica
actor Pinger { var pongs = 0; receive(msg: PingerMsg) => … }
actor Ponger { var pings = 0; receive(msg: PongerMsg) => … }

fun main() {
  with_pinger(() => {
    with_ponger(() => {
      rally(3)              // calls send_pinger(Pong) and send_ponger(Ping)
    })
  })
}
```

The compiler generates `send_pinger(msg)` and `send_ponger(msg)` as the ops
because a single flat op namespace can't hold two `send(msg)` declarations.
This works but leaks the implementation into the user surface: users see
`send_pinger` in their own code, not just in generated Koka.

With named effects, the same file becomes:

```hica
actor Pinger { var pongs = 0; receive(msg: PingerMsg) => … }
actor Ponger { var pings = 0; receive(msg: PongerMsg) => … }

fun main() {
  spawn Pinger as pinger    // fresh Pinger instance
  spawn Ponger as ponger    // fresh Ponger instance
  rally(pinger, ponger, 3)
}

fun rally(pinger: ref<Pinger>, ponger: ref<Ponger>, rounds: int) {
  if rounds > 0 {
    ponger.send(Ping)       // per-instance dispatch, unambiguous
    pinger.send(Pong)
    rally(pinger, ponger, rounds - 1)
  }
}
```

### 2.3 Actor pools and registries

A worker pool is one actor type spawned N times, each with its own state:

```hica
// Impossible in v1 — there is only one Counter handler.
fun spawn_workers(n: int) : list<ref<Counter>> {
  if n == 0 { [] }
  else {
    spawn Counter as w
    [w] + spawn_workers(n - 1)
  }
}

fun distribute(workers: list<ref<Counter>>, jobs: list<int>) {
  jobs.foreach((job) => {
    let w = round_robin(workers)
    w.incr()
  })
}
```

Step 4 of the actor lab-journal already proved Koka handles this cleanly
via named effects. hica needs the surface syntax to expose it.

---

## 3. Design Principles

Five commitments. Every syntax choice below follows from these.

**P1 — Named effects are a strict superset of v1 effects.** Every existing
`effect Name { … }` declaration continues to work. Every existing `handle
Name { … } in { … }` continues to work. A user who never writes `spawn`
never notices the feature exists.

**P2 — `spawn` binds a reference, `ref.op(args)` dispatches to it.** No
new operator syntax, no `!` or `?` shortcuts (§10 defers actor-style
sugar). Method-call syntax on references reuses hica's existing dot-form,
which every hica user already knows from struct field access.

**P3 — Reference lifetime is lexical.** A `spawn Name as r` binds `r` for
the rest of the enclosing block. When the block ends, the handler is torn
down and `r` becomes unusable. This matches Koka's `with h <- named
handler` scope rule and keeps the model simple: no explicit destroy, no
garbage collection.

**P4 — References are first-class values.** `ref<Name>` is a type. You can
pass a reference to a function, return it up the call stack (as long as
the *handler's* enclosing scope is still live), store it in a list, close
over it in a lambda. §5.5 covers the "handler-must-outlive-reference"
rule.

**P5 — Named and un-named live side-by-side.** A single effect declaration
supports both dispatch styles. `handle Db { … } in { … }` still works;
`spawn Db { … } as prod` also works. The compiler picks the emit shape
based on whether the effect is used named or plain in that scope. §7.6
covers the codegen decision.

---

## 4. Surface Syntax

### 4.1 Effect declarations — unchanged

Same syntax as v1. An effect declared once serves both styles.

```hica
effect Counter {
  fun incr()
  fun decr()
  fun get() : int
}
```

No new keywords on the declaration side. The instance-or-not decision is
made at the *use* site.

### 4.2 `spawn` — install a fresh instance

```
spawn-stmt   ::= 'spawn' Name '{' op-arm (',' op-arm)* ','? '}'
                 ('with' 'var' name '=' expr (',' 'var' name '=' expr)*)?
                 'as' ident
op-arm       ::= name '(' param-list ')' '=>' expr        (* same as handle *)
```

Reads: "install a new handler for effect `Name`, using these arms and this
state, and bind the resulting reference to `ident`." The op arms are
identical to v1 `handle`'s arms; the trailing `as ident` is the only
new syntax.

```hica
spawn Counter {
  incr() => count = count + 1,
  decr() => count = count - 1,
  get()  => count
} with var count = 0 as c1

spawn Counter {
  incr() => count = count + 1,
  decr() => count = count - 1,
  get()  => count
} with var count = 100 as c2
```

`c1` and `c2` are two independent Counter references. Their state is
completely isolated.

### 4.3 Reference dispatch — `ref.op(args)`

No new dispatch syntax. `c1.incr()` reuses hica's existing dot-syntax
grammar (currently used for struct field access and pipeline calls).

```hica
c1.incr()          // c1's count → 1
c1.incr()          // c1's count → 2
c2.decr()          // c2's count → 99

println(c1.get())  // 2
println(c2.get())  // 99
```

The compiler resolves the dispatch by looking at `c1`'s inferred type
(`ref<Counter>`) and finding `incr` in `Counter`'s op table. If `Counter`
has no `incr` op, the compiler reports:

```
error: 'incr' is not an operation of effect 'Counter'
  at pool.hc:42:6
       c1.incr()
          ^^^^
```

### 4.4 The `ref<Name>` type

```
type        ::= … | 'ref' '<' effect-name '>'
```

A first-class type carrying a reference to a `Name` handler instance. It
appears in function signatures, struct fields, list types, etc.:

```hica
fun bump(c: ref<Counter>, n: int) {
  if n > 0 {
    c.incr()
    bump(c, n - 1)
  }
}

struct WorkerPool { workers: list<ref<Counter>> }

fun pool_of(n: int) : list<ref<Counter>> {
  if n == 0 { [] }
  else {
    spawn Counter {
      incr() => count = count + 1,
      decr() => count = count - 1,
      get()  => count
    } with var count = 0 as w
    [w] + pool_of(n - 1)
  }
}
```

### 4.5 Effect rows in function types — reference-aware

v1's effect rows (`(A) -> <E1, E2> R`) restrict which *effect names* a
callback may use. With named effects, a function that dispatches on a
`ref<Counter>` still needs `<Counter>` in its effect row — the reference
carries the effect obligation.

```hica
// bump needs <Counter> in its row because c.incr() calls a Counter op.
fun bump(c: ref<Counter>, n: int) : <Counter> () {
  if n > 0 { c.incr(); bump(c, n - 1) }
}
```

The row entry `<Counter>` covers **any** Counter instance in scope. Two
references (`c1`, `c2`) do not produce `<Counter, Counter>`; they share the
one entry.

This matches how Koka's `named effect` type inference works: the effect
label is per-declaration, and the *evidence* (which instance) is threaded
implicitly per-call.

### 4.6 Interoperability with v1 `handle`

The same effect can be used both ways in the same program:

```hica
effect Log { fun info(s: string) }

fun main() {
  // v1 style — single implicit-target handler.
  handle Log {
    info(s) => println("[LOG] " ++ s)
  } in {
    info("boot")             // uses the implicit handler
  }

  // Named style — explicit instance.
  spawn Log {
    info(s) => println("[TRACE] " ++ s)
  } as trace_log
  trace_log.info("worker started")
}
```

The compiler tracks per-effect: "has this effect been used named anywhere
in this compilation unit?" and picks the Koka emit shape accordingly.
§7.6 covers the details. The important user-visible rule: **you can mix
freely; the compiler figures it out.**

---

## 5. Semantics

### 5.1 Instance identity

Each `spawn` expression evaluates to a fresh instance. Two spawns of the
same effect produce two references with distinct identities. Comparing
references with `==` is *not* supported in v1 of this feature — Koka's
named-effect handles are opaque tokens and hica doesn't expose their
identity. §10 defers reference equality until a concrete use case appears.

### 5.2 Dispatch resolution

For `ref.op(args)`:

1. Look up `ref`'s type. Must be `ref<E>` for some effect `E`.
2. Look up `op` in `E`'s op table. If absent, error (see §4.3).
3. Unify the arg types with `op`'s declared signature (freshened per
   call, same as v1 op resolution).
4. Add `<E>` to the enclosing function's inferred effect row.

The Koka codegen emits `ref.op(args)` directly — Koka's named-effect
mechanism does the runtime routing.

For a bare `op(args)` call (no `ref.` prefix), the v1 resolution rule
applies unchanged: look for a matching enclosing `handle E { … }` block.
This means named and un-named calls happily coexist in the same function.

### 5.3 Scoping and lifetime

A `spawn Name { … } as r` binds `r` for the rest of the enclosing block.
The handler is torn down when the block exits. Using `r` after the block
exits is a compile-time error (§5.5).

```hica
fun outer() {
  {
    spawn Counter { … } as c
    c.incr()
    c.incr()
  }                          // c's handler torn down here
  c.incr()                   // error: 'c' is not in scope
}
```

Nested spawns are fine and independent:

```hica
spawn Counter { … } as a
{
  spawn Counter { … } as b
  a.incr()                   // a is in scope
  b.incr()                   // b is in scope
}                            // b torn down
a.incr()                     // a still live
```

### 5.4 Exhaustiveness — same as v1

A `spawn` block must handle every op declared on the effect. Missing or
extra arms produce the same errors as `handle` (see effects-design §4.3,
§5.2). Duplicate arms are also caught. Nothing new here.

### 5.5 The escape rule

References may not outlive the handler that produced them. In practice
this means:

- Returning a `ref<E>` from a function whose block spawned it is a
  **compile-time error**.
- Storing a `ref<E>` in a data structure that outlives the spawn block
  is a compile-time error.
- Passing a `ref<E>` to a function that runs *inside* the spawn block is
  fine (the reference is a local value).
- Closing over a `ref<E>` in a lambda is fine as long as the lambda runs
  inside the spawn block.

```hica
// ✗ Escape — reference outlives handler.
fun make_counter() : ref<Counter> {
  spawn Counter { … } as c
  c                          // error: 'c' escapes its handler's scope
}

// ✓ Passing down — fine.
fun caller() {
  spawn Counter { … } as c
  bump(c, 10)                // bump runs inside c's scope
}

fun bump(c: ref<Counter>, n: int) : <Counter> () {
  if n > 0 { c.incr(); bump(c, n - 1) }
}
```

The checker enforces the escape rule via a **scope-depth annotation** on
each `ref<E>`-typed value (§8.4). This is a fresh mechanism — v1 has no
equivalent — and is one of the two significant new checker features (the
other being ref-typed method resolution, §8.3).

### 5.6 Effect rows and named calls

A function that calls `ref.op(…)` gets `<E>` added to its inferred effect
row exactly as if it had called a bare `op(…)` with a v1 handler in scope.
The row entry does not distinguish "used named" from "used un-named" —
one entry per effect name, regardless of how many references there are or
which style is used.

`hica check` output looks the same for both styles: `[<Counter, console>]`.

### 5.7 Resumption — still implicit

Same as v1: every arm resumes exactly once, automatically, with the value
of the arm's body. Non-resuming handlers, multi-shot resumption, and
explicit `resume` remain non-goals (see effects-design §5.3, §10).

---

## 6. Worked Example — Two-Actor Ping-Pong Without Workarounds

The M6 workaround retires. Compare:

**M6 (v1 named-op workaround):**

```hica
actor Pinger { var pongs = 0; receive(msg: PingerMsg) => … }
actor Ponger { var pings = 0; receive(msg: PongerMsg) => … }

fun rally(rounds: int) {
  if rounds <= 0 { … }
  else {
    send_ponger(Ping)        // compiler-generated op name
    send_pinger(Pong)
    rally(rounds - 1)
  }
}

fun main() {
  with_pinger(() => {
    with_ponger(() => {
      rally(3)               // implicit dispatch via nested scopes
    })
  })
}
```

**With named effects:**

```hica
actor Pinger {
  var pongs = 0
  receive(msg: PingerMsg) => match msg {
    Pong => { pongs = pongs + 1; println("pinger got Pong #{show(pongs)}") }
  }
}

actor Ponger {
  var pings = 0
  receive(msg: PongerMsg) => match msg {
    Ping => { pings = pings + 1; println("ponger got Ping #{show(pings)}") }
  }
}

fun rally(pinger: ref<Pinger>, ponger: ref<Ponger>, rounds: int) {
  if rounds > 0 {
    ponger.send(Ping)        // per-instance dispatch, unambiguous
    pinger.send(Pong)
    rally(pinger, ponger, rounds - 1)
  }
}

fun main() {
  spawn Pinger as pinger     // actor sugar spawns with default state
  spawn Ponger as ponger
  rally(pinger, ponger, 3)
}
```

Three things to notice:

1. The op name is just `send` in both actors — no `_pinger` / `_ponger`
   suffix. Named-effect dispatch resolves the ambiguity by reference,
   not by name.
2. `rally` takes two references as parameters. This is impossible in v1
   because there's no such type as `ref<Name>` — you'd have to inline
   the whole call chain into `main` and rely on lexical shadowing.
3. `main` reads top-to-bottom. No nested `with_pinger(() =>
   with_ponger(…))` callback tower.

---

## 7. Codegen — Mapping to Koka

Koka's `named effect` feature does exactly what we need. The mapping is
almost 1:1 with the actor lab-journal Step 4 and Step 5 experiments.

### 7.1 Effect declaration with named uses

When an effect is used with `spawn` anywhere in the compilation unit, the
Koka emission changes from `effect …` to `named effect …`:

hica:
```hica
effect Counter {
  fun incr()
  fun get() : int
}
```

Koka (if `spawn Counter` appears anywhere):
```koka
named effect counter
  fun hc_incr() : ()
  fun hc_get()  : int
```

Koka (if only `handle Counter` is used — v1 shape, unchanged):
```koka
effect counter
  ctl hc_incr() : ()
  ctl hc_get()  : int
```

The `ctl` → `fun` swap on the named path is because Koka's named effects
require *tail-resumptive* operations (the `fun` shape). Since hica v1
already restricts to auto-resume (see effects-design §5.3), every hica
op is tail-resumptive by construction — the swap is a no-op semantically.

Emitting both shapes for the same effect is impossible in Koka (they're
different type declarations). The compiler must pick one per effect
per compilation unit. §7.6 covers the decision rule.

### 7.2 `spawn` expression

hica:
```hica
spawn Counter {
  incr() => count = count + 1,
  get()  => count
} with var count = 0 as c
```

Koka:
```koka
var count := 0
with c <- named handler
  fun hc_incr() { count := count + 1 }
  fun hc_get()  { count }
```

Rules:
- The `var …` hoist rule from v1 M5 codegen still applies: state
  declarations move outside the `with c <- named handler` block.
- Each arm becomes a `fun` (not `ctl`) declaration. Because named-effect
  handlers must be tail-resumptive, `resume(…)` is implicit and does not
  appear in the emitted arm — the arm's body *is* the resume value.
- `with c <- named handler … <body>` is Koka's standard flatten-callback
  form. The `<body>` is everything in the enclosing hica block after the
  `spawn` statement.

Compare to the v1 `handle` codegen (effects-design §7.3):

```koka
// v1 handle
with handler
  ctl hc_incr() -> { count := count + 1; resume(()) }
  ctl hc_get()  -> resume(count)
<body>
```

Named-effect codegen is *simpler* because the resume wrapping goes away.
The v1 codegen's `resume(...)` wrapping only exists because `ctl`
operations must call `resume` explicitly; `fun` operations resume
tail-position automatically.

### 7.3 `ref.op(args)` — per-instance dispatch

hica:
```hica
c.incr()
c.get()
```

Koka:
```koka
c.hc_incr()
c.hc_get()
```

Koka's `.op()` syntax on a named-handle value is the dispatch form; no
new codegen invention is needed. The `hc_` op-name mangling from v1
carries over unchanged.

### 7.4 `ref<E>` in function signatures

hica:
```hica
fun bump(c: ref<Counter>, n: int) : <Counter> ()
```

Koka:
```koka
fun bump(c : ev<counter>, n : int) : <counter> ()
```

Koka spells the reference type as `ev<E>` ("evidence for effect `E`").
The lowercase form matches the effect-name lowercasing rule from v1
(effects-design §7.1). The `<counter>` on the return effect row is the
same emit rule as v1 (M4 §7.5).

Passing references through function calls, storing them in lists,
returning them (when the escape rule permits) all use the `ev<E>` type
unchanged.

### 7.5 The escape rule at codegen time

The escape rule (§5.5) is enforced at the hica checker; at codegen time
we simply emit the reference-passing code and trust Koka. Koka's own
type system will *also* reject escaping evidence, but its error messages
mention `ev<counter>` and "evidence out of scope" — worse UX than hica's
compile-time check.

### 7.6 Choosing between plain and named codegen

The rule: **if any `spawn Name` appears anywhere in the compilation
unit, `Name` is emitted as `named effect`.** If only `handle Name`
appears, it stays as v1's `effect` with `ctl` ops.

Consequences:

- Introducing a `spawn` in one module *promotes* the effect to named
  everywhere it's used in that compilation unit — including v1
  `handle` sites. The `handle` codegen must adapt.
- Adapting `handle` to a named effect: emit `with h <- named handler …
  <body>` and generate a *lexically-unique* `h` name (e.g. `hc__handle_1`).
  The arms and body are unchanged; the arms just get an implicit `h`
  binding they never reference. This preserves v1 semantics (the arm
  handles every op call in `<body>`, because there's only one instance
  and every op site resolves to it via Koka's evidence inference).

This "promotion" rule is the one significant runtime change of this
feature. It is invisible at the hica surface — user code doesn't
change, error messages don't change, `hica check` output doesn't
change. But it does mean adding `spawn` to a widely-used effect
causes a Koka-level recompile of every module that uses that effect.
§8.5 covers how the checker detects and reports this.

Alternative considered: keep `effect` as `effect` in Koka, generate
a hidden `named-effect-<E>` sibling, and desugar `spawn` to that
sibling. Rejected because it doubles the emitted-effect count and
makes error messages harder to read (Koka would mention two effect
names for what the user sees as one).

---

## 8. Type-Checker Sketch

### 8.1 The reference type

`hica-type` gains a new variant:

```koka
type hica-type
  | …existing…
  | TRef(effect-name : string)   // ref<E>
```

`TRef("Counter")` is the type of a `ref<Counter>`. It's a leaf type — no
recursion, no type parameters (an effect name is a plain string). Fresh
`TVar`s do not unify with `TRef` (a reference is not a polymorphic value).

### 8.2 Spawn expression checking

For each `spawn E { arms } (with var …)? as ident`:

1. Look up effect `E` in the registry (reuses M2's effect-registry).
   Error if unknown.
2. Run the same exhaustiveness / arm-arity / arm-type checks as v1's
   `handle` (§5.2 of effects-design, §8.3 of the M2 checker sketch).
3. Extend the current env with `ident : TRef(E)` for the rest of the
   enclosing block.
4. Mark `E` as *named-used* in the compilation unit's effect-usage
   registry (§8.5).

### 8.3 Method-call resolution

For each `expr.op(args)`:

1. Type-check `expr`. Call the result `t`.
2. If `t` is `TRef(E)`:
   - Look up `op` in `E`'s op table.
   - If absent: error (see §4.3 for the message shape).
   - Freshen `op`'s signature, unify arg types, add `<E>` to the
     enclosing function's inferred effect row (§8.4 of the M4 sketch).
3. If `t` is a struct type: current struct-field-access rules apply.
4. Otherwise: current pipeline-call / dot-syntax rules apply.

This means the existing dot-syntax paths keep working; ref-typed
receivers are a new dispatch shape layered on top.

### 8.4 The escape rule (`TRef` scope-depth tracking)

Each binding in the env gains a **scope depth** — an integer counter that
increments on entering a `{ … }` block and decrements on leaving it.
When the checker returns from a scope, every `TRef` binding whose depth
equals the current depth is dropped from the env.

Escape detection:

- When a `TRef(E)` value flows into a *return position* (the last
  expression of a function, an early `return`, or a value being passed
  to a builder-consumer), the checker checks: is the reference's
  binding depth `≤` the function's outermost depth? If yes: escape.
  If no (reference was declared inside the function): error.
- When a `TRef(E)` value is stored in a struct field or list element
  that is itself being returned, same check.

Error message:

```
error: reference of type 'ref<Counter>' escapes its handler's scope
  at pool.hc:34:3
       c                     // <-- reference binding site
       ^

  note: 'c' was spawned at pool.hc:32:5 and its handler ends when the
        enclosing block exits at pool.hc:35:1
```

The scope-depth mechanism is otherwise inert — it costs nothing for
non-`TRef` bindings and does not change unification.

### 8.5 Effect-usage registry (promotion detection)

`check-program` maintains a per-effect flag: `named-used : bool`. Any
`spawn E` sets `named-used(E) := true`. After all decls are checked,
the codegen phase reads the flag to pick between `effect` and `named
effect` emission (§7.6).

For cross-module scenarios: the flag is unioned across imported
modules. If module A defines `effect Counter` (only used with `handle`
in module A) and module B does `spawn Counter`, the compiled program
emits `named effect counter`.

Because named/plain emission is a compilation-unit-wide decision, an
import that flips the flag re-compiles every downstream module. This
is documented as a known caveat (§10) rather than fixed — the alternative
(per-effect Koka module boundaries) is a much larger change.

---

## 9. Milestone Plan

Five milestones, each shippable independently. Each has its own
regression tests (`tests/test-named-effects.kk`) and one runnable
example (`examples/effects/named-*.hc`).

| # | Milestone | Files touched | Exit criteria |
|---|-----------|---------------|---------------|
| **N1** | **Parser + AST for `spawn`, `ref<E>`, `ref.op()`** | `syntax/lexer.kk` (`TkSpawn`, `TkAs`, `TkRef`); `syntax/ast.kk` (`ESpawn`, `TRef`, `EMethodCall` or reuse `EDot`); `syntax/parser.kk` (`parse-spawn`, `parse-ref-type`, extend `parse-dot`). Codegen for `named effect` and `with h <- named handler`. Lenient checker (register `TRef` but no escape check). | Two-counters example (`examples/effects/two-counters.hc`) parses, emits valid Koka, and runs. |
| **N2** | **Checker: method-call resolution + effect promotion** | `semantics/checker.kk` (`TRef` dispatch in `infer`'s `EDot`/`ECall` case, freshening, row addition); effect-usage registry. Codegen: swap `effect` ↔ `named effect` based on the registry. | Named-op call with wrong arg type errors clearly. Effect used both ways in one program compiles. Six regression tests. |
| **N3** | **Escape rule + `ref<E>` in function signatures** | `semantics/checker.kk` (scope-depth on env bindings, `TRef` return-position check). `syntax/parser.kk` (`parse-type` accepts `ref<E>`). | Escaping `ref` errors with a clear message. `bump(c: ref<Counter>, n: int)` compiles. Actor-pool example runs. |
| **N4** | **`hica check` output + analyser awareness** | `main.kk` `discover-effects` treats named uses the same as un-named for row reporting. `semantics/analyser.kk` walks `ESpawn` and method calls without false positives. | Two-counters example reports `[<Counter, console>]`. Analyser 100/100 on all new examples. |
| **N5** | **`actor` sugar retires `send_<name>`** | `syntax/parser.kk` `parse-actor-decl` emits `send(msg)` (not `send_<name>`). Actor examples rewrite to use `spawn` + `ref<Actor>`. `learn/48-named-effects.hc` teaches the pattern. `docs/effects.md` + `docs/language-reference.md` extended. | `examples/effects/ping-pong-actor.hc` uses `spawn Pinger as pinger` and `pinger.send(Pong)`. M6 workaround retires. |

**N1 → N3** are the core language work. **N4** is the reporting /
tooling pass (mirrors v1's M3). **N5** is the actor-sugar retro-fit
and the docs sweep (mirrors v1's M6).

Each milestone follows the v1 workflow: journal entry, plan + log +
reflection, one runnable example, regression tests, `hica fmt` / `hica
analyse` sweep, breadcrumbs → milestone commit gated on user approval.

Estimated calendar: 2–3 sessions per milestone, matching v1's cadence.

---

## 10. Non-Goals for v2

The following are deliberately deferred:

- **Reference equality.** `c1 == c2` returns nothing meaningful in v1 of
  this feature; Koka doesn't expose named-handle identity as a value.
  Adds a dedicated op-code if a real use case appears.
- **Actor supervision / restart.** An outer handler that catches errors
  from a spawned actor and restarts it. Prototypeable on top of named
  effects (a `Supervisor` effect that owns a `ref<Actor>` and re-spawns
  on failure), but the language doesn't need first-class support.
- **Cross-module `spawn` unification.** Two modules spawning the same
  effect produce two evidence tokens that Koka treats as distinct.
  Sharing an instance across module boundaries requires passing the
  `ref<E>` explicitly; there is no global registry. Fine for now.
- **Non-resuming named ops.** Same rationale as v1 (effects-design
  §10). Named handlers keep the auto-resume rule.
- **Multi-shot named ops.** Same rationale as v1. Koka's named effects
  actually make multi-shot easier to model, but no demand exists.
- **`ref<E>`-parametric functions.** A function generic over `E` that
  takes any `ref<E>`. Adds effect-variable polymorphism, which v1
  effects also punted on. Revisit if actor libraries hit the wall.
- **Send-and-forget syntax (`c ! msg`).** The `.op()` form already
  covers everything; adding operator syntax is bikeshed until the
  need is visible.

---

## 11. Interaction With Existing Features

### 11.1 The `?` operator and `hica-early-*` effects

Unchanged. A function that calls `c.op()` and also uses `?` gets both
`<Counter>` and `<hica-early-…>` in its Koka effect row. Koka handles
the union.

### 11.2 Effect rows (M4)

An effect row `<Counter>` covers named and un-named use uniformly (§5.6).
Callback contracts (`f: () -> <Counter> ()`) accept functions that use
either style internally, as long as `Counter` is the only effect.

The M4 row-mismatch enforcement (`collect-effect-leaks`,
`walk-call-sites`) treats named-op calls the same as un-named — the
leak walker just looks up the callee's op in the effect registry, and
the registry is style-agnostic.

### 11.3 Stateful handlers (M5)

The `with var …` clause works identically on `spawn` and `handle`. The
codegen splits are the same: state hoisted outside the handler block,
multi-statement arm bodies use the `emit-handle-arm` split (M5.5's
match-in-resume hoist doesn't apply on the named path because `fun`
ops don't wrap in `resume(...)`).

### 11.4 `actor` sugar (M6) — retro-fit in N5

The M6 desugar currently emits `effect Name { fun send_<name>(msg) }`
and `pub fun with_<name>(action)`. N5 changes this to:

- Emit `effect Name { fun send(msg) }` (bare op name — no
  `_<name>` suffix).
- The user-facing spawn becomes `spawn Name as ref`; the compiler no
  longer generates a `with_<name>` helper.

Backwards compatibility: the current `actor` syntax stays valid.
Existing files using `with_pinger(() => …)` and `send_pinger(Pong)`
continue to compile because N5 keeps generating both shapes for one
release cycle, then retires the un-suffixed shape in the next.

### 11.5 REPL

Same story as v1 M6 (deferred). `spawn` at the REPL would need the
evaluator to keep the handler alive across inputs — non-trivial.
Cost/value unclear; punt until concrete demand appears.

### 11.6 Formatter

`spawn Name { … } with var … as ref` on one line for short blocks;
otherwise arms on separate lines, `with var …` on its own line before
`as ref` on the last line. Matches existing `handle` formatter rules.

---

## 12. Open Questions

Intentionally deferred to implementation-time discussion:

1. **`spawn` inside a lambda.** Does a `spawn` inside a lambda work as
   expected? The handler's lifetime is tied to the lambda's block; the
   reference cannot escape the lambda. Assumed yes; verify at N3.

2. **Recursive references.** Can a `spawn Pinger as pinger` reference
   itself inside its own arm bodies? Koka's `with h <- named handler`
   binds `h` inside the handler block, so arm bodies can call `h.op()`.
   Useful for actors that re-schedule work. Design: allow it, document
   the "handler references itself via `ref`" pattern.

3. **`spawn` return value.** `spawn Name … as r` is a statement in this
   design. Should it also be an expression (`let r = spawn Name … { … }`
   without the `as` clause)? Reading is more natural without `as`, but
   adding a new expression shape complicates parsing. Punt to N1.

4. **Explicit destroy.** Should there be a way to tear down a handler
   before its scope ends? Not needed for correctness (scope handles
   it), but useful for long-running processes. Deferred until concrete
   use case (e.g. actor supervision).

5. **Named-effect `pub` visibility.** Does exporting an effect that's
   also `spawn`-able export the whole ref-type surface? Assumed yes
   (matches v1 `pub effect` rule); revisit if demand for private
   references appears.

---

## 13. Appendix — Worked Examples

### 13.1 `examples/effects/two-counters.hc` (N1 exit criterion)

```hica
effect Counter {
  fun incr()
  fun get() : int
}

fun main() {
  spawn Counter {
    incr() => count = count + 1,
    get()  => count
  } with var count = 0 as c1

  spawn Counter {
    incr() => count = count + 1,
    get()  => count
  } with var count = 100 as c2

  c1.incr()
  c1.incr()
  c1.incr()

  c2.incr()

  println("c1 = {show(c1.get())}")   // c1 = 3
  println("c2 = {show(c2.get())}")   // c2 = 101
}
```

### 13.2 `examples/effects/counter-pool.hc` (N3 exit criterion)

```hica
effect Counter {
  fun incr()
  fun get() : int
}

fun bump(c: ref<Counter>, n: int) : <Counter> () {
  if n > 0 { c.incr(); bump(c, n - 1) }
}

fun main() {
  spawn Counter {
    incr() => count = count + 1, get() => count
  } with var count = 0 as w1
  spawn Counter {
    incr() => count = count + 1, get() => count
  } with var count = 0 as w2
  spawn Counter {
    incr() => count = count + 1, get() => count
  } with var count = 0 as w3

  let workers = [w1, w2, w3]
  workers.foreach((w) => bump(w, 5))

  workers.foreach((w) => println("worker = {show(w.get())}"))
  // worker = 5
  // worker = 5
  // worker = 5
}
```

### 13.3 `examples/effects/ping-pong-named.hc` (N5 exit criterion)

The M6 ping-pong rewritten with `spawn` + `ref<Actor>` — see §6 for the
full listing.

### 13.4 Multi-connection Db (N3 payoff)

```hica
effect Db {
  fun query(sql: string) : Rows
  fun exec(sql: string)
}

pub fun with_sqlite(path: string) : ref<Db> {
  // (This form requires the "spawn as expression" resolution from Q3.
  //  Alternative: pass an action, per v1 with_sqlite.)
  spawn Db {
    query(sql) => sqlite_query(path, sql),
    exec(sql)  => sqlite_exec(path, sql)
  } as conn
  conn                       // escape rule: fine because conn's scope
                             // is the caller's block, not this function's
}

fun main() {
  let prod  = with_sqlite("prod.db")
  let cache = with_sqlite("cache.db")

  prod.exec("UPDATE users SET last_seen = now()")
  let rows = cache.query("SELECT * FROM sessions")
  println("cache hit rows = {rows.count}")
}
```

*(This example uses the "spawn as expression" resolution — Q3 open
question. If we stick with statement-only `spawn`, `with_sqlite`
becomes `with_sqlite(path, action)` and the caller writes `with_sqlite("prod.db",
(prod) => { … })`.)*

---

## 14. Summary

hica gets two surface constructs and one type:

- `spawn Name { arms } (with var …)? as ref` — install a fresh
  handler instance.
- `ref.op(args)` — dispatch on a specific instance.
- `ref<Name>` — the first-class type of an instance reference.

Five milestones. Milestone N1 alone (parser + codegen + two-counters)
validates the approach end-to-end. N5 retires the M6 `send_<name>`
workaround.

Every hica v1 effect program continues to work unchanged. The `handle`
form remains the right choice for single-handler-per-scope patterns
(capability sandboxes, one-shot state); `spawn` is the escape hatch when
you need multiple independent instances.

The mechanism is Koka's `named effect` verbatim — no runtime invention,
no scheduler, no mailbox layer. The actor lab-journal's Step 4 and
Step 5 experiments already validated the codegen shape end-to-end;
this proposal wraps hica surface syntax around it.

Ready to plan N1.
