Hica’s implementation of named effects elegantly resolves the traditional handler disambiguation problem by turning effect handlers into lexically-scoped capabilities backed by Koka evidence vectors (`ev<E>`).

**Key Technical Strengths**

* **Lexical Scope Protection:** The compile-time escape rule prevents dangling `ref<T>` handles from outliving their handler blocks, ensuring memory and effect safety without needing a full runtime actor model.


* **Explicit Capability Passing:** Typing parameters as `ref<Counter>` gives functions precise capability access while allowing multiple independent instances of the same effect to coexist in a single scope.


* **Clean Lowering:** Mapping `spawn` directly to Koka’s native named effects ensures lightweight runtime execution while keeping the surface syntax cleaner than raw handler-evidence manipulation.



**Design Trade-offs & Considerations**

* **Suffix Variable Binding:** Syntactically placing `as ref` at the very end of a multi-line `spawn` block can obscure the handle name until the reader scans past the entire handler body.


* **Lambda Inference Gap:** The temporary requirement for explicit helper functions in untyped lambdas (e.g., inside `foreach`) creates a minor friction point in higher-order collection pipelines.


* **Synchronous Execution:** While `spawn` borrows terminology from concurrent process systems, control flow remains strictly synchronous stack manipulation via standard delimited continuations/effects.



Are you planning to extend named effects to support asynchronous background execution, or will `spawn` remain strictly bound to stack-based synchronous handlers?

---

## 1. Suffix `as binder` placement — not currently planned

The reviewer is right that in a long handler body, the bound name is buried at the end:
```hica
spawn Counter {
  incr() => count = count + 1,
  get()  => count
} with var count = 0 as c1   // ← reader only sees "c1" after scanning all arms
```

This isn't in N4 or N5. Two options worth tracking as a post-N5 backlog item:
- **Alternative prefix syntax:** `let c1 = spawn Counter { ... }` — purely a parser change, no AST or codegen impact since `ESpawn` already carries the binder string
- **Status quo + docs:** the v1 `handle … in { … }` has no binder name at all, so `spawn … as c1` is already an improvement; document the scanning pattern in the style guide

The prefix `let` form is the most natural since it mirrors how every other value is bound in hica. Worth opening a backlog item.

## 2. Lambda inference gap — partially planned for N4

The N3 carry-forward already flags this: when `ref-dispatch-info` gets a `TVar` receiver in `(w) => w.incr()`, it silently falls through to "undefined variable". The reviewer calls this "minor friction" — but the *error message* is what makes it bad. N4's plan says "emit a targeted error or broaden inference."

The broadening (real top-down inference into lambdas) is hard. The **targeted error** is N4 scope:

```
error: 'incr' is not defined
  note: if 'w' is a ref<Counter>, declare a typed helper:
        fun bump(c: ref<Counter>) { c.incr() }
        then pass it to foreach
```

This should be added to the N4 exit criteria explicitly.

## 3. `spawn` keyword terminology — a real design tension

The reviewer's question "are you planning async?" is the crux. Right now `spawn` means *lexically-scoped synchronous handler instantiation*, backed by Koka's evidence vector allocation. It is decidedly not concurrent.

The tension is real: `spawn` in Erlang, Go (`go`), Rust async, and Koka's own `std/async` all imply concurrency. Koka itself has `spawn` in `std/async` — if hica ever surfaces Koka's async layer, there will be a name collision at the conceptual level even if not at the code level.

**Answer to the reviewer's question:** No async is planned. The underlying Koka model *could* support cooperative async via Koka's `async` effect, but that would be a separate keyword/mechanism — not `spawn`. The current `spawn` is strictly synchronous stack manipulation and will stay that way.

**What to do about it:**
- Add a one-sentence note to the intro of the "Named effects" docs section — not just buried in the "Known limitations" footnote — stating that `spawn` is synchronous handler instantiation, not concurrent process creation
- Consider a post-N5 rename audit: `instance`/`handler`/`new` are less loaded alternatives. The cost is a breaking change after N1–N3 have shipped examples; it's worth flagging before more users adopt it but not worth acting on mid-milestone

---

## Summary of actionable items

| Item | Where it lands | Priority |
|------|---------------|----------|
| Add targeted error/hint for TVar lambda in `foreach` | N4 exit criteria | High — reviewer specifically called it out |
| Backlog item: `let c1 = spawn ...` prefix syntax | Post-N5 | Low — ergonomic improvement, not a blocker |
| Docs: clarify `spawn` is synchronous in intro (not footnote) | N4 docs pass | Low — one sentence |
| Design note: keyword rename risk post-N5 | journal/design doc | Medium — capture before more code is written |

The lambda hint is the most concrete deliverable — it fits cleanly into N4 since N4 is already touching `analyser.kk` and `main.kk`'s call-site walkers.
