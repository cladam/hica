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

### Current fix: name marshalling (prefixing)

All user-defined names get an `hc_` prefix. A small passthrough list
(`main`, `println`, `print`, `trace`, `show`) lets hica code call core
Koka I/O functions directly.

**The unsolved tension:** if a user writes `abs(5)` without defining `abs`,
they probably want Koka's `abs` — but the current approach prefixes it to
`hc_abs(5)` which doesn't exist. The real fix is to distinguish declarations
from call sites:
- **Declarations** (`fun abs(x)`) → always prefix to avoid shadowing
- **Calls** (`abs(5)`) → check if the name was declared in hica; if not,
  pass through to Koka

This requires a **name resolution pass** (tracking which names are in scope)
before emission. Until then, the passthrough list stays small and safe.

## 2. Overloaded operators on untyped params

Koka's `+`, `-`, etc. are overloaded across `int`, `float64`, `string`.
When hica emits `fun add(a, b) = (a + b)` without type annotations, Koka
cannot resolve which `+` to use.

**Works:** `fun double(n) => n * 2` — the literal `2` constrains `n` to `int`.

**Fails:** `fun add(a, b) => a + b` — no literal to anchor the type.

### Fix options

1. **Emit type annotations** when the hica type checker has inferred them
   (requires type checker — Phase 2).
2. **Default to `int`** — emit `: int` on untyped params as a stopgap.
3. **Qualify operators** — emit `int/(+)` instead of `+` when types are unknown
   (ugly but unambiguous).

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

**Fix:** same as #2 — needs type annotations from hica's type checker.

## Priority

| # | Issue              | Blocker? | Fix                              |
|---|--------------------|----------|----------------------------------|
| 1 | Name clashes       | Yes      | Name marshalling (`hc_` prefix)  |
| 2 | Overloaded ops     | Partial  | Type annotations (needs checker) |
| 3 | Hyphenated idents  | No       | Design decision (use underscores)|
| 4 | Polymorphic HOFs   | Partial  | Type annotations (needs checker) |



Confirmed: the generated Koka code is valid — match as a module name is a keyword collision. This is a pre-existing codegen issue (file-to-module naming), not related to Phase 5.

Phase 5 summary:

All 10 examples build successfully through hica build
Type annotations are emitted on function params, return types, and let bindings
Generated Koka code compiles for 9/10 examples; the 1 failure is a pre-existing module match keyword collision (not a type annotation issue)
This is a good commit point. The match module-name issue should be tracked separately as a codegen limitation.