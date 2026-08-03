# Technical Design Document: Native Documentation Engine & Docstrings (`hica analyse --document`)

## 1. Executive Summary

This specification outlines the integration of **docstring syntax (`///`)** into the Hica compiler and the extension of `hica analyse` to natively generate and verify project documentation (`--document` and `--check-docs`).

By embedding these capabilities directly into the compiler, Hica gains a zero-dependency, 100% offline documentation and drift-detection suite. The generated documentation acts as both human-readable Markdown docs and a deterministic context map for AI coding agents.

## 2. System Architecture

```
                       ┌─────────────────────────┐
                       │   Hica Source (*.hc)    │
                       └────────────┬────────────┘
                                    │
                                    ▼
                 ┌──────────────────────────────────────┐
                 │ Lexer & Parser (syntax/ast)          │
                 │  - Extracts `///` DocComments         │
                 │  - Attaches `doc` to `decl` nodes    │
                 └──────────────────┬───────────────────┘
                                    │
                                    ▼
                 ┌──────────────────────────────────────┐
                 │ Semantics Engine (semantics/analyser)│
                 │  - Evaluates Purity & Effects        │
                 │  - Scores FP Quality & Health        │
                 │  - Maps Data Models & Architecture   │
                 └──────────────────┬───────────────────┘
                                    │
    ┌─────────────────┬─────────────┴─────────────┬──────────────────┐
    ▼                 ▼                           ▼                  ▼
docs/ARCHITECTURE.md  docs/MODELS.md      docs/EFFECTS.md    docs/HEALTH.md     docs/ROUTER.md

```


## 3. Part I: Docstrings in Hica Core (`syntax/ast`)

### 3.1 Syntax Specification

Docstrings in Hica use triple-slash syntax (`///`) directly preceding top-level declarations (`fun`, `pub fun`, `struct`, `type`).

```hica
/// Calculates the total cost after applying discount and tax.
/// Returns `Err` if discount rate is outside 0.0..1.0.
pub fun calculate_total(price: float, discount: float) : result<float, string> => {
    if discount < 0.0 || discount > 1.0 {
        Err("Invalid discount rate")
    } else {
        Ok(price * (1.0 - discount))
    }
}

/// Represents geometric shapes supported by the renderer.
type Shape {
    Circle(radius: float),
    Rect(width: float, height: float)
}
```

### 3.2 Lexer Modifications

Add a new token variant to the lexer: `DocComment(string)`.

```koka
// In syntax/lexer
pub type token
  // ... existing tokens ...
  DocComment( text : string )
```

* Rule: Match consecutive lines starting with `///`, trim leading/trailing whitespace per line, and combine them with newlines into a single `DocComment` token value.

### 3.3 AST Modifications (`syntax/ast`)

Extend declaration structures in `syntax/ast` to store optional docstring metadata:

```koka
// In syntax/ast
pub struct fun-decl
  name        : string
  doc         : maybe<string>   // <-- NEW
  params      : list<string>
  param-types : list<hica-type>
  ret-type    : maybe<hica-type>
  body        : node
  span        : span
  is-pub      : bool

pub struct struct-decl
  name   : string
  doc    : maybe<string>       // <-- NEW
  fields : list<(string, hica-type)>
  span   : span

pub struct enum-variant
  name   : string
  fields : list<(string, hica-type)>

pub struct enum-decl
  name     : string
  doc      : maybe<string>     // <-- NEW
  variants : list<enum-variant>
  span     : span
```

### 3.4 Parser Integration

Update the parser rules for top-level declarations:

1. When encountering a `DocComment` token, store its content in a temporary buffer.
2. Expect the next non-whitespace token to be a declaration (`fun`, `pub fun`, `struct`, or `type`).
3. Attach the buffered string to the `doc` field of the created AST node.
4. If a `DocComment` is followed by anything other than a top-level declaration, emit a parsing warning and discard it.

## 4. Part II: `hica analyse --document` Engine

Extend `semantics/analyser` with a documentation generator pass.

### 4.1 New CLI Options

Extend `hica analyse` CLI flags:

```bash
# Generate the docs/ folder in current directory
hica analyse --document

# Specify custom output path
hica analyse --document --out-dir=custom_docs/

# Verify whether docs are up-to-date with current AST signatures (CI mode)
hica analyse --check-docs
```

### 4.2 Generated Documentation Suite Specs

When `--document` is passed, `hica analyse` executes a project-wide pass and writes five structured Markdown files into `docs/`:

#### 1. `docs/ARCHITECTURE.md`

Summarizes project organization, top-level entry points (`fun main`), imported standard libraries, and exported public symbols.

* **Data Sources:** Scans `import` statements (e.g., `import "std/io"`) and all declarations with `is-pub == True`.
* **Output Structure:**
* **Module Overview:** List of `.hc` files in the project.
* **Public Entry Points:** Table of `pub fun` signatures and attached docstrings.
* **Dependencies:** Standard library and relative module imports.

#### 2. `docs/MODELS.md`

Provides a central type dictionary for domain data models.

* **Data Sources:** `struct-decl` and `enum-decl` nodes in `syntax/ast`.
* **Output Structure:**
* **Structs:** Table of field names, field types (e.g., `int`, `string`, `list<T>`), and field descriptions extracted from docstrings.
* **Enums (ADTs):** Full variant catalog (e.g., `Circle(radius: float)`) with pattern-matching guidance.

#### 3. `docs/EFFECTS.md`

Tracks purity and side effects across the codebase.
* **Data Sources:** Reuses `analyse-decl` side-effect state tracking in `semantics/analyser`.

* **Effect Categories:**
* `Pure` (`total`): No side effects detected.
* `Console`: Uses `console-fns` (`println`, `eprintln`).
* `I/O & FileSystem`: Uses `fsys-fns` (`read_file`, `write_file`) or `io-fns` (`get_args`, `get_env`).
* `Divergent`: Contains unbounded `loop` or recursive calls.

* **Output Matrix:**

| Function | Signature | Purity Status | Detected Effect Dependencies |
| --- | --- | --- | --- |
| `calculate_total` | `(price: float, discount: float) : result<float, string>`<br> | ✅ Pure | None |
| `load_config` | `(path: string) : result<string, string>`<br> | ⚡ Impure | `fsys` (`read_file`) |

#### 4. `docs/HEALTH.md`

Reports functional programming quality scores and anti-pattern debt hotspots across all files.
* **Data Sources:** Existing `format-markdown` and `function-score` logic in `semantics/analyser`.
* **Output:**
* Total FP Quality Index (e.g., `92/100`).
* High-debt hotspots categorized by **Immutability** (`var`/`for`/`while` loops), **Pipelines/Allocation** (eager nested list operations), **Error Handling** (nested `match` on `Maybe`/`Result`), and **Double Wrapping**.

#### 5. `docs/ROUTER.md`

Acts as an anchor index for human navigation and AI agent context routing.

* **Data Sources:** AST spans (`span.start`, `span.end`) mapped back to source lines.
* **Output:** List of `hica://` symbol URIs mapped to line numbers and short docstring summaries:
```markdown
- [`calculate_total`](hica://src/pricing.hc:12) — Calculates total cost after discount and tax.
- [`Shape`](hica://src/models.hc:4) — Represents geometric shapes supported by renderer.
```

## 5. Part III: Drift Detection (`hica analyse --check-docs`)

To ensure documentation never gets out of date in CI pipelines, `--check-docs` verifies that current source code matches generated documentation.

### 5.1 Drift Check Algorithm

1. Parse all `.hc` files and extract signatures, docstrings, spans, and quality scores in memory.


2. Generate in-memory string representations of `ARCHITECTURE.md`, `MODELS.md`, `EFFECTS.md`, `HEALTH.md`, and `ROUTER.md`.
3. Compare the generated contents against the existing files in `docs/`.
4. If any file differs:
* Print exact out-of-sync symbols to `stderr`.
* Return exit code `1`.

5. If all files match, print `Documentation is up to date.` and exit with `0`.

## 6. Implementation Roadmap

### Phase 1: Syntax & Parser Updates

* [ ] Update `syntax/lexer` token types with `DocComment` token.
* [ ] Extend `fun-decl`, `struct-decl`, and `enum-decl` in `syntax/ast` with `doc : maybe<string>`.
* [ ] Update parser to attach comments to AST nodes.
* [ ] Add compiler unit tests verifying `doc` field population.

### Phase 2: Documentation Generator Pass

* [ ] Create `semantics/docgen.kk` (or extend `semantics/analyser`).
* [ ] Implement `generate-architecture-md` for exports and imports.
* [ ] Implement `generate-models-md` for structs and enums.
* [ ] Implement `generate-effects-md` using effect tracking from `analyser.kk`.
* [ ] Integrate existing `format-markdown` for `HEALTH.md`.
* [ ] Implement `generate-router-md` for `hica://` symbol spans.

### Phase 3: CLI Integration & Check Mode

* [ ] Add `--document`, `--out-dir`, and `--check-docs` options to `hica analyse` CLI parser.
* [ ] Wire file-writing logic for `docs/` directory output.
* [ ] Implement the in-memory string comparison pass for `--check-docs`.
* [ ] Write integration test running `hica analyse --check-docs` in test projects.