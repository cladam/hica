# Hica Developer Guide

Step-by-step guide for developing a new feature in hica.

## Prerequisites

- Koka ≥ 3.2 installed
- Repository cloned with submodules:
  ```bash
  git clone --recurse-submodules https://github.com/cladam/hica.git
  # or, if already cloned:
  git submodule update --init --recursive
  ```
- Submodules: `lib/kunit` (test framework) and `lib/klap` (CLI parser)

## Compilation Pipeline

Understanding how hica compiles a `.hc` file:

```
.hc source → Lex → Parse → Type Check → Emit Koka (.kk) → Koka Compiler → C/JS/WASM
```

## Source Architecture

| Directory | Purpose |
|-----------|---------|
| `src/syntax/lexer.kk` | Tokenization |
| `src/syntax/parser.kk` | Recursive descent + Pratt expression parsing |
| `src/syntax/ast.kk` | AST node definitions |
| `src/syntax/fold.kk` | AST traversal utilities |
| `src/semantics/checker.kk` | Type inference (Hindley-Milner + unification) |
| `src/semantics/prelude.kk` | Extern function signatures (Koka-backed stdlib) |
| `src/emit/codegen.kk` | Hica AST → Koka source emission |
| `src/diagnostics/diagnostics.kk` | Error collection and rendering |
| `src/main.kk` | CLI entry point, build pipeline, prelude loading |

## Step-by-Step: Adding a New Feature

### 1. Check the Backlog

Look at `documentation/backlog.md` for the feature's status, complexity, and dependencies. If it's not listed, add an entry.

### 2. Write an Example First

Create a `.hc` file in `examples/` that shows how the feature should look from the user's perspective. This is your design spec.

```bash
# Reference existing examples for syntax conventions
ls examples/*.hc
```

### 3. Update the Lexer (if new syntax)

Edit `src/syntax/lexer.kk` if the feature requires:
- New keywords (add to keyword list)
- New operators or punctuation
- New literal forms

### 4. Update the AST

Edit `src/syntax/ast.kk` to add new expression or statement nodes. Each node carries a `span` for error reporting and optional type annotations.

### 5. Update the Parser

Edit `src/syntax/parser.kk`:
- Add parsing rules for the new syntax
- If it's an operator, integrate into the Pratt parser with correct precedence
- If it's a statement form, add a case in the statement parser

### 6. Update the Type Checker

Edit `src/semantics/checker.kk`:
- Add type inference rules for the new AST nodes
- Handle unification constraints
- Add exhaustiveness checks if relevant (e.g. new pattern forms)

If the feature introduces new built-in functions, add their signatures to `src/semantics/prelude.kk`.

### 7. Update Code Generation

Edit `src/emit/codegen.kk`:
- Add emission rules for the new AST nodes
- Remember: user-declared names get an `hc_` prefix to avoid Koka stdlib clashes
- Module names that clash with Koka keywords get an `hc-` prefix

### 8. Write Tests

Tests live in `tests/` and use the `kunit` framework.

| Test file | What to test |
|-----------|-------------|
| `tests/test-lexer.kk` | New tokens lex correctly |
| `tests/test-parser.kk` | New syntax parses to correct AST |
| `tests/test-codegen.kk` | New AST emits correct Koka code |
| `tests/test-cli.kk` | End-to-end: `.hc` file compiles and runs correctly |

Test conventions:
- Use `unit("description") { ... }` for pure tests
- Use `itest("description") { ... }` for tests with I/O
- Assertions: `assert/is-true()`, `assert/equals()`, `assert/is-false()`

### 9. Build and Run Tests

```bash
# Build the compiler
koka -ilib/klap -isrc src/main.kk -o hica
chmod +x hica

# Run individual test suites
koka -ilib/kunit -isrc -e tests/test-lexer.kk
koka -ilib/kunit -isrc -e tests/test-parser.kk
koka -ilib/kunit -isrc -e tests/test-codegen.kk
koka -ilib/kunit -ilib/klap -isrc -e tests/test-cli.kk -- ./hica

# Or run everything at once
bash test-hica.sh
```

### 10. Test with Examples

```bash
# Run your new example
./hica run examples/my-feature.hc

# Also run check mode (type-check only, no compilation)
./hica check examples/my-feature.hc

# Verify existing examples still work
./hica run examples/hello.hc
./hica run examples/fizzbuzz.hc
```

### 11. Update the Prelude (if applicable)

If the feature adds standard library functions written in hica:

- Add to the appropriate file in `prelude/` (`math.hc`, `strings.hc`, `operators.hc`, `cli.hc`, `io.hc`)
- Or create a new prelude file and register it in `src/main.kk` (load order matters)

### 12. Add a Learn Lesson (if applicable)

If the feature is user-facing and significant, add a numbered lesson in `learn/`:
- Follow the sequential numbering convention (`NN-topic.hc`)
- Include explanatory comments, runnable code, and a challenge section

### 13. Update Documentation

- `docs/language-reference.md` — Syntax additions
- `docs/standard-library.md` — New stdlib functions
- `docs/style-guide.md` — Conventions for the new feature
- `documentation/backlog.md` — Mark the feature as done

### 14. Commit

```bash
tbdflow commit -t feat -m "add <feature description>"
```

## Build Commands Reference

| Command | Purpose |
|---------|---------|
| `koka -ilib/klap -isrc src/main.kk -o hica` | Debug build |
| `koka -O2 -ilib/klap -isrc src/main.kk -o hica` | Release build |
| `chmod +x hica` | Make binary executable |
| `./hica --version` | Verify build |
| `./hica run <file>.hc` | Compile and run a hica program |
| `./hica build <file>.hc` | Compile only |
| `./hica check <file>.hc` | Type-check only |
| `./hica clean` | Clean build artifacts |
| `bash test-hica.sh` | Run full test suite |

## CI Pipeline

CI runs on push to `main` and on PRs. It builds on Ubuntu (x86_64) and macOS (arm64).

Steps: checkout with submodules → install Koka → build compiler → verify binary → run lexer/parser/codegen tests.

Ensure submodules are included in CI checkout (`submodules: true`).

## Naming Conventions

- Functions and variables: `snake_case`
- Constructors and types: `PascalCase`
- Use `fun` not `fn` for function declarations
- Return type annotation: `fun foo(x: int) : bool` (colon, not `->`)
- Booleans are lowercase: `true`, `false`
- Top-level expressions must be inside `fun main() { ... }`
