---
layout: default
title: CLI Reference - hica
---

# CLI Reference

```
$ hica --help

Usage: hica [COMMAND] [FILE]
The hica compiler

Options:
      --help                 display this help and exit
      --version              output version information and exit

Commands:
    build, b    Compile a .hc file to Koka and build a binary
    run, r      Compile and run a .hc file
    check, c    Analyse a .hc file and report errors
    clean       Remove generated build artifacts
    test, t     Run tests in a .hc file
    new         Create a new hica project
    init        Initialise a project in the current directory
    help        Print this message

See 'hica help <command>' for more information on a specific command.
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

## Building from Source

Requires [Koka](https://koka-lang.github.io/koka/doc/book.html#install) ≥ 3.2.

```sh
# Clone and build
git clone https://github.com/cladam/hica.git
cd hica
koka -O2 -ilib/klap -isrc src/main.kk -o hica
chmod +x hica

# Verify installation
./hica --version
```
