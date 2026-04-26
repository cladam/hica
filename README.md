# hica

**hica** is a high-performance, expression-oriented programming language built
in [Koka](https://koka-lang.github.io/) that transpiles to Koka. It blends
Rust-like syntax and safety with the simplicity of Go, powered by Koka's
algebraic effect system and Perceus reference counting. Because the target is
Koka itself, hica programs can be compiled onward to C, JavaScript, or WASM.

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
.hc source → Lex → Parse → Desugar → Type & Effect Inference → Emit Koka (.kk)
```

Each phase is implemented as a Koka module using algebraic effects for compiler
state (diagnostics, fresh names, symbol scopes).

## Technical Stack

| Component             | Approach                                        |
| --------------------- | ----------------------------------------------- |
| Implementation        | Koka 3.x                                        |
| Parsing               | Recursive descent with Pratt expression parsing |
| Type system           | System F + row polymorphism (algebraic effects)  |
| Memory management     | Perceus (inherited from Koka target)             |
| Backend target        | Koka (.kk) → C / JS / WASM via Koka              |
| Runtime               | Koka standard library and runtime                |

## Quick Start

Requires [Koka](https://koka-lang.github.io/koka/doc/book.html#install) ≥ 3.2.

```sh
# Build the compiler
koka -isrc src/main.kk -o hica
chmod +x hica

# Compile and run a Hica source file
./hica run examples/hello.hc

# Just compile (outputs to target/main.kk)
./hica build examples/arrow.hc

# Validate without emitting
./hica check examples/hello.hc
```

## CLI

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

## Inspirations

- [Lisette](https://lisette.run/) — Rust-inspired language that compiles to Go
- [Koka](https://koka-lang.github.io/) — language with algebraic effects and
  Perceus memory management
- C# — the `=>` operator and query expression syntax

## Licence

MIT — see [LICENSE](LICENSE).
