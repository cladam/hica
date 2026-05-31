---
layout: default
title: hica — A safe, expression-oriented language
---

# What is hica?

**hica** is a safe, expression-oriented, functional-flavored language with a gentle learning curve. It is built in [Koka](https://koka-lang.github.io/) and transpiles to Koka, powered by Koka's algebraic effect system and Perceus reference counting.

Because the target is Koka itself, hica programs can be compiled onward to **C**, **JavaScript**, or **WASM**.

> **hica** — **H**indley-milner **I**nference **C**ompiler with **A**lgebraic effects

## Design Goals

- **Safe by default** — no null, no unhandled exceptions; errors are values (`Result`, `Maybe`).
- **Expression-oriented** — everything returns a value: `if`, `match`, and blocks are all expressions.
- **Functional-flavored** — immutability by default, higher-order functions, and pattern matching at the core.
- **Gentle learning curve** — Hindley-Milner type inference means you rarely write annotations; the language gets out of your way.
- **Effect tracking** — side effects (I/O, state, exceptions) are tracked by the type system, not buried in function bodies.
- **No garbage collector** — memory safety via Koka's Perceus reference counting, with no GC pauses.
- **Familiar syntax** — curly braces, `let`, `fun`, `match`, `if`, and the `=>` expression-bodied shorthand.

## A Quick Taste

```hica
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
