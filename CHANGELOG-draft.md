# Unreleased since v0.29.3 (2026-05-26)

### ✨ Features

- feat(named-effects): milestone N5 — `actor` sugar retires `send_<name>` and the `with_<name>` callback helper. Each `actor Name { … }` now desugars to a single effect declaration with a bare `send(msg)` op; users install instances with `spawn Name { send(msg) => body } as ref` and dispatch with `ref.send(msg)`. Two actors both declaring `send` compose freely — codegen emits effect-qualified Koka op names (`hc_<effect>_<op>`) so Koka's auto-generated `hc_<op>/@select` selectors don't collide.
- fix(checker): spawn binders now visible through `Let`/`VarDecl` bodies — `extend-let-chain` threads `ESpawn` binders alongside Let/Var bindings, so `var final = -1; spawn Counter { … } as c; c.op()` works even when the spawn is nested after a top-of-function `var`.
- [91770ff](https://github.com/cladam/hica/commit/91770ff) feat: improve hica-changelog.hl: emoji headers, tag range, hash prefix
- [bc821a1](https://github.com/cladam/hica/commit/bc821a1) feat: add hica-changelog.hl and hica-tests.hl dev scripts
- [d442a5a](https://github.com/cladam/hica/commit/d442a5a) feat: add hica-lisp as a git submodule
