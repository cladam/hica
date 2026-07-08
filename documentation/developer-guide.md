# hica Developer Guide

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
.hc source → Lex → Parse → Desugar → Type Check → Emit Koka (.kk) → Koka Compiler → C/JS/WASM
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
| `src/transform/desugar.kk` | AST-to-AST rewrites (range/bit patterns → guards) |
| `src/emit/codegen.kk` | hica AST → Koka source emission |
| `src/emit/codegen-js.kk` | hica AST → JavaScript source emission |
| `src/emit/codegen-js-repl.kk` | JS REPL mode emission |
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

If the feature affects the JS target, also update `src/emit/codegen-js.kk` and the JS runtime preamble. If it affects the REPL, update `src/emit/codegen-js-repl.kk`. Run `make test-js` to verify no JS regressions.

### 8. Write Tests

Tests live in `tests/` and use the `kunit` framework.

| Test file | What to test |
|-----------|-------------|
| `tests/test-lexer.kk` | New tokens lex correctly |
| `tests/test-parser.kk` | New syntax parses to correct AST |
| `tests/test-codegen.kk` | New AST emits correct Koka code |
| `tests/test-cli.kk` | End-to-end: `.hc` file compiles and runs correctly |
| `tests/choreo/test-hica-cli.chor` | ATDD acceptance tests for CLI commands |
| `tests/choreo/test-hica-repl.chor` | ATDD acceptance tests for the REPL |

Test conventions:
- Use `unit("description") { ... }` for pure tests
- Use `itest("description") { ... }` for tests with I/O
- Assertions: `assert/is-true()`, `assert/equals()`, `assert/is-false()`

### 9. Build and Run Tests

```bash
# Debug build (fast iteration)
make build

# Optimised release build
make release

# Run individual test suites
make test-lexer
make test-parser
make test-codegen
make test-cli     # end-to-end, requires a built binary
make test-js      # JS backend, requires a built binary
make choreo-cli   # ATDD CLI acceptance tests
make choreo-repl  # ATDD REPL acceptance tests

# Or run everything at once
make test
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
- After any prelude change, re-bundle and rebuild:
  ```bash
  make bundle-prelude release
  ```

If the feature adds functions to the standard library (`stdlib/std/*.hc`):

- Edit or add the relevant file under `stdlib/std/`
- Re-bundle, rebuild, and clear the runtime cache:
  ```bash
  make bundle-stdlib release
  rm -f ~/.hica/stdlib/*.hc ~/.hica/stdlib/*.kk
  ```

### 12. Add a Learn Lesson (if applicable)

If the feature is user-facing and significant, add a numbered lesson in `learn/`:
- Follow the sequential numbering convention (`NN-topic.hc`)
- Include explanatory comments, runnable code, and a challenge section

### 13. Update Documentation

- `docs/language-reference.md`: Syntax additions
- `docs/standard-library.md`: New stdlib functions
- `docs/style-guide.md`: Conventions for the new feature
- `documentation/backlog.md`: Mark the feature as done

### 14. Commit

```bash
tbdflow commit -t feat -m "add <feature description>"
```

## Build Commands Reference

All common operations are available via `make`. Run `make` with no target for a debug build.

| Make target | Purpose |
|-------------|--------|
| `make build` | Debug build (fast, no `-O2`) |
| `make release` | Optimised release build |
| `make bundle` | Bundle prelude + stdlib, then release build |
| `make bundle-prelude` | Embed `prelude/*.hc` → `src/prelude-bundle.kk` |
| `make bundle-stdlib` | Embed `stdlib/std/*.hc` → `src/stdlib-bundle.kk` |
| `make test` | Full test suite via `test-hica.sh` |
| `make test-lexer` | Lexer unit tests |
| `make test-parser` | Parser unit tests |
| `make test-codegen` | Codegen unit tests |
| `make test-cli` | End-to-end CLI tests |
| `make test-js` | JS backend tests |
| `make choreo-cli` | ATDD CLI acceptance tests |
| `make choreo-repl` | ATDD REPL acceptance tests |
| `make playground` | Build the browser playground |
| `make playground-serve` | Build + serve playground on `localhost:8080` |
| `make clean` | Remove binary and clear stdlib runtime cache |

Raw hica commands:

| Command | Purpose |
|---------|--------|
| `./hica --version` | Verify build |
| `./hica run <file>.hc` | Compile and run a hica program |
| `./hica build <file>.hc` | Compile only |
| `./hica check <file>.hc` | Type-check only |
| `./hica clean` | Clean build artifacts |

## Scripts Reference

All helper scripts live in `scripts/`. Run them from the repository root.

### `scripts/bundle-prelude.sh`

Embeds the prelude `.hc` source files into `src/prelude-bundle.kk` as string constants. This makes the hica binary self-contained — no external prelude files needed at runtime.

```bash
bash scripts/bundle-prelude.sh
```

Files bundled (in load order):
- `prelude/math.hc`
- `prelude/glob.hc`
- `prelude/strings.hc`

Run this whenever you edit a prelude file, then rebuild the binary.

### `scripts/bundle-stdlib.sh`

Embeds the stdlib `.hc` source files into `src/stdlib-bundle.kk` as `(module-path, source)` pairs. Enables `import "std/list"` etc. without external files.

```bash
bash scripts/bundle-stdlib.sh
```

Modules bundled:
- `std/term`, `std/ops`, `std/list`, `std/string`
- `std/io`, `std/actor`, `std/datetime`, `std/cli`, `std/env`

Run this whenever you edit a stdlib file, then rebuild the binary and clear the cache:

```bash
make bundle-stdlib release
rm -f ~/.hica/stdlib/*.hc ~/.hica/stdlib/*.kk
```

### `scripts/build-playground.sh`

Builds the browser-based hica REPL/playground.

```bash
bash scripts/build-playground.sh
```

Steps performed:
1. Compiles `src/playground.kk` with Koka's `--target=js` backend.
2. Bundles the output into `playground/hica-compiler.js` via `esbuild`.
3. Generates `playground/prelude-sources.js` (browser-safe prelude subset).
4. Generates `playground/stdlib-sources.js` (`std/ops`, `std/list`, `std/string`, `std/term`).

Prerequisites: `koka` and `npx` (esbuild) must be available on `$PATH`.

To preview locally after building:

```bash
cd playground && python3 -m http.server 8080
open http://localhost:8080
```

> Note: `std/io`, `std/actor`, `std/cli`, and `std/env` are excluded from the playground build — they rely on Node.js/native APIs not available in the browser.

## CI Pipeline

CI runs on push to `main`, on PRs, and on version tags (`v*.*.*`). Defined in `.github/workflows/build.yml`.

**Matrix**: Ubuntu x86_64, Ubuntu arm64, macOS arm64, Windows x86_64.

**Steps per platform:**
1. Checkout with submodules (`submodules: true` — required for kunit/klap)
2. Install Koka (via the official install script)
3. Build — debug on branch push, release (`-O2`) on version tags
4. Verify binary (`./hica --version`)
5. Unit tests: lexer, parser, codegen
6. End-to-end CLI tests (`test-cli.kk`); Windows runs with `continue-on-error` due to path-handling differences
7. Choreo ATDD acceptance tests: `make choreo-cli` + `make choreo-repl` (Unix only; requires `cargo install choreo`)
8. JS backend tests: `make test-js` (Unix only)
9. Strip binary (Linux) / ad-hoc codesign (macOS)
10. Package as `.tar.gz` (Unix) or `.zip` (Windows) and upload as GitHub Actions artifact

**Release job**: triggered only on version tags. Downloads all platform artifacts and creates a GitHub Release with generated release notes.

Ensure submodules are always included in CI checkout (`submodules: true`).

## Naming Conventions

- Functions and variables: `snake_case`
- Constructors and types: `PascalCase`
- Use `fun` not `fn` for function declarations
- Return type annotation: `fun foo(x: int) : bool` (colon, not `->`)
- Booleans are lowercase: `true`, `false`
- Top-level expressions must be inside `fun main() { ... }`
