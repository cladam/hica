# Effects Implementation Journal

Working log for implementing user-facing algebraic effects in hica.
Design spec: [`effects-design.md`](effects-design.md).

Each milestone gets its own section with:

- **Goal** — what "done" looks like for this milestone.
- **Plan** — a small, ordered checklist of concrete edits.
- **Log** — running notes made while implementing (surprises, dead-ends, fixes).
- **Reflection** — written *after* the milestone is green; what changed vs the plan, what to carry forward, what to change in the design doc.

We ship one milestone at a time. **We do not start Mn+1 until Mn is green, reflected on, and documented.**

---

## Ground Rules

1. **Small edits, frequent checks.** Every change ends with `hica check` on a smoke-test file, and the relevant `.kk` test suite green.
2. **Regression tests before green.** Every milestone must add at least one test to `tests/test-effects.kk` (new file) — failing first, then passing.
3. **One example per milestone.** Under `examples/effects/`, a runnable `.hc` file demonstrating the milestone's capability.
4. **Docs get updated in the same milestone.** `docs/language-reference.md` and `docs/standard-library.md` are amended alongside the code — not "later".
5. **Reflection is mandatory.** Before starting the next milestone we write a Reflection section here. If we skip it, we lose the pattern.
6. **`hica fmt` and `hica analyse` on every artefact.** Every `.hc` file we ship (examples, learn modules, tests) must pass:
   - `hica fmt --check <file>` → exit 0 (no formatting changes needed).
   - `hica analyse <file>` → clean report with no warnings or penalties.
   If either tool complains, we treat that as a milestone blocker. If `hica fmt` mis-formats the new `effect`/`handle` syntax, that is a formatter bug we fix in the same milestone (see `src/format/formatter.kk`). If `hica analyse` penalises legitimate `effect`/`handle` code, we update `src/semantics/analyser.kk` in the same milestone — the analyser must learn the new constructs at the same rate the parser does.
7. **Intent Log via tbdflow breadcrumbs.** As we work, we drop short intent notes with `tbdflow + "…"` — these are breadcrumbs describing *what we're doing and why*, saved locally in `.tbdflow-intent.json` and automatically appended to the next commit body. **A breadcrumb is not a commit message.** Commits happen only at milestone checkpoints, use conventional-commit format (`tbdflow commit -t <type> -s effects -m "…"`), and are gated on your approval. See the "Intent Log" section below for the full workflow.

---

## Cross-cutting deliverables

These artefacts grow across milestones. Track their state here so we know what still needs backfilling.

| Artefact | Purpose | Grows through |
|---|---|---|
| `tests/test-effects.kk` | Compiler regression tests for parsing, checking, codegen | M1 → M6 |
| `examples/effects/*.hc` | One runnable example per milestone | M1 → M6 |
| `learn/44-effects-intro.hc` | User-facing intro tutorial | M2 |
| `learn/45-effects-state.hc` | Stateful handlers | M5 |
| `learn/46-effects-sandbox.hc` | Effect-row polymorphism / capability security | M4 |
| `learn/47-effects-actors.hc` | `actor` sugar | M6 |
| `docs/language-reference.md` | `effect` + `handle` syntax reference | M1, M4, M5 |
| `docs/standard-library.md` | Any prelude effects that ship (probably none in v1) | as needed |
| `docs/effects.md` | New user-facing guide, longer than the language-reference entry | M2 |
| `SKILL.md` | Update the "gives up user-defined algebraic effect handlers" line | M2 |
| `documentation/backlog.md` | Mark P3 and P4 progress | after each milestone |
| `CHANGELOG-draft.md` | One line per milestone | after each milestone |
| `src/format/formatter.kk` | Teach the formatter about `effect` / `handle` layout | M1 (as needed) |
| `src/semantics/analyser.kk` | Teach the analyser about user effects; no false positives on `effect`/`handle` | M1 (baseline) + M3 (reporting) |

---

## Milestone 1 — Parser passthrough

### Goal

An `.hc` file that contains `effect Name { fun op(...) : T ... }` declarations and `handle Name { ... } in { ... }` expressions parses, produces AST nodes, and emits **valid runnable Koka**. The checker treats effect ops as free identifiers (lenient mode); exhaustiveness and effect-row inference come later.

**Exit criteria:**

- `hica run examples/effects/hello-effect.hc` prints the expected output.
- `hica build --generate examples/effects/hello-effect.hc` produces a `.kk` file we can eyeball to confirm the Koka mapping matches §7 of the design doc.
- `tests/test-effects.kk` has at least 4 parser/codegen tests — all green.
- `docs/language-reference.md` has a new "Effects (experimental)" section pointing at the design doc and marking the surface as unstable.

### Plan

- [ ] **Lexer.** Add `TkEffect`, `TkHandle`. `TkIn` and `TkWith` already exist. Add them to `token-kind/show` and to the keyword lookup table.
- [ ] **AST.**
  - Add `effect-op` struct: `{ name : string, params : list<(string, hica-type)>, ret : hica-type }`.
  - Add `effect-def` struct: `{ span, name, ops, is-pub, doc }`.
  - Add `program.effects : list<effect-def>` (default `[]`).
  - Add `expr` variant `EHandle(effect-name : string, arms : list<handle-arm>, state : list<(string, node)>, body : node)`.
  - Add `handle-arm` struct: `{ op-name : string, params : list<string>, body : node }`.
- [ ] **Parser.**
  - `parse-effect-def` at top level (after `parse-struct-def`).
  - `parse-handle-expr` recognised where a primary expression is expected.
  - `handle Name { arm, arm, arm } (with var x = e, var y = e)? in { body }`.
- [ ] **Codegen.**
  - Emit `effect <name>` with `ctl <op>(<params>) : <ret>` per op.
  - Emit `with handler` with `ctl <op>(<args>) -> resume(<body-expr>)` per arm.
  - Emit hoisted `var <name> := <init>` before `with handler` for stateful handlers.
- [ ] **Checker.** Lenient mode only: register effect names so unknown-effect errors are possible; register op names so they don't trigger "undefined variable"; do not check exhaustiveness yet.
- [ ] **Tests.** `tests/test-effects.kk` with cases:
  1. Parser accepts a minimal effect declaration.
  2. Parser accepts a minimal handle expression.
  3. Codegen produces the expected Koka fragment for a trivial effect.
  4. `hica run` on `examples/effects/hello-effect.hc` produces expected stdout.
- [ ] **Example.** `examples/effects/hello-effect.hc` — the smallest useful effect (a `Log` capability with one `info(s: string)` op).
- [ ] **Docs.** Draft `docs/language-reference.md` section "Effects (experimental, since vX.Y)". Add `documentation/effects-design.md` link.
- [ ] **`hica fmt` sweep.** Run `hica fmt --check` on every new/edited `.hc` artefact. If output diverges from what a reasonable style would produce, fix `src/format/formatter.kk` — do not rely on hand-formatting. Add a formatter regression test if we had to touch the formatter.
- [ ] **`hica analyse` sweep.** Run `hica analyse` on every new/edited `.hc` artefact. Expected result: zero warnings, zero penalties. If a legitimate `effect`/`handle` construct triggers a false positive (unused-name, unreachable-branch, effect-leak), fix `src/semantics/analyser.kk` in this milestone. Add an analyser regression test in `tests/test-analyser.kk`.
- [ ] **Journal.** Fill in Log and Reflection below.

### Log

_(fill in during implementation — dates, surprises, dead-ends, one-line notes)_

### Reflection

_(after M1 is green — fill in before starting M2)_

**What went as planned:**
**What surprised us:**
**What we changed in the design doc:**
**Carry-forward risks for M2:**

---

## Milestone 2 — Effect symbol table + exhaustiveness

### Goal

Handler exhaustiveness and unknown-op detection produce hica-level errors with source spans. Users start to feel the type-safety benefit of `handle`.

**Exit criteria:**

- Handler with a missing op produces `error: handler for effect 'X' is missing operation 'y'` with a caret.
- Handler with an unknown-op arm produces `error: 'z' is not an operation of effect 'X'`.
- Duplicate arms produce `error: operation 'y' is handled twice`.
- `learn/44-effects-intro.hc` runs end-to-end and teaches the core.
- `docs/effects.md` exists (user-facing guide).
- `SKILL.md` line about "gives up user-defined algebraic effect handlers" is updated.

### Plan

_(expand once M1 reflection is in — likely covers effect registry, op resolution, handler-arm checker, error messages, learn module)_

### Log

### Reflection

---

## Milestone 3 — Effect names in `hica check` output

### Goal

`hica check` reports user-defined effects alongside built-ins. The user sees `[<Terminal, console, fsys>]`.

**Exit criteria:**

- `hica check examples/effects/terminal-editor.hc` shows the `Terminal` effect in the output row.
- Analyser test coverage in `tests/test-analyser.kk` extended by two cases (one user effect, one mixed with built-ins).

### Plan

### Log

### Reflection

---

## Milestone 4 — Effect-row polymorphic function types

### Goal

Function type syntax gains `(A) -> <E1, E2> R`. The sandbox pattern from `security-type-boundaries.md` §7 becomes fully expressible.

**Exit criteria:**

- `with_sqlite(path, f: () -> <Db> ())` compiles.
- Passing a callback that calls a non-`<Db>` user effect errors at the call site with a clear message.
- `examples/effects/db-sandbox.hc` runs.
- `learn/46-effects-sandbox.hc` teaches the pattern.
- `docs/language-reference.md` updated with effect-row syntax.
- `documentation/security-type-boundaries.md` §9 has P3 and P4 marked ✓.

### Plan

### Log

### Reflection

---

## Milestone 5 — Stateful handlers (`with var …`)

### Goal

Handlers can carry local mutable state. Counter, Buffer, and simple actor examples work without `process_messages` scaffolding.

**Exit criteria:**

- `examples/effects/counter.hc` runs.
- `examples/effects/buffer.hc` runs.
- `learn/45-effects-state.hc` teaches the pattern.
- `docs/language-reference.md` extended with the `with var` clause.

### Plan

### Log

### Reflection

---

## Milestone 6 — `actor` keyword desugar

### Goal

The `actor` keyword becomes sugar over `effect + handle + with var`. The `src/actors/` lab prototypes get rewritten to use the sugar; ping-pong runs without hand-rolled dispatch.

**Exit criteria:**

- `examples/effects/ping-pong-actor.hc` runs.
- `src/actors/step5-ping-pong.kk` (or its hica successor) rewritten with the new sugar.
- `learn/47-effects-actors.hc` teaches the pattern.
- Actor lab journal has a Step 7 documenting the rewrite.

### Plan

### Log

### Reflection

---

## Intent Log — tbdflow breadcrumbs + milestone commits

Two distinct things live under this heading, and they must not be conflated. See `.github/skills/tbdflow/SKILL.md` §7 for the source-of-truth definition of breadcrumbs.

### Breadcrumbs vs commits — the difference

| | Breadcrumb (`tbdflow + "…"`) | Milestone commit (`tbdflow commit -t … -m "…"`) |
|---|------------------------------|-------------------------------------------------|
| **When** | Any time during a milestone, especially at pivots, dead-ends, non-obvious decisions | Only at the end of a milestone, after Reflection is written |
| **Purpose** | Capture *why* — a chain-of-thought breadcrumb that would otherwise be lost | Standardised, lint-clean conventional commit that lands on trunk |
| **Frequency** | Many per milestone (1–2 minimum for anything non-trivial) | One per milestone (occasionally one extra for mid-flight `docs(effects)` fixes) |
| **Storage** | `.tbdflow-intent.json` — local, gitignored, ephemeral | Git history — permanent |
| **Approval needed** | No — write freely as we work | **Yes — we ask you first, every time** |
| **Fate** | Automatically appended to the next commit body, then consumed | Becomes the durable story of the feature |

### The breadcrumb workflow

While working inside a milestone we drop `tbdflow + "…"` breadcrumbs to record intent. Examples of the kind of notes we should be leaving:

- `tbdflow + "M1 lexer: adding TkEffect and TkHandle; TkIn/TkWith already exist"`
- `tbdflow + "M1 ast: chose to keep handle-arm params as list<string>, not typed; annotations added in M2"`
- `tbdflow + "M1 parser: hit ambiguity between 'handle Ident {' and struct-literal, resolved by requiring newline before arm"`
- `tbdflow + "M1 codegen: hoisted var outside 'with handler' — trailing-block form only sees the handler scope"`
- `tbdflow + "M1 fmt: formatter was collapsing arms onto one line; added handle-block layout rule"`

Rule of thumb from the tbdflow skill: **at least 1–2 breadcrumbs per milestone**, more if the work was surprising. Non-trivial refactors and pivots must be logged — the audit trail is not optional.

At the milestone commit, all pending breadcrumbs auto-flow into the commit body, then `.tbdflow-intent.json` is cleared. The intent log is preserved *inside* the commit, not alongside it.

### Milestone commit conventions

When we reach a milestone checkpoint we draft the commit and **ask you before running it**. Draft form:

```
tbdflow commit -t feat -s effects -m "<subject ≤72 chars, lowercase, no period>"
```

- **Scope is always `effects`.** Filters the log cleanly.
- **Types we expect to use:** `feat` (parser/checker/codegen work), `docs` (design + journal edits), `test` (regression tests), `refactor` (analyser/formatter adjustments), `chore` (build, tooling). The lint list in `.tbdflow.yml` is the source of truth.
- **Subject:** ≤72 chars, lowercase, no trailing period. Imperative mood.
- **Body:** we usually don't need to write one — the accumulated breadcrumbs from `.tbdflow-intent.json` become the body automatically. If we do add one, wrap at 80 chars, leading blank line, explain *why* not *what*.

### Checkpoint rule (when we commit)

We **only commit at the end of a milestone** — never in the middle. A milestone commit happens when:

1. Code changes are green (`hica check`, `hica test`, `hica fmt --check`, `hica analyse` all clean).
2. The milestone's Plan checklist is fully ticked.
3. The Reflection section is filled in.
4. Breadcrumbs are in place for every non-trivial decision made during the milestone.
5. **You have been asked and approved the commit type + subject.** No autonomous commits.

In-milestone work stays uncommitted (or on a feature branch) until the checkpoint. This keeps the trunk to roughly one commit per milestone, with the breadcrumbs embedded in each commit's body doing the storytelling.

### Running log

Two tables — breadcrumbs pending (uncommitted) and milestone commits landed.

**Pending breadcrumbs** (this session):

| When | `tbdflow + "…"` |
|------|-----------------|
| _(none yet — nothing in `.tbdflow-intent.json`)_ | |

**Milestone commits landed:**

| Milestone | Commit sha | tbdflow invocation |
|-----------|------------|-------------------|
| _(none yet — first checkpoint will be after M1)_ | | |

Rows get appended when we land a milestone commit (or the occasional mid-flight `docs(effects)` commit for design-doc fixes we discover during implementation).

---

## Post-M6 — Retrospective

Once all six milestones are green:

- Write `documentation/retrospective-effects.md` following the pattern of `retrospective-hml.md` / `retrospective-toml.md` / `retrospective-yaml.md`.
- Mark `documentation/backlog.md` rows P3 and P4 as **done** with the notes we accumulated.
- Publish a blog-style post in `docs/` about the design decisions and the outcome.
- Consider the next phase: named effects, non-resuming control, and multi-shot resumption — but only if concrete demand exists.

---

## Working style checklist (revisit at every milestone start)

- [ ] Have we written a Plan section that fits on one screen?
- [ ] Do we have one failing test in `tests/test-effects.kk` before we start writing code?
- [ ] Is there one runnable example under `examples/effects/`?
- [ ] Are the docs edits queued in the plan, not deferred?
- [ ] Did we write the previous milestone's Reflection before starting this one?
- [ ] Have we run `hica fmt --check` and `hica analyse` on every new/edited `.hc` file, with zero findings?
- [ ] Have we dropped at least 1–2 `tbdflow + "…"` breadcrumbs for the non-trivial decisions we made?
- [ ] Is the milestone commit type + subject drafted (e.g. `tbdflow commit -t feat -s effects -m "…"`), ready to be approved before we commit?
