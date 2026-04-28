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

### Technical Notes
- Koka stdlib: `std/os/env` for `get-args()`, `std/os/file` for file I/O, `std/os/path` for paths
- Output dir: `target/` (following Cargo/Lisette convention)
- `hica build examples/hello.hc` → writes `target/main.kk`
- `hica run examples/hello.hc` → writes `target/main.kk`, then runs `koka -e target/main.kk`
- Short aliases follow Cargo convention: `b`=build, `r`=run, `c`=check, `t`=test
