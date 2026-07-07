<div align="center">
  <img src="assets/hica-logo2.png" width="200" alt="hica logo" />
  <p><b>A safe, expression-oriented language with algebraic effects and familiar syntax.</b></p>
  
</div>

**hica** is a safe, expression-oriented language with a functional style and familiar syntax.

Features include:

- Hindley-Milner type inference
- Algebraic effects
- Expression-oriented design
- No nulls or unchecked exceptions
- Compilation to C, JavaScript, and WASM

Under the hood, hica is implemented in [Koka](https://koka-lang.github.io/) and inherits Koka's algebraic effect system and Perceus memory management.

hica stands for **H**indley-Milner **I**nference **C**ompiler with **A**lgebraic effects.

Visit hica's [website](https://www.hica.dev/) for a tour of the language.

## Design Goals

- **Safe by default** – no null, no unhandled exceptions; errors are values (`Result`, `Maybe`).
- **Expression-oriented** – everything returns a value: `if`, `match`, and blocks are all expressions.
- **Functional-first** – immutability by default, higher-order functions, and pattern matching at the core.
- **Minimal ceremony** – Hindley-Milner type inference means you rarely write annotations; the language gets out of your way.
- **Effect tracking** – side effects (I/O, state, exceptions) are tracked by the type system, not buried in function bodies.
- **Predictable memory management** – inherited from Koka's Perceus reference counting; no GC pauses, no manual allocation.
- **Familiar syntax** – curly braces, `let`, `fun`, `match`, `if`, and the `=>` expression-bodied shorthand.

## Built with hica

[**tbdflow-ui**](https://github.com/cladam/tbdflow-ui) — a desktop dashboard for [tbdflow](https://github.com/cladam/tbdflow), a Trunk-Based Development CLI with thousands of downloads and a [listing on trunkbaseddevelopment.com](https://trunkbaseddevelopment.com/committing-straight-to-the-trunk/#tooling-support). The UI is a multi-panel ImGui app written entirely in hica.

[**HML**](https://github.com/cladam/hml) — Hica Markup Language, a structured document and configuration format. The parser and API library are written in hica and published as a reusable package. Demonstrates multi-file libraries, recursive data types, and pattern matching on tree-shaped data.

[**yml2hml**](https://www.hica.dev/docs/yml2hml/) — a standalone CLI tool that converts YAML files to HML format. A practical example of real-world parsing, recursive data structures, and formatted output.

## Concurrency

hica currently targets scripting, tooling, and single-threaded programs. OS threads and async I/O are not in scope yet.

That said, Koka's algebraic effect system provides the right primitives for structured concurrency. Named effect handlers can express cooperative patterns (coroutines, generators, and actor-like message passing) without needing language-level async/await. The [`counter-actor` example](examples/counter-actor.hc) demonstrates the actor pattern today. Structured concurrency via named handlers is the direction the runtime is heading.

For I/O-bound parallelism in the meantime, `exec()` and `exec_args()` let you shell out to external processes.

## Install

**Linux / macOS / Chromebook:**

```sh
curl -fsSL https://www.hica.dev/install.sh | sh
```

This installs the latest release binary to `~/.local/bin`. Override with `HICA_INSTALL_DIR`:

```sh
curl -fsSL https://www.hica.dev/install.sh | HICA_INSTALL_DIR=/usr/local/bin sh
```

**Windows (PowerShell):**

```powershell
irm https://www.hica.dev/install.ps1 | iex
```

### Build from source

Requires [Koka](https://koka-lang.github.io/koka/doc/book.html#install) ≥ 3.2.

```sh
git clone --recurse-submodules https://github.com/cladam/hica.git
cd hica
make release
```

> **Already cloned without `--recurse-submodules`?**
> Run `git submodule update --init --recursive` inside the repo before building.

## Why hica?

hica aims to combine:

- the readability of Python,
- the safety mindset of Rust,
- the ergonomics of F#,
- and the algebraic effects of Koka,

while keeping a familiar curly-brace syntax.

## Quick Start

Create a file `hello.hc`:

```rust
fun main() {
  println("Hello, world")
}
```

Then run it:

```sh
hica run hello.hc
```

Other common commands:

```sh
# Compile to a binary
hica build hello.hc -o hello

# Type-check without emitting
hica check hello.hc

# Format source
hica fmt hello.hc
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

### FizzBuzz

```rust
fun fizzbuzz(n) =>
  if n % 15 == 0 { "fizzbuzz" }
  else if n % 3 == 0 { "fizz" }
  else if n % 5 == 0 { "buzz" }
  else { show(n) }
```

## CLI

| Command  | Description                          |
| -------- | ------------------------------------ |
| `build`  | Compile a file to a binary           |
| `run`    | Compile and run a file               |
| `check`  | Type-check source without emitting   |
| `fmt`    | Format source                        |
| `test`   | Run tests in a file                  |
| `new`    | Create a new project                 |
| `repl`   | Start an interactive shell           |

Run `hica help <command>` for details on any command.

## Inspirations

- [Koka](https://koka-lang.github.io/) – language with algebraic effects and
  Perceus memory management
- [Rust](https://www.rust-lang.org/) – syntax, safety mindset, and the `match` expression
- [F#](https://fsharp.org/) – functional-first style, pipelines, and type inference ergonomics
- [C#](https://learn.microsoft.com/en-us/dotnet/csharp/) – the `=>` expression-bodied shorthand and query syntax
- [Python](https://www.python.org/) – approachable, expressive lists and comprehensions

## Status

hica is under active development and moving fast — new features land regularly and contributions are welcome.

The language is usable today for experimentation and personal projects.

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

## Licence

Apache License 2.0 – see [LICENSE](LICENSE).
