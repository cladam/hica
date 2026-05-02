---
layout: default
title: Quick Start — hica
---

# Quick Start

Get up and running with hica in a few minutes.

## Prerequisites

Install [Koka](https://koka-lang.github.io/koka/doc/book.html#install) version 3.2 or newer.

## Build the Compiler

```sh
git clone https://github.com/cladam/hica.git
cd hica

# Build the hica compiler
koka -ilib/klap -isrc src/main.kk -o hica
chmod +x hica
```

## Run Your First Program

Create a file called `hello.hc`:

```rust
fun main() {
  println("Hello, world!")
}
```

Then compile and run it:

```sh
./hica run hello.hc
```

Output:

```
Hello, world!
```

## CLI Commands

| Command | Description |
| ------- | ----------- |
| `hica run <file>` | Compile and run a `.hc` file |
| `hica build <file>` | Compile a `.hc` file to Koka |
| `hica check <file>` | Type-check without emitting code |
| `hica clean` | Remove generated build artifacts |
| `hica new <name>` | Create a new hica project |
| `hica init` | Initialise a project in the current directory |

Short aliases work too: `hica r`, `hica b`, `hica c`.

## Try the Examples

The repo ships with ready-to-run examples:

```sh
./hica run examples/hello.hc
./hica run examples/fizzbuzz.hc
./hica run examples/pipe.hc
./hica run examples/match.hc
./hica run examples/closures.hc
```

## Next Steps

- [Learn hica](/hica/docs/learn) — 20 progressive lessons
- [Language Reference](/hica/docs/language-reference) — full syntax guide
- [Standard Library](/hica/docs/standard-library) — built-in functions
