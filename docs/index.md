---
layout: default
title: hica — A Modern Systems Language
---

# What is hica?

**hica** is a high-performance, expression-oriented programming language built in [Koka](https://koka-lang.github.io/) that also transpiles to Koka. It blends Rust-like syntax and safety with a pragmatic, approachable design, powered by Koka's algebraic effect system and Perceus reference counting.

Because the target is Koka itself, hica programs can be compiled onward to **C**, **JavaScript**, or **WASM**.

> **hica** — **H**indley-milner **I**nference **C**ompiler with **A**lgebraic effects

## Design Goals

- **Expression-oriented** — everything returns a value: `if`, `match`, and blocks are all expressions.
- **Effect tracking** — side effects (I/O, state, exceptions) are first-class citizens, tracked by the type system.
- **No garbage collector** — memory safety via Koka's Perceus reference counting, inherited from the Koka target.
- **Strong inference** — Hindley-Milner type inference with row polymorphism; type annotations are rarely required but fully supported.
- **Familiar syntax** — curly braces, `let`, `fun`, `match`, `if`, and the `=>` expression-bodied shorthand.

## A Quick Taste

```rust
fun fizzbuzz(n) =>
  if n % 15 == 0 { "fizzbuzz" }
  else if n % 3 == 0 { "fizz" }
  else if n % 5 == 0 { "buzz" }
  else { show(n) }

fun main() {
  for i in 0..20 {
    println(fizzbuzz(i + 1))
  }
}
```

## Compilation Pipeline

```
.hc source → Lex → Parse → Type Check → Emit Koka (.kk) → Koka → C / JS / WASM
```

Each phase is implemented as a Koka module using algebraic effects for compiler state (diagnostics, fresh type variables, symbol scopes).

## Technical Stack

| Component             | Approach                                        |
| --------------------- | ----------------------------------------------- |
| Implementation        | Koka 3.x                                        |
| Parsing               | Recursive descent with Pratt expression parsing |
| Type system           | Hindley-Milner with unification                 |
| Name resolution       | Declaration-aware marshalling (`hc_` prefix)    |
| CLI argument parsing  | klap (clap-inspired, in-tree)                   |
| Memory management     | Perceus (inherited from Koka target)            |
| Backend target        | Koka (.kk) → C / JS / WASM via Koka            |

Ready to get started? Check the [Quick Start](/hica/docs/quick-start) guide, or dive into [Learn hica](/hica/docs/learn) for a step-by-step tutorial.
