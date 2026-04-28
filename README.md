# hica

**hica** is a high-performance, expression-oriented programming language built
in [Koka](https://koka-lang.github.io/) that transpiles to Koka. It blends
Rust-like syntax and safety with the simplicity of Go, powered by Koka's
algebraic effect system and Perceus reference counting. Because the target is
Koka itself, hica programs can be compiled onward to C, JavaScript, or WASM.

hica is a good name for this language and it can stand for **H**indley-milner **I**nference **C**ompiler with **A**lgebraic effects

## Design Goals

- **Expression-oriented** — everything returns a value: `if`, `match`, and
  blocks are all expressions.
- **Effect tracking** — side effects (I/O, state, exceptions) are first-class
  citizens, tracked by the type system.
- **No garbage collector** — memory safety via Koka's Perceus (Functional But
  In-Place) reference counting, inherited from the Koka target.
- **Strong inference** — Hindley-Milner type inference with row polymorphism;
  type annotations are rarely required.
- **Familiar syntax** — curly braces, `let`, `fun`, `match`, `if`, and the `=>`
  expression-bodied shorthand.

## Compilation Pipeline

```
.hc source → Lex → Parse → Type Check → Emit Koka (.kk) → Koka → C / JS / WASM
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

## Quick Start

Requires [Koka](https://koka-lang.github.io/koka/doc/book.html#install) ≥ 3.2.

```sh
# Build the compiler
koka -ilib/klap -isrc src/main.kk -o hica
chmod +x hica

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
  let result = double(21);
  result
}
```

### If / else-if chains

```rust
fun fizzbuzz(n) =>
  if n == 15 { "fizzbuzz" }
  else if n == 3 { "fizz" }
  else if n == 5 { "buzz" }
  else { "other" }
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
  let sq = (n) => n * n;
  apply(sq, 5)
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
    build, b    Compile a .hc file to Koka and build a binary
    run, r      Compile and run a .hc file
    check, c    Analyze a .hc file and report errors
    clean       Remove generated build artifacts
    help        Print this message

See 'hica help <command>' for more information on a specific command.
```

## Inspirations

- [Lisette](https://lisette.run/) — Rust-inspired language that compiles to Go
- [Koka](https://koka-lang.github.io/) — language with algebraic effects and
  Perceus memory management
- C# — the `=>` operator and query expression syntax

## Licence

MIT — see [LICENSE](LICENSE).
