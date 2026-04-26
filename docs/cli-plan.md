# Hica CLI Plan

Modeled after [Lisette's CLI](lisette-main/docs/intro/quickstart.md).

## Target CLI

```
hica help

hica v0.1.0 (koka)

Usage: hica <command>

Commands:
    new        Create a new project
    build      Compile a .hc file to Koka
    run        Compile and run a .hc file
    check      Validate a .hc file
    clean      Remove build artifacts
    help       Print this message

Hint: Run hica help <command> to learn more about a command.
```

## Implementation Phases

### Phase 1: build + run (current)
- `hica build <file.hc>` — reads a `.hc` file, runs the pipeline (lex → parse → emit), writes `.kk` output to `target/`
- `hica run <file.hc>` — does `build`, then invokes `koka` on the generated `.kk` file and runs it
- `hica` (no args) / `hica help` — prints usage

### Phase 2: check + diagnostics
- `hica check <file.hc>` — runs lex → parse → type check, reports errors without emitting

### Phase 3: project management
- `hica new <name>` — scaffolds a project directory with `src/main.hc`
- `hica clean` — removes the `target/` directory

### Technical Notes
- Koka stdlib: `std/os/env` for `get-args()`, `std/os/file` for file I/O, `std/os/path` for paths
- Output dir: `target/` (following Lisette/Rust convention)
- `hica build examples/hello.hc` → writes `target/main.kk`
- `hica run examples/hello.hc` → writes `target/main.kk`, then runs `koka -e target/main.kk`
