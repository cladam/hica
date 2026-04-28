# Hica Backlog

Consolidated backlog of language features, CLI improvements, and tooling.
Items are grouped by area and roughly ordered by complexity within each group.

Legend: **done** = shipped, **—** = not started

---

## Language Features

### Expressions & Operators

| Feature | Status | Complexity | Notes |
|---------|--------|------------|-------|
| Unary negation (`-x`, `!x`) | **done** | Low | Lexer, parser, checker, codegen |
| `else if` chains | **done** | Low | Parser desugaring |
| Pipe operator `\|>` | — | Low | Desugar `a \|> f` → `f(a)` in parser |
| String concatenation (`+` on strings) | — | Low | Checker + codegen |
| String interpolation (`"score: {n}"`) | — | Medium | Lexer + parser + codegen |
| Type annotations in syntax (`: int`) | — | Medium | Parser + AST + codegen; checker already infers |

### Pattern Matching

| Feature | Status | Complexity | Notes |
|---------|--------|------------|-------|
| Int literal patterns | **done** | — | `0 => ...`, `1 => ...` |
| Wildcard patterns | **done** | — | `_ => ...` |
| Variable patterns | **done** | — | `n => ...` |
| String literal patterns | — | Low | Parser + checker; codegen already emits strings |
| Destructuring patterns (tuples/structs) | — | Medium | Depends on tuple/struct types |
| Slice patterns (`[first, ..rest]`) | — | High | Depends on list types |

### Data Types

| Feature | Status | Complexity | Notes |
|---------|--------|------------|-------|
| Tuples (`(1, "hi")`, `.0`, `.1`) | — | Low | Koka has native tuples; parser + emitter only |
| Tuple destructuring (`let (a, b) = pair`) | — | Low | Parser + codegen |
| Lists (`[1, 2, 3]`) | — | Medium | Koka `list<a>`; same literal syntax |
| List operations (`map`, `filter`, `fold`) | — | Medium | Passthrough to Koka stdlib |
| Structs (`struct Point { x: int, y: int }`) | — | Medium | Emit Koka `struct` |
| Algebraic types / enums | — | High | Emit Koka `type` with variants |
| Maps / dictionaries | — | High | Koka `std/data/linearmap`; lower priority |

### Control Flow

| Feature | Status | Complexity | Notes |
|---------|--------|------------|-------|
| `if` / `else if` / `else` | **done** | — | Expression-valued |
| `match` | **done** | — | Int + wildcard + var patterns |
| `for i in 0..n` (range loop) | — | Medium | Emit Koka `for` or `list` + `foreach` |
| `while condition { ... }` | — | Medium | Emit Koka `while` |
| `repeat(n) { ... }` | — | Low | Emit Koka `repeat` |

### Functions

| Feature | Status | Complexity | Notes |
|---------|--------|------------|-------|
| Named functions (`fun f(x) => ...`) | **done** | — | Arrow + block bodies |
| Lambdas (`(x) => x * 2`) | **done** | — | Desugars to `Fun` node |
| Higher-order functions | **done** | — | Checker infers `TFun` types |
| Mutual recursion | — | Medium | Needs fixpoint or two-pass approach |

### Modules & Visibility

| Feature | Status | Complexity | Notes |
|---------|--------|------------|-------|
| Single-file compilation | **done** | — | `.hc` → `.kk` |
| `import "mymodule"` | — | High | Multi-file compilation, module graph |
| `pub` visibility | — | Medium | Emit Koka `pub` |

---

## Compiler Infrastructure

| Feature | Status | Complexity | Notes |
|---------|--------|------------|-------|
| Lexer | **done** | — | |
| Parser | **done** | — | |
| Type checker (HM inference) | **done** | — | Phases 0–4 |
| Diagnostics (`diag` effect) | **done** | — | Errors with spans |
| Codegen (type annotations) | **done** | — | Phase 5 |
| Name resolution | **done** | — | Phase 6; only declared names get `hc_` |
| Module keyword clash fix | **done** | — | `match.hc` → `hc-match.kk` |
| Structured error output with source snippets | — | Medium | Show line + caret |
| Desugaring pass | — | Medium | Separate pass for complex transforms |

---

## CLI

| Command | Status | Complexity | Notes |
|---------|--------|------------|-------|
| `hica build <file>` / `hica b` | **done** | — | Lex → parse → check → emit → koka |
| `hica run <file>` / `hica r` | **done** | — | Build + execute |
| `hica check <file>` / `hica c` | **done** | — | Type check + report |
| `hica clean` | **done** | — | Remove generated files |
| `hica help <command>` | **done** | — | |
| `hica --version` / `-V` | **done** | — | |
| `hica new <name>` | — | Low | Scaffold project directory |
| `hica init` | — | Low | Scaffold in existing directory |
| `hica test` / `hica t` | — | Medium | Discover + run test files |
| `hica fmt` / `hica fmt --check` | — | Medium | Pretty-printer (Wadler-Leijen) |

---

## What We Defer

These are explicitly **not** in scope near-term:

- **Row polymorphism / effect inference** — Koka handles this
- **Generics / let-polymorphism** — add later when needed
- **Type annotations in syntax** — parser doesn't parse `: type` yet
- **Sets** — Koka has no built-in set; use maps
- **File I/O** — passthrough to Koka stdlib when needed
- **Interfaces / traits** — Koka's effects cover many of the same use cases
