---
layout: default
title: hica for Kids — hica
---

# hica for Kids: The Language with the Magic Arrow

Welcome to **hica**! hica is a programming language designed to be fast like a racing car but easy to read like a story. It's built using **Koka** and turns your code into **C** — the same language used to build the world's most powerful software.

## Why hica for Kids?

| Reason | What it means |
|--------|---------------|
| **Easy to read** | hica code looks almost like plain English |
| **No boilerplate** | No more `public static void main(String[] args)` — just `fun main()` |
| **Fast programs** | Your code becomes a real executable, not just a script |
| **Smart memory** | hica uses a trick called **Perceus** to clean up after itself — no garbage collector slowdowns |
| **Everything is an expression** | `if`, `match`, and blocks all give back values |
| **Learn real concepts** | The ideas you learn (functions, expressions, pattern matching) work in every language |

## Getting Started

1. Install [Koka](https://koka-lang.github.io/koka/doc/book.html#install) (version 3.2 or newer).
2. Build the compiler:

```sh
koka -ilib/klap -isrc src/main.kk -o hica
chmod +x hica
```

## Your First Program — Hello, World!

```rust
fun main() {
  println("Hello, world!")
}
```

Save that in a file called `hello.hc` and run it:

```sh
./hica run hello.hc
```

## Variables: Labelled Boxes

Imagine you have a box and you stick a label on it. That's what `let` does — it creates a named box and puts a value inside.

```rust
fun main() {
  let snack = "Apple";
  let count = 5;
  println(count)
}
```

You can tell the computer what type of value the box should hold:

```rust
let age: int = 11
let name: string = "Alice"
```

## Data Types: What Goes in the Box?

| Type | Example | What it is |
|------|---------|------------|
| `int` | `42`, `-7` | Whole numbers — like counting your toys |
| `float` | `3.14` | Numbers with decimal points |
| `string` | `"hello"` | Text — words, sentences, emoji |
| `char` | `'A'` | A single letter or symbol |
| `bool` | `true`, `false` | Like a light switch — on or off |

## Functions: Little Machines

A function is like a machine in a factory. You put something in, it does some work, and something comes out:

```rust
fun double(n) => n * 2
fun square(n) => n * n

fun main() {
  let a = double(3);
  let b = square(a);
  println(b)
}
```

## The Magic Arrow (`=>`)

When a function does just one thing, you can use the **hica Arrow**:

```rust
// With curly braces (block body)
fun double(n) {
  n * 2
}

// With the arrow (same thing, shorter!)
fun double(n) => n * 2
```

## Making Decisions

`if` expressions are like a fork in the road:

```rust
fun abs(x) => if x < 0 { -x } else { x }
```

## Pattern Matching: The Match Game

```rust
fun describe(x) => match x {
  0 => "zero",
  1 => "one",
  _ => "many"
}
```

## Lists: Collections of Things

```rust
fun main() {
  let fruits = ["apple", "banana", "cherry"];
  let nums = [1, 2, 3, 4, 5];
  println(fruits);
  println(nums)
}
```

## The Pipe: Connecting Machines

The pipe `|>` connects the output of one function to the input of the next — like an assembly line:

```rust
fun double(x) => x * 2
fun add_one(x) => x + 1

fun main() {
  let result = 5 |> double |> add_one;
  println(result)
}
```

## Maybe: Something or Nothing

```rust
fun main() {
  let treasure = Some("gold coin");
  let empty = None;

  match treasure {
    Some(item) => println("Found: " + item),
    None       => println("Nothing here")
  }
}
```

## Result: It Worked or It Didn't

```rust
fun safe_divide(a, b) =>
  if b == 0 { Err("can't divide by zero!") }
  else { Ok(a / b) }

fun main() {
  match safe_divide(10, 3) {
    Ok(n)  => println(n),
    Err(e) => println(e)
  }
}
```

## What's Next?

Work through the [Learn hica](/hica/docs/learn) lessons — 20 programs that teach you one idea at a time!
