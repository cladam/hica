# Hica CLI Plan

Modeled after Cargo and [Lisette's CLI](lisette-main/docs/intro/quickstart.md).

## Target CLI

```
$ hica --help

hica v0.1.0 (koka)

Usage: hica [OPTIONS] [COMMAND]

Options:
  -V, --version    Print version info and exit
  -h, --help       Print help

Commands:
    build, b    Compile a .hc file to Koka
    run, r      Compile and run a .hc file
    check, c    Analyze a .hc file and report errors
    clean       Remove the target directory
    help        Print this message

See 'hica help <command>' for more information on a specific command.
```

## Implementation Status

### Phase 1: build + run + check + clean (done)
- `hica build <file.hc>` / `hica b` — reads a `.hc` file, runs the pipeline (lex → parse → emit), writes `.kk` output to `target/`
- `hica run <file.hc>` / `hica r` — does `build`, then invokes `koka` on the generated `.kk` file and runs it
- `hica check <file.hc>` / `hica c` — runs lex → parse, reports errors without emitting
- `hica clean` — removes the `target/` directory
- `hica help <command>` — per-command help
- `hica --version` / `hica -V` — version info
- `hica` (no args) / `hica --help` / `hica -h` — prints usage

### Phase 2: deeper check + diagnostics
- Wire up type checker in `hica check` once `semantics/checker.kk` is implemented
- Structured error output with spans and source snippets

### Phase 3: project management
- `hica new <name>` — scaffolds a project directory with `src/main.hc`
- `hica init` — scaffolds in existing directory

### Phase 4: test runner
- `hica test` / `hica t` — discover and run `.hc` test files

## Language Backlog

Features to add to the hica language itself, ordered roughly by complexity.

### `else if` desugaring (parser)
Parse `else if` as sugar for nested `If` nodes so fizzbuzz-style chains stay
flat instead of staircase-nesting. Low complexity — parser-only change.

### Pipe operator `|>` (lexer + parser)
Desugar `a |> f` into `f(a)` during parsing. Enables pipeline style:
`3 |> square |> double` instead of `double(square(3))`. Low complexity.

### Type annotations (lexer + parser + codegen)
Support optional annotations: `fun double(x: int) : int => x * 2`.
Requires `: type` parsing in params and return position, threading through
the AST, and emitting annotations in Koka output. Medium complexity.
Also unblocks overloaded-operator resolution (see codegen-limitations.md #2).

### Destructuring in match (parser + codegen)
Allow pulling values out of structs/tuples in match arms, leveraging Koka's
native pattern matching. Depends on adding struct/tuple types first.

### Formatter: `hica fmt` (CLI + pretty printer)
Code formatter using the Wadler-Leijen pretty-printing algorithm.
Parse `.hc` source into AST, then re-emit with canonical style.

**Style rules (the "Hica Standard"):**
- 2-space indentation
- Open brace on same line as `fun`/`if` (1TBS, not Allman)
- Single-line `=>` bodies when short; indent 2 after `=>` when multi-line
- Spaces around operators: `x * 2`, not `x*2`
- Semicolons separate bindings/side-effects; never on the last expression
- Flatten `else if` (no staircase nesting)
- `--check` flag: exit non-zero if file isn't formatted (for CI)

**CLI:** `hica fmt <file.hc>`, `hica fmt --check <file.hc>`

**Implementation:** read file → lex → parse → pretty-print AST → write.
Medium complexity — needs a pretty-printer module (`emit/format.kk`).

### Technical Notes
- Koka stdlib: `std/os/env` for `get-args()`, `std/os/file` for file I/O, `std/os/path` for paths
- Output dir: `target/` (following Cargo/Lisette convention)
- `hica build examples/hello.hc` → writes `target/main.kk`
- `hica run examples/hello.hc` → writes `target/main.kk`, then runs `koka -e target/main.kk`
- Short aliases follow Cargo convention: `b`=build, `r`=run, `c`=check, `t`=test
