---
layout: default
title: CLI Reference - hica
---

# CLI Reference

```
$ hica --help

Usage: hica [OPTIONS] [COMMAND] [FILE]
The hica compiler

Options:
      --check            Check formatting without modifying the file
      --target=TARGET    Output target: koka (default) or js
      --help                 display this help and exit
      --version              output version information and exit

Commands:
  build, b               Compile a .hc file and build a binary
  run, r                 Compile and run a .hc file
  check, c               Analyse a .hc file and report errors
  fmt, f                 Format a .hc file
  clean                  Remove generated build artifacts
  test, t                Run tests in a .hc file
  new                    Create a new hica project
  init                   Initialise a hica project in the current directory
  repl                   Start an interactive REPL
  help                   Show help for a command
```

## Commands

### `hica run` (alias: `r`)

Compile and immediately run a `.hc` file:

```sh
hica run examples/hello.hc
```

### `hica build` (alias: `b`)

Compile a `.hc` file to Koka. Outputs a `.kk` file alongside the source:

```sh
hica build examples/arrow.hc
```

### `hica check` (alias: `c`)

Type-check a `.hc` file and report diagnostics without generating code:

```sh
hica check examples/hello.hc
```

### `hica clean`

Remove generated build artifacts:

```sh
hica clean
```

### `hica fmt` (alias: `f`)

Format a `.hc` file according to the [style guide](/hica/docs/style-guide):

```sh
hica fmt examples/hello.hc
```

Use `--check` to verify formatting without modifying the file. Returns exit code 1 if changes are needed (useful in CI):

```sh
hica fmt --check examples/hello.hc
```

**Formatting rules applied:**

- Remove trailing whitespace
- Space around operators (`+`, `*`, `/`, `%`, `=`, `==`, `!=`, `<=`, `>=`, `&&`, `||`, `|>`, `=>`)
- Collapse consecutive blank lines to one
- Remove spaces inside `()` and `[]`
- Remove space before function-call parentheses
- Space after commas (not before)
- Space after colon in type annotations (not before)
- Ensure trailing newline at end of file

### `hica test` (alias: `t`)

Run tests defined in a `.hc` file:

```sh
hica test examples/test-example.hc
```

Tests are written with `test` blocks and assertions:

```rust
fun double(n: int) : int => n * 2

test "double works" {
  assert(double(3) == 6)
  assert_eq(double(0), 0)
}
```

Output:

```
running 2 test(s)...

  ✓ double works
  ✓ basic math

2 test(s) passed
```

**Assertions:**

| Function | Description |
|----------|-------------|
| `assert(cond)` | Fails if `cond` is `false` |
| `assert_eq(expected, actual)` | Fails if values differ; shows both values |
| `assert_ne(a, b)` | Fails if values are equal |
| `assert_true(cond)` | Fails if `cond` is `false` (descriptive message) |
| `assert_false(cond)` | Fails if `cond` is `true` |
| `assert_contains(list, elem)` | Fails if list does not contain element |
| `assert_empty(list)` | Fails if list is not empty |
| `assert_not_empty(list)` | Fails if list is empty |

**Exit codes:** 0 if all tests pass, 1 if any test fails.

### `hica new`

Create a new hica project with a starter file structure:

```sh
hica new my-project
```

### `hica init`

Initialise a hica project in the current directory:

```sh
mkdir my-project && cd my-project
hica init
```

