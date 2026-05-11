<div align="center">
  <img src="assets/hica-logo.png" width="200" alt="hica logo" />
  <p><b>A modern, expressive and fast systems language</b></p>
  
</div>

**hica** is a high-performance, expression-oriented programming language built
in [Koka](https://koka-lang.github.io/) that also transpiles to Koka. It blends
Rust-like syntax and safety with a pragmatic, approachable design, powered by
Koka's algebraic effect system and Perceus reference counting. Because the target
is Koka itself, hica programs can be compiled onward to C, JavaScript, or WASM.

hica is a good name for this language and it can stand for **H**indley-milner **I**nference **C**ompiler with **A**lgebraic effects

Visit hica's [website](https://cladam.github.io/hica/) for a tour of the language.

## Design Goals

- **Expression-oriented** — everything returns a value: `if`, `match`, and
  blocks are all expressions.
- **Effect tracking** — side effects (I/O, state, exceptions) are first-class
  citizens, tracked by the type system.
- **No garbage collector** — memory safety via Koka's Perceus (Functional But
  In-Place) reference counting, inherited from the Koka target.
- **Strong inference** — Hindley-Milner type inference with row polymorphism;
  type annotations are rarely required but fully supported.
- **Familiar syntax** — curly braces, `let`, `fun`, `match`, `if`, and the `=>`
  expression-bodied shorthand.

## Compilation Pipeline

```
.hc source → Lex → Parse → Desugar → Type Check → Emit Koka (.kk) → Koka Compiler → C/JS/WASM
```

Each phase is implemented as a Koka module using algebraic effects for compiler
state (diagnostics, fresh type variables, symbol scopes).

## Technical Stack

| Component             | Approach                                        |
| --------------------- | ----------------------------------------------- |
| Implementation        | Koka 3.x                                        |
| Parsing               | Recursive descent with Pratt expression parsing |
| Type system           | Hindley-Milner with unification                  |
| Name resolution       | Declaration-aware marshalling (`hc_` prefix)     |
| CLI argument parsing  | klap (clap-inspired, in-tree)                    |
| Memory management     | Perceus (inherited from Koka target)             |
| Backend target        | Koka (.kk) → C / JS / WASM via Koka              |
| Runtime               | Koka standard library and runtime                |

## Install

```sh
curl -fsSL https://cladam.github.io/hica/install.sh | sh
```

This installs the latest release binary to `~/.local/bin`. Override with `HICA_INSTALL_DIR`:

```sh
curl -fsSL https://cladam.github.io/hica/install.sh | HICA_INSTALL_DIR=/usr/local/bin sh
```

### Build from source

Requires [Koka](https://koka-lang.github.io/koka/doc/book.html#install) ≥ 3.2.

```sh
git clone https://github.com/cladam/hica.git
cd hica
koka -O2 -ilib/klap -isrc src/main.kk -o hica
chmod +x hica
```

## Quick Start

```sh
# Compile and run a Hica source file
./hica run examples/hello.hc

# Just compile (outputs .kk alongside source)
./hica build examples/arrow.hc

# Type-check without emitting
./hica check examples/hello.hc
```

## Examples

### Expression-bodied functions

```rust
fun double(x) => x * 2

fun main() {
  let result = double(21)
  result
}
```

### If / else-if chains

```rust
fun fizzbuzz(n) =>
  if n % 15 == 0 { "fizzbuzz" }
  else if n % 3 == 0 { "fizz" }
  else if n % 5 == 0 { "buzz" }
  else { show(n) }
```

### Match expressions

```rust
fun describe(x) => match x {
  0 => "zero",
  1 => "one",
  _ => "many"
}
```

### Lambdas

```rust
fun apply(f, x) => f(x)

fun main() {
  let sq = (n) => n * n
  apply(sq, 5)
}
```

### Type annotations

```rust
fun add(a: int, b: int) : int => a + b

fun main() {
  let x: int = 42
  println(add(x, 8))
}
```

### Maybe and Result types

```rust
fun safe_divide(a, b) =>
  if b == 0 { Err("division by zero") }
  else { Ok(a / b) }

fun main() {
  match safe_divide(10, 3) {
    Ok(n)  => println(n),
    Err(e) => println(e)
  }
}
```

## CLI

```
$ hica --help

Usage: hica [COMMAND] [FILE]
The hica compiler

Options:
      --help                 display this help and exit
      --version              output version information and exit

Commands:
  build, b               Compile a .hc file and build a binary
  run, r                 Compile and run a .hc file
  check, c               Analyse a .hc file and report errors
  clean                  Remove generated build artifacts
  test, t                Run tests in a .hc file
  new                    Create a new hica project
  init                   Initialise a hica project in the current directory
  help                   Show help for a command
```

## Inspirations

- [Lisette](https://lisette.run/) — Rust-inspired language that compiles to Go
- [Koka](https://koka-lang.github.io/) — language with algebraic effects and
  Perceus memory management
- C# — the `=>` operator and query expression syntax
- Python – easy and powerful lists

## Licence

Apache License 2.0 — see [LICENSE](LICENSE).
