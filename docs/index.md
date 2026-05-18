---
layout: default
title: Introduction - hica
---

# Introduction

**hica** is an expression-oriented programming language designed to feel approachable without giving up type safety or performance.

It is implemented in [Koka](https://koka-lang.github.io/) and inherits Koka’s algebraic effect system and Perceus memory management.

## Why hica?

Most programming languages force you to choose: easy to learn **or** safe and fast. hica shifts the trade-off boundary—global type inference gives you the low-friction syntax of a dynamic language, while the Koka backend compiles to native C11 for systems-level performance.

- **Familiar syntax**: if you've seen Rust, TypeScript, or C#, hica feels natural. Curly braces, `let`, `fun`, `match`, `if`, and the `=>` expression-bodied shorthand.
- **Everything is an expression**: `if`, `match`, and blocks compose naturally because they return values.
- **Compile-time safety**: Strong static typing without pervasive annotations.
- **No tracing garbage collector**: deterministic compile-time memory management via Koka's Perceus engine. Because hica structures are immutable, there are no reference cycles; Perceus optimises reference counts at compile time, turning functional copies into in-place mutations when a value is uniquely owned.
- **Effect tracking**: side effects (I/O, state, exceptions) are first-class citizens, tracked by the type system.

> **hica** stands for **H**indley-milner **I**nference **C**ompiler with **A**lgebraic effects

## How It Works

hica compiles through a multi-stage pipeline:

```
.hc source → Lex → Parse → Desugar → Type Check → Emit Koka (.kk) → Koka Compiler → C/JS/WASM
```

The compiler itself is written in Koka and uses algebraic effects to manage compiler state and diagnostics.

Because the final target is Koka, hica programs inherit the full Koka runtime: its standard library, Perceus memory management, and the ability to compile to C (native), JavaScript (browser/Node), or WASM.

## What You Get for Free

By targeting Koka, hica doesn't need to reinvent:

- Memory management (Perceus reference counting)
- Backend codegen (C, JS, WASM, all handled by Koka)
- Standard library (strings, lists, I/O, concurrency)
- Optimisation passes(including in-place reuse optimisations)
- Platform support and ABI concerns
- Effect runtime (handlers, resumptions)

## A Quick Example

```rust
// filter keeps matching elements, map transforms each, fold reduces to a single value
fun main() {
  let nums = [1, 2, 3, 4, 5]
    |> filter((x) => x % 2 == 0)
    |> map((x) => x * 10)
    |> fold(0, (sum, x) => sum + x)

  println(nums)
}
```

## Technical Stack

| Component             | Approach                                        |
| --------------------- | ----------------------------------------------- |
| Implementation        | Koka 3.x                                        |
| Parsing               | Recursive descent with Pratt expression parsing |
| Type system           | Hindley-Milner with unification                 |
| Name resolution       | Declaration-aware marshalling (`hc_` prefix)    |
| CLI argument parsing  | klap (clap-inspired, in-tree)                   |
| Memory management     | Perceus (inherited from Koka target)            |
| Backend target        | Koka (.kk) -> C / JS / WASM via Koka            |

## Inspirations

- [Koka](https://koka-lang.github.io/) - language with algebraic effects and Perceus memory management
- [Lisette](https://lisette.run/) - Rust-inspired language that compiles to Go
- C# - the `=>` operator and query expression syntax
- Python - easy and powerful lists

## Next Steps

- **[Learn hica](/hica/docs/learn)**: 40 standalone programs, each teaching one concept. Run them, modify them, break them.
- **[Language Reference](/hica/docs/language-reference)**: every syntax detail, for when you need the precise rules.
- **[Standard Library](/hica/docs/standard-library)**: all built-in functions covering strings, lists, math, and more.
