---
layout: default
title: CLI Reference — hica
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
koka -ilib/klap -isrc src/main.kk -o hica
chmod +x hica

# Verify installation
./hica --version
```
