# Codegen Limitations & Name Marshalling

Known issues discovered while writing examples (2026-04-26).

## 1. Name clashes with Koka stdlib

Hica emits user-defined names verbatim into Koka source. If a hica function
has the same name as a Koka stdlib function, Koka's type checker rejects it
as ambiguous.

**Example:** `fun abs(x) => ...` clashes with `std/core/int/abs`.

**Other risky names:** `map`, `filter`, `show`, `print`, `println`, `max`,
`min`, `length`, `head`, `tail`, `zip`, `fold`, `take`, `drop`, `reverse`,
`sort`, `compare`, `string`, `list`, `int`, `bool`, `char`, `order`.

### Current fix: name resolution (Phase 6)

The codegen collects all user-declared top-level function names. Only those
get the `hc_` prefix. Names not declared by the user pass through to Koka
unchanged, so `abs(5)` calls Koka's `abs` when the user hasn't defined one.

`main` is excluded from the declared set so it stays as Koka's entry point.
Local bindings (params, let-bound vars, pattern vars) are also excluded,
producing cleaner output (`x` instead of `hc_x`).

Additionally, filenames that collide with Koka keywords (e.g. `match.hc`)
are emitted as `hc-match.kk` / `module hc-match` to avoid parse errors.

## 2. Overloaded operators on untyped params

Koka's `+`, `-`, etc. are overloaded across `int`, `float64`, `string`.
When hica emits `fun add(a, b) = (a + b)` without type annotations, Koka
cannot resolve which `+` to use.

**Works:** `fun double(n) => n * 2` — the literal `2` constrains `n` to `int`.

**Fails:** `fun add(a, b) => a + b` — no literal to anchor the type.

### Fix: type annotations (Phase 5)

The type checker infers types for all params and return values. Codegen now
emits `fun hc_add(a : int, b : int) : int` — Koka resolves `+` to `int/(+)`.
This also fixes issue #4 (polymorphic higher-order functions).

## 3. Hyphenated identifiers

Hica's lexer treats `-` as the minus operator, so `is-even` is parsed as
`is - even` (three tokens). Koka uses hyphens in identifiers (`is-even`),
but hica inherits Rust/C-style conventions where `-` is always subtraction.

**Decision:** hica uses underscores (`is_even`). If we want kebab-case
support, the lexer would need a context-sensitive rule (hyphen is part of
an identifier when not surrounded by spaces and preceded by an alpha char).

## 4. Fully polymorphic higher-order functions

`fun apply(f, x) => f(x)` emits valid Koka, but Koka can't resolve the
call `apply(square, 7)` without type annotations because `f` is unconstrained.

**Fix:** same as #2 — type annotations from hica's type checker (Phase 5).
Now resolved.

## Priority

| # | Issue              | Status   | Fix                                       |
|---|--------------------|----------|-------------------------------------------|
| 1 | Name clashes       | Fixed    | Name resolution (Phase 6)                 |
| 2 | Overloaded ops     | Fixed    | Type annotations (Phase 5)                |
| 3 | Hyphenated idents  | N/A      | Design decision (use underscores)         |
| 4 | Polymorphic HOFs   | Fixed    | Type annotations (Phase 5)                |

