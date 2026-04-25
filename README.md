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

## Project Structure

```
src/
  main.kk              — compiler entry point
  syntax/
    ast.kk              — AST node definitions
    lexer.kk            — tokeniser
    parser.kk           — recursive descent parser
  semantics/
    checker.kk          — type and effect inference
  emit/
    codegen.kk          — Koka code generation
  diagnostics/
    diagnostics.kk      — error and warning reporting
tests/                  — test suite
docs/                   — design notes and references
```

## Quick Start

Requires [Koka](https://koka-lang.github.io/koka/doc/book.html#install) ≥ 3.2.

```sh
# Build the compiler
koka -isrc src/main.kk -o hica
chmod +x hica

# Run on a Hica source file
./hica examples/hello.hc
```

## Inspirations

- [Lisette](https://lisette.run/) — Rust-inspired language that compiles to Go
- [Koka](https://koka-lang.github.io/) — language with algebraic effects and
  Perceus memory management
- C# — the `=>` operator and query expression syntax

## Licence

MIT — see [LICENSE](LICENSE).
