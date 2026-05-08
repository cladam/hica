---
layout: default
title: Quick Start - hica
---

# Quick Start

Get hica running and compile your first program in a few minutes.

## Prerequisites

Install [Koka](https://koka-lang.github.io/koka/doc/book.html#install) version 3.2 or newer.

## Install hica

### Build from source

```sh
git clone https://github.com/cladam/hica.git
cd hica

# Build the hica compiler
## -i includes klap library and src directory
koka -O2 -ilib/klap -isrc src/main.kk -o hica
## make hica executable
chmod +x hica

# Verify hica by checking the version
./hica --version
```

## Run Your First Programs

Create `hello.hc`:

```rust
fun main() {
  println("Hello, world!")
}
```

Then build and run it:

```sh
./hica run hello.hc
```

Output:

```
Hello, world!
```

`run` transpiles the file to Koka, compiles it, and executes the result.

## CLI Commands

| Command | Description |
| ------- | ----------- |
| `hica run <file>` | Compile and run a `.hc` file |
| `hica build <file>` | Compile a `.hc` file and build a binary |
| `hica check <file>` | Analyse a `.hc` file and report errors |
| `hica clean` | Remove generated build artifacts |
| `hica new <name>` | Create a new hica project |
| `hica init` | Initialise a project in the current directory |
| `hica help <command> | Show help for a command |

Short aliases work too: `hica r`, `hica b`, `hica c`.

## Try the Examples

The repo ships with ready-to-run [examples](https://github.com/cladam/hica/tree/main/examples):

```sh
./hica run examples/hello.hc
./hica run examples/fizzbuzz.hc
./hica run examples/pipe.hc
./hica run examples/match.hc
./hica run examples/closures.hc
```

## Next Steps

- **[Learn hica](/hica/docs/learn)**: 29 standalone programs, each teaching one concept. Run them, modify them, break them.
- **[Language Reference](/hica/docs/language-reference)**: every syntax detail, for when you need the precise rules.
- **[Standard Library](/hica/docs/standard-library)**: all built-in functions covering strings, lists, math, and more.
