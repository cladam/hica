# Retrospective: User-Facing Algebraic Effects in hica

**Feature:** `effect` / `handle` / effect-row polymorphism / `actor` sugar
**Design doc:** [`effects-design.md`](effects-design.md)
**Implementation journal:** [`effects-journal.md`](effects-journal.md)
**Milestones shipped:** M1 → M6, plus carry-over sweeps M4.5, M5.5, M6.5
**Sessions:** 14 focused Cline sessions across ~5 calendar days

---

## What Worked Well

- **Design-first, then milestones.** Writing `effects-design.md` before touching
  a line of compiler code paid dividends every session. Every "should I do X
  or Y?" question had an answer in §4–§8 already, and the six-milestone
  slicing survived contact with reality — we never had to re-slice.
- **The journal-as-you-go workflow.** Each session began by reading the last
  session's Log entry and Reflection, and ended by writing its own. Handoffs
  between sessions were mechanical because every carry-forward was named,
  scoped, and pointed at exact files/functions.
- **Layering was the correct call.** M1 (AST + parser passthrough) →
  M2 (checker exhaustiveness) → M3 (`hica check` reporting) →
  M4 (effect rows) → M5/M5.5 (stateful handlers) → M6 (`actor` sugar). Each
  layer reused the previous one verbatim. M6's `actor` keyword ended up as a
  pure parser change — zero new codegen, zero new checker rules — because
  every capability it needed was already in place.
- **Lenient checker Mode B in M1.** Not enforcing exhaustiveness in M1 let
  us prove the parser + codegen paths worked end-to-end before committing
  to type-checker semantics. When M2 tightened the rules, the codegen was
  already stable.
- **The `tests/test-effects.kk` regression suite.** Every milestone added
  2–4 focused tests. By M6.5 the suite was 25 tests strong and caught every
  regression in seconds. The `emit-typed-program(src)` helper (added in M2)
  made codegen assertions trivial — grep the emitted Koka for a specific
  shape, done.
- **Runnable examples per milestone.** `hello-effect.hc` (M1), `greet-typed-op.hc`
  (M2), `db-sandbox.hc` + `db-sandbox-leak.hc` (M4), `counter.hc` +
  `buffer.hc` (M5/M5.5), `counter-actor.hc` + `ping-pong-actor.hc` (M6).
  Every one of them still runs unchanged at M6.5.
- **The design doc's §7 codegen mapping.** Line-for-line accurate. When we
  hit ambiguity mid-session we could re-read §7.1 or §7.4 and get the
  answer without inventing anything.

## Friction Points

| Issue | Root cause | Resolution |
|-------|-----------|------------|
| Koka silently defaults missing constructor args | `TFun(params, r)` destructures the 3-arg constructor with `effects = []` — the row is dropped, no warning | Explicit `TFun(params, r, es)` in every destructure site; caught in M4 session 9 |
| Field-access ambiguity when locals shadow struct fields | Koka's dot-syntax resolution picks the accessor over the local, producing "only functions can be applied" at the projection site | Rule adopted: **never name a local `foo` when you plan to project `.foo`** — hit 4× across M1, M4, M4.5, M6.5 |
| `println` inside effect-inferred code cascades | Adding `console` to one function propagates through every caller via Koka's effect inference | Use `trace(...)` from `std/core/debug` (`div`-only) for tracing; never `println` |
| Stdlib name collisions inside `emit-expr` | Effect ops named `exec`, `write`, `print`, etc. were hijacked by ~50 hardcoded stdlib intercepts in codegen | M4.5: checker tags op-Var nodes with `"hc-op:"` prefix; codegen strips the tag and always emits `hc_<name>` |
| Adding a Koka effect to `check-program` breaks distant functions | Every helper called from `infer` needs the new effect appended; error points at outermost `pub fun infer`, not the callee | Rule: when adding a checker effect, sweep every helper signature in the same edit |
| Multi-statement arm body inside `resume(...)` | Second statement fell outside the resume parens | M5: `emit-handle-arm` splits leading statements before `resume(...)` |
| Match/if as arm body wrapped in `resume(...)` | Koka's layout parser can't close the block inside the resume argument | M5.5: hoist to `val hc__<op>_res = …` before `resume(res_name)` |
| `TkIn` binop precedence swallowed keyword `in` | `parse-expr()` in state initialiser consumed `handle … in { … }`'s `in` as list-membership operator | M5: parse state inits at `parse-binary(9)` — above `In`'s l-bp of 7 |
| Koka reserved keywords surface late | `final`, `exec`, `write` are Koka-only reservations; hica accepts them, Koka rejects the generated code | Blocklist in `marshal-name` — extended each time we found a new one (M4.5 for `exec`, M5 for `final`) |
| Single-letter effect / actor names lower to Koka type-variable syntax | `effect A` → Koka `effect a` → "expected type name (and not type variable)" | M6.5: checker rejects `edef.name.count <= 1` with a hica-level message |
| Analyser flagged handler-captured `var` as debt | The only sanctioned v1 pattern for observing post-handler state uses `var final = -1; with_counter(…)` | M6.5: `contains-lambda-assigning-to` heuristic suppresses the debt when a lambda in scope writes to the var |
| `hica fmt` and `hica analyse` are per-file CLIs | Sweep loops must invoke one file at a time | Documented; small CLI ergonomics follow-up |

## The `hc-op:` Prefix Tag

The most contentious design call. Every user-defined effect op gets its
call-site `Var(name)` node rewritten in the checker to `Var("hc-op:" ++ name)`.
Codegen's `marshal-name` strips the prefix and always emits `hc_<name>`.
The alternative (Approach C in the session-10 log) was to thread
`effect-op-names` through `emit-expr` and its 15 helpers — a full-file
refactor of `codegen.kk` touching ~184 call sites.

Approach A (the prefix tag) is 30 lines total across two files. The
trade-off: a magic string prefix lives in the AST between the checker and
codegen phases. It's contained by `unwrap-op-tag` / `unwrap-op-tag-main`
helpers so downstream walkers see bare names, but it *is* a leak of
implementation detail into the shared AST. If we ever grow more of these
tags we'll want a real annotation field on `Var`.

**Verdict:** the right call for M4.5, but a design smell that could bite in
future work. Named effects (post-M6) may be the trigger for cleaning it up.

## The `TFun.effects` Silent Default

The single most costly friction point. Koka lets you destructure a 3-arg
constructor with 2 patterns and silently defaults the missing field. Adding
`effects : list<string> = []` to `TFun` didn't break the build — it just
started dropping effect rows in ~7 places in the checker, producing
codegen that looked plausible but was missing the row entirely.

The symptom (row silently absent from emitted Koka) took a session to trace
because there was no compiler error. Once found, the fix was mechanical:
change `TFun(params, r) -> TFun(params, r)` to `TFun(params, r, es) ->
TFun(params, r, es)` at every site.

**Rule for future work:** any time we add a defaulted field to a
frequently-destructured AST variant, sweep every destructure in the same
edit — and add a targeted regression test that would catch the silent drop.

## What Changed vs the Design Doc

**Nothing structural.** Every §4 syntax rule landed as spec'd. Every §7
codegen mapping is implemented verbatim. §8's checker algorithm is
implemented step-for-step. §10's non-goals are still non-goals.

**Two undocumented implementation details:**

1. Effect op call sites emit as `hc_<op>` (not just op declarations) — the
   design doc §7.1 only mentions the declaration side. Documented inline
   in `emit-expr` and `marshal-name`.
2. The `hc-op:` AST prefix tag — internal to the checker↔codegen contract.

Both are compiler internals, not language features. If a future contributor
wonders why `Var("hc-op:exec")` appears in a dumped AST, the answer is in
`is-effect-op-name` (checker) and `marshal-name` (codegen).

## Numbers

- **6 milestones** (M1 → M6) + **3 carry-over sweeps** (M4.5, M5.5, M6.5)
- **~5 calendar days**, **14 focused Cline sessions**
- **25 regression tests** in `tests/test-effects.kk` (0 → 25)
- **6 regression tests** in `tests/test-analyser.kk` (4 → 6)
- **7 runnable examples** under `examples/effects/`
- **4 learn files** (`learn/44…` through `learn/47…`)
- **3 doc surfaces updated** (`docs/effects.md` new, `docs/language-reference.md`
  extended, `SKILL.md` Koka row rewritten)
- **100% backwards compatible** — every hica program written before M1
  still compiles and runs identically

## Lessons for Future Language Features

1. **Design doc first, milestones second, code third.** The `effects-design.md`
   document was 700+ lines before a single AST field changed. It saved
   dozens of "wait, how did we decide this?" moments.
2. **Ship a passthrough milestone first.** M1's "parse and emit, don't check"
   let us prove the codegen shape end-to-end before committing to
   type-checker semantics. When M2 tightened the rules, the codegen didn't
   move.
3. **Lenient checker mode is a superpower.** Mode B (register but don't
   enforce) unblocks incremental development in a way that "checker first,
   codegen second" doesn't.
4. **One example per milestone, always runnable.** These become the
   regression suite's smoke tests and the docs' worked examples for free.
5. **The Reflection section is not optional.** Every milestone that had a
   proper Reflection produced a cleaner next-milestone Plan. The one time
   we skipped it (mid-M4 session boundary) we lost time re-discovering the
   handoff context in session 9.
6. **`tbdflow` breadcrumbs beat commit messages.** The `.tbdflow-intent.json`
   file accumulated 30+ breadcrumbs across the feature. Each one was
   consumed into the next milestone commit body, meaning every commit
   carries the "why" for the decisions it embeds.
7. **Field-shadowing is a real hazard in Koka.** Rule: never name a local
   the same as a struct field you'll project in the same function. Got
   burned 4×. Adopt defensively.
8. **When you add a defaulted AST field, sweep every destructure.** Koka
   silently defaults missing constructor args, so a 3-arg constructor with
   2-arg destructures produces wrong-but-compilable code. Add a regression
   test that would catch the silent drop.

## Verdict

The feature shipped as designed, on the milestone plan, without a single
design-doc revision. Backwards compatibility is 100%. The compiler grew
by roughly 400 lines of checker + codegen (~8% of `src/`) to gain
first-class algebraic effect handlers, effect-row polymorphism, and
actor-style concurrency sugar.

The friction points were almost entirely at the hica↔Koka boundary
(silent constructor defaults, reserved-keyword collisions, type-variable
naming rules). The hica-native design decisions — Mode B leniency,
auto-resumption, `with var …` state, effect-row unification — all landed
without surprise.

The `actor` sugar is the payoff: two-actor ping-pong fits in 25 lines and
compiles to real Koka effect handlers. The `security-type-boundaries.md`
sandbox pattern is now expressible in the type system, not just prose. The
terminal-editor use case from §2 of the design doc is unlocked pending
someone writing it (deferred to post-M6 alongside the real `hedit` work).

**Would we do it again the same way?** Yes. The one thing to change:
add regression tests that guard against silent constructor-default drops
*before* introducing new defaulted fields, not after (we found the
`TFun.effects` drop only after `hica run` emitted code that ran but
lost the row).

Next up: named / instantiated effects (design-doc §10). But that needs
its own design doc first.
