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

### Fix: name marshalling (prefixing)

Emit user-defined names with a prefix to avoid clashes:

```
hica: fun abs(x) => ...
koka: fun hc_abs(x) = ...        // prefixed
koka:   val result = hc_abs(-5)  // call sites also prefixed
```

**Scope:** function declarations, variable bindings, function call targets,
pattern variables. Literals and operators are unaffected.

**Implementation:** in `emit/codegen.kk`, wrap name emission in a
`marshal-name(name)` function:

```koka
fun marshal-name( name : string ) : string
  "hc_" ++ name
```

Apply it in `emit-decl` (function name + params), `emit-expr/Var`,
`emit-expr/Let` (binding name), and `emit-expr/Call` (callee if Var).

**Exception:** `main` must NOT be prefixed — Koka expects `fun main()`.

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
