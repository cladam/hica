# Unreleased since v0.29.3 (2026-05-26)

### 🐛 Fixes

- fix(manifest, build): `@koka { include: "..." }` in `hica.hml` is now
  honored by `hica build`/`hica run` (see [hedit](https://github.com/cladam/hedit)
  `docs/hica-issues.md`: "@koka { include } not honored by hica build").
  Two independent bugs conspired to hide the include from koka's `-i`
  search path when only a *helper* module transitively imported the
  library:

  1. `hml-field` in `src/main.kk` was line-oriented and never noticed
     the closing `}` on the same header line, so the compact form
     `@koka { include: "./lib/hilisp/src" }` parsed as an unterminated
     block and the include list came back empty. Multi-line blocks
     (`@koka {\n    include: …\n}`) worked, which is why the bug went
     unnoticed for the other manifest blocks. `hml-field` now peels the
     trailing `}` off the header line and scans the inner body, so
     compact and expanded forms behave identically.

  2. `import-dirs` only walked the *direct* imports of the entry file.
     `hica test tests/hilisp_host_test.hc` succeeded because the test
     itself imports `../lib/hilisp/src/lisp`, but `hica build
     src/main.hc` (which reaches `lisp` only via `hilisp_host.hc`)
     omitted `lib/hilisp/src` from koka's `-i` list and failed with
     `could not find module: lisp`. `import-dirs` now walks the same
     graph as `collect-extern-env` / `compile-imports`, contributing
     the directory of every reachable `.hc` (with cycle-safety and
     dedup).

  Combined effect: any project that keeps a hica library under
  `lib/…/src` and lists it via `@koka { include }` — including hedit's
  `lib/hilisp/src` bridge — builds without a manifest workaround. Tests,
  `hica check`, and the JS backend all pick up the same graph walk via
  their existing `include-dirs` plumbing.

- fix(codegen): map operations on `list<(K, V)>` now emit through

  `list.foldr` instead of `.find`/`.any`/`.map`/`.filter` chains (see
  [hedit](https://github.com/cladam/hedit) `docs/hica-issues.md` Issue #6).
  Before: `map_set`/`map_get`/`map_remove`/`map_keys`/`map_values`/
  `map_contains_key` desugared to chains like
  `if xs.any(...) then xs.map(...) else xs ++ [(k, v)]`. Koka's `list.any`
  and `list.map` are recursive over `list<a>` and inferred as `<div>`,
  which then leaked into any callback that touched a map op — most
  visibly HiLisp's `register_host_dispatch` in hedit, whose callback
  signature is required to be `total`. The `<div>` row bubbled all the
  way out through the map helpers, forcing every consumer that stored
  host state as an alist to fall back to raw `env_set` bindings.
  After: each map op emits a single `list.foldr` pass. Koka's totality
  analysis recognises `foldr` as structurally recursive on the list
  spine, so map ops on `list<(K, V)>` now compose cleanly into `total`
  callbacks (as long as the payload's own `==` is total — which it is
  for `string`/`int`/`char`/…). Existing dot-called call sites keep
  working; only the emitted Koka shape changes.
  Codegen tests in `tests/test-codegen.kk` updated to assert the
  `.foldr(...)` shape. Repro: hedit's `hilisp_host.hc` (which uses
  `map_set` inside a `total` host-dispatch callback) now compiles clean
  once hica-lisp is rebuilt against the new codegen.

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
