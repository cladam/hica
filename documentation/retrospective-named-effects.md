# Retrospective: Named / Instantiated Effects in hica

**Feature:** `spawn Name { … } as ref`, per-instance dispatch (`ref.op(args)`),
first-class `ref<Name>` type, escape rule, `actor` sugar collapse.
**Design doc:** [`named-effects-design.md`](named-effects-design.md)
**Implementation journal:** [`named-effects-journal.md`](named-effects-journal.md)
**Milestones shipped:** N1 → N5 (N5 landed before N4 in project order)
**Sessions:** 8 focused Cline sessions across ~4 calendar days
**Prior art:** [`retrospective-effects.md`](retrospective-effects.md) —
this is the v2 layer on the v1 effect-handler machinery.

---

## What Worked Well

- **Design-first, then milestones (same as v1).** The design doc `named-effects-design.md`
  was written before a single AST field changed, and every "should we do X or Y?"
  question during N1–N5 had an answer in §4 (syntax), §7 (codegen mapping), or §8
  (checker) already. Slicing survived intact: N1 shipped the parser+codegen, N2
  added dispatch, N3 landed the escape rule, N5 collapsed the actor sugar. Only
  N4 shifted late in the sequence.
- **Layering re-used verbatim.** Named effects sat directly on top of v1:
  `handle-arm` struct reused unchanged; `emit-handle-arm` gained a sibling
  `emit-named-arm`; the M4.5 `hc-op:` prefix tag inspired the N2 `hc-ref-op:`
  tag; M3's `discover-effects` already reported user effect rows and just
  needed to strip the `hc-ref-op:` prefix to keep working (N2 covered this
  in three lines). By N4 the "milestone" collapsed to *five tests* because
  every reporting invariant already held.
- **Lenient checker Mode B in N1.** Same trick as M1: N1's checker registered
  `TRef(E)` bindings without wiring up dispatch. This let N1 ship the parser +
  codegen + `two-counters` example end-to-end without committing to method-call
  semantics — those landed cleanly in N2 with the codegen already stable.
- **`emit-typed-program(src)` regression tests.** The v1 test harness from
  `tests/test-effects.kk` was copied to `tests/test-named-effects.kk` for N1
  and grew 4 → 7 → 10 → 13 → 14 → 17 across N1, N2, N3, N5, and N4. Every
  regression was a one-line grep on emitted Koka. Effect-qualified op names
  (N5) added one assertion; N4 row-reporting used the fresh `discover-effects`
  public API.
- **Journal-as-you-go workflow.** Each session read the last session's
  Log + Reflection and ended by writing its own. N1 session-2's handoff pointed
  the next session at the exact `parse-spawn-expr` insertion point and Stage B–E
  work; N2 opened by reading it and shipped in one session. N4's handoff went
  the other way: "N4 turned out to be no code — audit first, then tests."
- **`hica fmt` + `hica analyse` on every artefact.** Enforced from N1. Once N1
  taught the formatter about `spawn` / `as` / `handle` / `effect` / `actor`
  keywords, all subsequent examples stayed clean. The M6.5 analyser heuristic
  (`contains-lambda-assigning-to`) already handled the sanctioned "spawn
  arm mutates outer var" pattern, so N1's ESpawn analyser walker was a
  five-line arm addition.
- **Design doc §7 codegen mapping was again line-for-line accurate.** The
  `with c <- named handler` shape (§7.2), `ev<E>` type spelling (§7.4),
  `hc_<op>` naming (§7.1), and compilation-unit-wide promotion rule (§7.6)
  all landed as spec'd. The one deviation (effect-qualified op names in N5)
  was a codegen refinement, not a design change.

## Friction Points

| Issue | Root cause | Resolution |
|-------|-----------|------------|
| Koka `match` guards must be `total` | N2's ref-dispatch guard needs `effect-reg` to look up ops, which is not `total`; a `match | guard` would be rejected | Hoist the check into a plain `if` shell *before* the outer `match`; extract the remaining arms into a helper (`call-dispatch-arms`) at top-level. Sessions 3–4 lost half a day to this |
| Wrapping `emit-expr`'s Call arm in an `if/else match` breaks Koka's layout parser | Same block as above — Koka rejects `match` after `else` at the same indentation | Kept the fix inline: added a first arm to the existing `match (callee.expr, args)` cascade that guards on `raw-cname.starts-with(ref-op-tag).is-just`. Avoided a 400-line indentation shift |
| `emit-test-program` vs `emit-program` divergence | Test-mode emit forked early in v1 and didn't get the N1 spawn-promotion pass | Two-line fix in N2 to add the same `collect-spawn-effects` call. Logged as a "long-term extract shared helper" carry-forward |
| Koka's `hc_<op>/@select` selector collision on same-named ops in two `named effect`s | Koka auto-generates a per-op selector in the module; two effects with a `send` op collide | N5 change: emit *effect-qualified* op names for all `named effect`s (`hc_<effect>_<op>`). Plain `effect`+`handle` keeps un-qualified names |
| Nominal unification of `TRef(A)` vs `TRef(B)` | N3's initial `unify` fallback rejected any non-builtin pair, producing bogus `type mismatch: expected ref<Counter>, got ref<Counter>` | Added a symmetric `TRef(a), TRef(b)` arm alongside `TStruct`/`TEnum` |
| Declared `<Counter>` effect row rejected by Koka | Koka adds `exn` to virtually every body; a bare user row missing `div,exn` fails to unify | Codegen appends `div,exn` to every explicit function row. User surface stays minimal (`<Counter>`); emitted Koka gets a compatible baseline |
| `ref.op()` inside untyped `foreach` lambdas fails to dispatch | Checker sees the lambda param as `TVar`, not `TRef`; ref-dispatch is receiver-type-driven | Documented as a known N3 limitation. Workaround: declare a `ref<E>`-typed helper (`fun bump(c: ref<Counter>, n: int)`) and pass it to `foreach`. Matches design doc §13.2 |
| `extend-let-chain` didn't know about `ESpawn` | An `ESpawn` following a `var` at top-of-function was placed inside the `VarDecl`'s body field; the recursive helper only handled `Let`/`VarDecl`/`LetTuple` | N5 fix: added an `ESpawn(ename, _, _, binder) -> env.extend(binder, TRef(ename))` arm. Two-line change; unblocked the `learn/47-effects-actors.hc` rewrite |
| Test-source string lexer footguns in `tests/test-named-effects.kk` | Two spellings of a test crashed Koka's string lexer: `++` inside string interpolation, and `\{` / `\}` escapes | Documented as a carry-forward hazard: keep test-source strings *simple* — no `++`, no `\{`, no interpolation, no metacharacters. If necessary, build strings up in Koka out of small literals |
| Transitive libcurl link for `test-named-effects` | N4 tests import `main` to call `discover-effects`; `main` transitively imports the curl-backed `deps`/`http` modules; the linker fails without `-lcurl` | Added `--cclib=$(CURL_LIB)` to the `test-named-effects` Makefile rule. Documented as a hazard for any future test file that imports `main` |

## The `hc-ref-op:` Prefix Tag

Named-effect method dispatch reuses the M4.5 tag-in-the-AST trick. In N2 the
checker rewrites `Call(Var("incr"), [c1])` — where `c1 : TRef(Counter)` and
`incr ∈ Counter.ops` — as `Call(Var("hc-ref-op:incr"), [c1])`. Codegen's
`emit-expr` intercepts the tag and emits `c1.hc_incr()` — Koka's named-handler
dispatch shape.

N5 extended the tag to include the effect name (`hc-ref-op:counter:incr`) so
the qualified op-name codegen (`hc_counter_incr`) could re-build the right
Koka identifier without a fresh registry lookup. The parser is a two-segment
string split at emit time — same idea as v1's `hc-op:` unwrap.

**Trade-off:** the same design smell v1 flagged. A magic string prefix lives
in the AST between the checker and codegen phases. It's contained by
`strip-ref-op-tag` in codegen and `unwrap-op-tag-main` in the discharge
walker, but it is a leak of implementation detail. If we ever add a third
tag we should promote this to a real annotation field on `Var`.

## Effect-Qualified Op Names (N5's core codegen change)

Koka's `named effect` machinery auto-generates a `hc_<op>/@select` selector
per op. Two `named effect`s in the same module that declare a same-named
op — as `Pinger` and `Ponger` both declaring `send` did — collide on that
selector at Koka compile time:

```
ping-pong-actor.kk(43, 7): type error:
  definition hc_send/@select is already defined in this module, at (40, 7)
    hint: use a local qualifier?
```

The fix (N5): every `named effect` op is emitted as `hc_<effect>_<op>`, and
per-instance dispatch (`ref.send(msg)`) emits `ref.hc_<effect>_<op>(msg)`.
Plain `effect`+`handle` code keeps the un-qualified `hc_<op>` shape — only
named-effect ops get the qualifier.

The change spans three sites:

1. `emit-effect-op-decl(op, named-emit, effect-name)` — optional
   `effect-name` param; when non-empty and `named-emit`, prepend to build
   `hc_<effect>_<op>`.
2. `emit-effect-def` passes `ed.name` down to declarations.
3. `emit-named-arm(arm, declared, effect-name)` and `ESpawn`'s emit pass
   the effect name so arm bodies match the declaration.

Cross-module: each Koka module owns its own qualifiers, so the scheme keeps
working as long as no two effects with same op name land in the same emitted
`.kk` file. That's the current design guarantee.

## What Changed vs the Design Doc

**Nothing structural.** Every §4 syntax rule landed as spec'd (parser). Every
§7 codegen shape is implemented verbatim (spawn-emit, ref-dispatch, `ev<E>`
type, promotion rule). §8's checker sketch — approach-B escape tracking,
freshening on dispatch — is implemented step-for-step. §10's non-goals
(reference equality, multi-shot resumption, `ref<E>`-polymorphism) are
still non-goals.

**Three undocumented implementation details:**

1. **Effect-qualified op names** (N5). Design doc §7.1 mentions `hc_<op>`
   naming; the N5 refinement adds an effect prefix for `named effect`s to
   avoid the `@select` collision. Documented inline in `emit-effect-op-decl`
   and the N5 journal entry.
2. **The `hc-ref-op:<effect>:<op>` AST prefix tag** (N2 + N5). Internal to
   the checker↔codegen contract. Same design smell as v1's `hc-op:`.
3. **`div,exn` baseline appended to every explicit function row** (N3).
   Every user-declared `<Counter>` etc. emits `<counter,div,exn>` on the
   Koka side. Invisible at the hica surface but essential for the row to
   compile against Koka's baseline effects.

Both design smells (#1 and #2) are compiler internals, not language
features. If a contributor sees `Var("hc-ref-op:counter:incr")` in a
dumped AST, the answer is in `infer-ref-call` (checker) and
`strip-ref-op-tag` (codegen).

## Numbers

- **5 milestones** (N1 → N5), sequenced N1 → N2 → N3 → N5 → N4
- **~4 calendar days**, **8 focused Cline sessions**
- **17 regression tests** in `tests/test-named-effects.kk` (0 → 17)
- **2 new tests** in `tests/test-analyser.kk` (6 → 8)
- **2 test replacements** in `tests/test-effects.kk` (v1 M6 → N5)
- **5 runnable examples/tutorials** touched: `examples/effects/two-counters.hc`
  (N1/N2), `examples/effects/counter-pool.hc` (N3), `examples/effects/counter-actor.hc`
  (N5 rewrite), `examples/effects/ping-pong-actor.hc` (N5 collapse from M6
  callback tower), `learn/48-named-effects.hc` (N2 tutorial), `learn/47-effects-actors.hc`
  (N5 rewrite)
- **3 doc surfaces updated** (`docs/effects.md`, `docs/language-reference.md`,
  `SKILL.md` Koka row extended for named effects)
- **100% backwards compatible** — every v1 `effect`/`handle` program still
  compiles and runs unchanged; the design doc's compilation-unit-wide
  promotion rule is the only behaviour that changes when a `spawn` appears

## Lessons for Future Language Features

1. **Layering pays off.** N1–N5 was possible in ~4 days because every
   milestone re-used v1 machinery: `handle-arm` reused for arm parsing,
   M3's `discover-effects` for row reporting, M4.5's `hc-op:` trick
   inspired N2's `hc-ref-op:`, M6.5's `contains-lambda-assigning-to`
   handled the analyser without new code, the `emit-typed-program(src)`
   test harness was a one-file copy. **Design a v1 with the v2 shape
   in mind** — the layering re-use is where the time savings compound.
2. **Handoff notes are worth more than commit messages.** Every N-milestone
   session ended with 30–100 lines of handoff for the next session — file
   paths, function names, exact insertion points. Made session context
   transitions mechanical.
3. **"Codegen shape first, semantics second" (via lenient checker).**
   Mode B in N1 shipped valid Koka before the checker knew what
   `TRef(E)` meant. When N2 tightened the checker, the codegen didn't
   move an inch. Repeat this pattern for any future feature that
   involves both new syntax and new type-system semantics.
4. **Don't refactor huge match cascades to add one arm.** N2 initially
   tried to extract `emit-expr`'s Call cascade into a helper to add a
   dispatch guard cleanly. This would have been a 400-line indentation
   shift on `codegen.kk`. Reverted and added the guard as the *first arm
   of the existing cascade* — three lines total. Whenever a semantic
   change fits inside an existing match arm, prefer that to a
   file-shape refactor.
5. **Koka's `total`-guard restriction is a real design constraint.** If
   a check needs the effect registry or any other non-total lookup, it
   must be a plain `if` shell before the `match`, not a `match | guard`.
   Learned twice (N2 session 3, and again in a smaller way in N5). Add
   this to the v1 carry-forward hazards permanently.
6. **String-lexer footguns in test sources.** Keep test-source `.kk`
   strings *simple* — no `++`, no `\{` / `\}`, no interpolation, no
   metacharacters. If you need a special character in an assertion,
   build the string up in Koka out of small literals and join. Cost:
   two false-start test attempts in N4.
7. **Sequence matters less than you think.** N5 shipped *before* N4 in
   this project. This ended up being fine because N4 was mostly tests +
   a `pub fun discover-effects` visibility change; the audit-first
   discipline in N4's plan turned it into a five-line milestone.
   Take-away: don't over-order milestones — if a later one is
   well-scoped and cheap, ship it early.
8. **`--cclib` propagates transitively.** Any test file importing
   `main` needs the same `--cclib` flags as the top-level build (curl
   for hica). Log this once and add a shared Makefile fragment if it
   happens again.

## Verdict

The feature shipped as designed, on the milestone plan, with two
codegen refinements (effect-qualified op names, `div,exn` row baseline)
and one milestone re-order (N5 → N4). Backwards compatibility is 100%.
The compiler grew by roughly 250 lines of checker + codegen (~4% of
`src/`) to gain first-class named effect instances, per-instance
dispatch, a first-class `ref<E>` type, and the compile-time escape
rule.

The friction points were almost entirely at the hica↔Koka boundary
(same as v1): guard totality, layout-parser surprises, selector
collisions on same-named ops, the `div,exn` baseline. The hica-native
design decisions — Mode B leniency, the `hc-ref-op:` tag, approach-B
escape tracking, effect-qualified op names — all landed without any
mid-milestone re-scoping.

The payoff:

- Two counters with independent state in the same function — a two-line
  change from single-instance to per-instance dispatch (§2.1 of the
  design doc, exit criterion of N1/N2).
- Ping-pong collapsed from the M6 `with_pinger(() => with_ponger(…))`
  callback tower + `send_pinger`/`send_ponger` name-mangling workaround
  to a flat `spawn Pinger as pinger; spawn Ponger as ponger; rally(...)`
  reading top-to-bottom (§2.2 → §6, N5 exit).
- Actor pools with `list<ref<Counter>>` and a `bump(c: ref<Counter>, n:
  int)` helper (§2.3 → N3 exit, `counter-pool.hc`).
- Multi-connection Db (design doc §13.4) is now expressible — parameter
  refs may be passed to callees without triggering the escape rule.

**Would we do it again the same way?** Yes. The one thing to change:
document the "handoff notes end with exact next-session prompts" rule
in the ground rules from day one. It emerged organically during v1 but
was the single most valuable session-to-session discipline for v2.

Next up: no immediate follow-on. The design doc §10 non-goals
(reference equality, non-resuming ops, multi-shot resumption,
`ref<E>`-polymorphism) all remain non-goals until concrete demand
appears. If a real use case surfaces — supervision trees, dynamic
actor registries with cross-module sharing, effect abstraction over
generic `ref<E>` — the pattern from this retro (design doc first,
milestone slicing, lenient checker, layer on v1) should apply
verbatim.
