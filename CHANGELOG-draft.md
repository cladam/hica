# Unreleased since v0.29.3 (2026-05-26)

### 🐛 Fixes

- fix(effects): auto-install panic handlers in test-mode `main` for every
  user-declared `handle`-style effect visible in the merged program
  (see [hedit](https://github.com/cladam/hedit) `docs/hica-issues.md` Issue #5).
  Before: a `pub fun` whose inferred effect row carried two or more
  user-defined effects (e.g. `<Terminal, Clipboard>`) forced *every* test in
  the file to install *every* handler, or the whole file failed to compile
  with an opaque `unhandled effect: <mod>/<eff>` error naming `fun main` —
  because Koka's `try({ hctestN() })` wrapper only discharges `exn`, not
  user effects.
  After: `emit-test-program` wraps each `hctestN()` invocation in
  `try({ <panic-handlers> hctestN() })` where every visible `handle`-style
  effect gets a `ctl <op>(...) -> throw("unhandled op: <effect>.<op>")`
  arm. The user's own `handle` inside the test body still shadows the
  panic arms (Koka picks the innermost matching handler), so tests that
  install real handlers keep working. A test that actually invokes an op it
  forgot to install now fails at **runtime** with a targeted
  `"unhandled op: <effect>.<op> — install a handler in your test"` message
  — pointing at the failing test — instead of at compile time against the
  whole file. Named effects (`spawn`-promoted) are skipped: they're only
  reachable through explicit `spawn … as ref` installation. Two new tests
  in `tests/test-effects.kk` cover the panic-wrap path and the
  no-user-effects degrade-to-original-shape path. Repro: hedit's
  `tests/runtime_test.hc` under a Copy/Paste-carrying `event_loop` now
  goes green with zero test-file changes.

### ✨ Features


- feat(named-effects): milestone N4 — `hica check` row reporting now covers every named-effect dispatch style. Spawn-only, mixed handle+spawn, and cross-effect scenarios all surface exactly one row entry per effect, matching the v1 `hica check` contract. The analyser walks `ESpawn` state initialisers and arm bodies without false positives (spawn scaffolding accrues no debt). Milestone landed as tests-only (three new named-effect regression tests, two new analyser tests) plus `pub fun discover-effects` in `src/main.kk` so tests can call it directly. Makefile: `test-named-effects` now links libcurl transitively (needed once we import `main`).
- feat(named-effects): milestone N5 — `actor` sugar retires `send_<name>` and the `with_<name>` callback helper. Each `actor Name { … }` now desugars to a single effect declaration with a bare `send(msg)` op; users install instances with `spawn Name { send(msg) => body } as ref` and dispatch with `ref.send(msg)`. Two actors both declaring `send` compose freely — codegen emits effect-qualified Koka op names (`hc_<effect>_<op>`) so Koka's auto-generated `hc_<op>/@select` selectors don't collide.
- fix(checker): spawn binders now visible through `Let`/`VarDecl` bodies — `extend-let-chain` threads `ESpawn` binders alongside Let/Var bindings, so `var final = -1; spawn Counter { … } as c; c.op()` works even when the spawn is nested after a top-of-function `var`.
- [91770ff](https://github.com/cladam/hica/commit/91770ff) feat: improve hica-changelog.hl: emoji headers, tag range, hash prefix
- [bc821a1](https://github.com/cladam/hica/commit/bc821a1) feat: add hica-changelog.hl and hica-tests.hl dev scripts
- [d442a5a](https://github.com/cladam/hica/commit/d442a5a) feat: add hica-lisp as a git submodule
