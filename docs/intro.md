---
layout: default
title: Introduction — hica
---

# Introduction

**hica** is a high-performance, expression-oriented programming language built in [Koka](https://koka-lang.github.io/) that also transpiles to Koka. It blends Rust-like syntax and safety with a pragmatic, approachable design, powered by Koka's algebraic effect system and Perceus reference counting.

> **hica** stands for **H**indley-milner **I**nference **C**ompiler with **A**lgebraic effects

## Why hica?

Most programming languages force you to choose: easy to learn **or** safe and fast. hica gives you both.

- **Familiar syntax**: if you've seen Rust, TypeScript, or C#, hica feels natural. Curly braces, `let`, `fun`, `match`, `if`, and the `=>` expression-bodied shorthand.
- **Everything is an expression**: `if`, `match`, and blocks all return values. No surprise `void` returns.
- **Compile-time safety**: Hindley-Milner type inference catches bugs before your program runs, without requiring type annotations everywhere.
- **No garbage collector**: memory safety via Koka's Perceus (Functional But In-Place) reference counting.
- **Effect tracking**: side effects (I/O, state, exceptions) are first-class citizens, tracked by the type system.

## How It Works

hica compiles through a multi-stage pipeline:

```
.hc source → Lex → Parse → Type Check → Emit Koka (.kk) → Koka → C / JS / WASM
```

Each phase is implemented as a Koka module using algebraic effects for compiler state; diagnostics, fresh type variables, and symbol scopes.

Because the final target is Koka, hica programs inherit the full Koka runtime: its standard library, Perceus memory management, and the ability to compile to C (native), JavaScript (browser/Node), or WASM.

## What You Get for Free

By targeting Koka, hica doesn't need to reinvent:

- Memory management (Perceus reference counting)
- Backend codegen (C, JS, WASM — all handled by Koka)
- Standard library (strings, lists, I/O, concurrency)
- Optimisation passes (tail-call, FBIP in-place reuse)
- Platform support and ABI concerns
- Effect runtime (handlers, resumptions)

## A Quick Example

```rust
fun fizzbuzz(n) =>
  if n % 15 == 0 { "fizzbuzz" }
  else if n % 3 == 0 { "fizz" }
  else if n % 5 == 0 { "buzz" }
  else { "{n}" }

fun main() {
  for i in 0..20 {
    println(fizzbuzz(i + 1))
  }
}
```

## Inspirations

- [Koka](https://koka-lang.github.io/) — language with algebraic effects and Perceus memory management
- [Lisette](https://lisette.run/) — Rust-inspired language that compiles to Go
- C# — the `=>` operator and query expression syntax
- Python — easy and powerful lists

## Next Steps

- [Quick Start](/hica/docs/quick-start) — install and run your first program
- [Learn hica](/hica/docs/learn) — 20 progressive lessons, one concept at a time
- [Language Reference](/hica/docs/language-reference) — the full syntax and semantics
