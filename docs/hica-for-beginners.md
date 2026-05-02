---
layout: default
title: hica for Beginners — hica
---

# hica for Beginners

A practical introduction to hica for programmers new to the language. If you already know Python, JavaScript, or Rust, you'll feel at home quickly.

## What is hica?

hica is a statically typed, expression-oriented language. The compiler is built in [Koka](https://koka-lang.github.io) and emits Koka code, which compiles to C, giving you native performance with minimal boilerplate.

| Feature | Details |
|---------|---------|
| **Type inference** | Hindley-Milner — types are inferred, annotations optional |
| **Expression-oriented** | `if`, `match`, and blocks all return values |
| **Compiled** | `.hc` → Koka → C → native executable |
| **Memory management** | Perceus reference counting — no GC pauses |
| **Functional core** | First-class functions, closures, pipe operator |

## Setup

1. Install [Koka](https://koka-lang.github.io/koka/doc/book.html#install) (version 3.2 or newer).
2. Build the compiler:

```sh
koka -ilib/klap -isrc src/main.kk -o hica
chmod +x hica
```

3. Run a program:

```sh
./hica run hello.hc
```

## Hello, World

```rust
fun main() {
  println("Hello, world!")
}
```

Every hica program starts at `fun main()`. The last expression in a block is its return value — no `return` keyword needed.

## Variables

Variables are immutable bindings created with `let`:

```rust
fun main() {
  let name = "Alicia";
  let age = 30;
  let pi = 3.14;
  println("name={name}, age={age}, pi={pi}")
}
```

### Optional type annotations

Type annotations use `: type` after the name. They're optional — the compiler infers types — but useful for documentation:

```rust
let count: int = 42
let label: string = "total"
let ratio: float = 0.75
```

## Data Types

| Type | Example | Description |
|------|---------|-------------|
| `int` | `42`, `-7` | Integer numbers |
| `float` | `3.14`, `-0.5` | Floating-point numbers |
| `string` | `"hello"` | Text strings (interpolation with `"{expr}"`) |
| `char` | `'A'`, `'!'` | Single characters |
| `bool` | `true`, `false` | Boolean values |

## Functions

### Named functions

```rust
fun add(a, b) {
  a + b
}
```

### Arrow syntax

When the body is a single expression, use `=>`:

```rust
fun double(x) => x * 2
fun square(x) => x * n
fun greet(name) => "Hello, " + name
```

### With type annotations

```rust
fun add(a: int, b: int) : int => a + b
fun is_even(n: int) : bool => n % 2 == 0
```

### Lambdas and closures

```rust
let sq = (n) => n * n;
let add = (a, b) => a + b;
```

Closures capture variables from their enclosing scope:

```rust
fun make_adder(n) => (x) => x + n

fun main() {
  let add5 = make_adder(5);
  println(add5(10));
  println(add5(20))
}
```

## Control Flow

### If / else

`if`/`else` are expressions — they return values:

```rust
fun abs(x) => if x < 0 { -x } else { x }

fun main() {
  let sign = if 42 > 0 { "positive" } else { "non-positive" };
  println(sign)
}
```

### Else-if chains

```rust
fun classify(n) =>
  if n % 15 == 0 { "fizzbuzz" }
  else if n % 3 == 0 { "fizz" }
  else if n % 5 == 0 { "buzz" }
  else { "{n}" }
```

### Match expressions

Pattern matching with integer, string, and wildcard patterns:

```rust
fun describe(x) => match x {
  0 => "zero",
  1 => "one",
  _ => "many"
}

fun main() {
  println(describe(0));
  println(describe(1));
  println(describe(99))
}
```

## Loops

### For-range

```rust
fun main() {
  for i in 0..5 {
    println(i)
  }
}
```

### For-in (collection)

```rust
fun main() {
  let names = ["Alicia", "Kalle", "Olle"];
  for name in names {
    println("Hello, " + name)
  }
}
```

### Repeat

```rust
fun main() {
  repeat(3) {
    println("tick")
  }
}
```

## Collections

### Lists

Homogeneous, immutable lists with standard library operations:

```rust
fun main() {
  let nums = [1, 2, 3, 4, 5];

  let doubled = map(nums, (x) => x * 2);
  println(doubled);

  let evens = filter(nums, (x) => x % 2 == 0);
  println(evens);

  let total = fold(nums, 0, (acc, x) => acc + x);
  println(total)
}
```

### Tuples

Fixed-size, heterogeneous containers:

```rust
fun main() {
  let pair = (1, "hello");
  println(pair.0);
  println(pair.1);

  let (a, b) = (10, 20);
  println(a + b)
}
```

## The Pipe Operator

The pipe `|>` passes the left-hand value as the first argument to the right-hand function. It lets you write data transformations as a readable pipeline:

```rust
fun double(x) => x * 2
fun add_one(x) => x + 1

fun main() {
  let result = 5 |> double |> add_one;
  println(result)
}
```

Pipes work well with the standard library:

```rust
fun main() {
  let result = [1, 2, 3, 4, 5]
    |> filter((x) => x % 2 == 0)
    |> map((x) => x * 10)
    |> fold(0, (acc, x) => acc + x);
  println(result)
}
```

## Error Handling

### Maybe — optional values

Use `Some` and `None` to represent values that might not exist:

```rust
fun find_first_even(xs) =>
  match filter(xs, (x) => x % 2 == 0) {
    Cons(h, _) => Some(h),
    Nil        => None
  }

fun main() {
  match find_first_even([1, 3, 4, 7]) {
    Some(n) => println("Found: {n}"),
    None    => println("No even number")
  }
}
```

### Result — success or failure

Use `Ok` and `Err` for operations that can fail:

```rust
fun safe_divide(a, b) =>
  if b == 0 { Err("division by zero") }
  else { Ok(a / b) }

fun main() {
  match safe_divide(10, 3) {
    Ok(n)  => println("Result: {n}"),
    Err(e) => println("Error: " + e)
  }
}
```

## Strings

Concatenation with `+` and interpolation with `{expr}` inside double-quoted strings:

```rust
fun main() {
  let name = "world";
  let greeting = "Hello, " + name;
  let math = "2 + 2 = {2 + 2}";
  println(greeting);
  println(math)
}
```

## Putting It Together

A slightly larger example combining several features:

```rust
fun fizzbuzz(n) =>
  if n % 15 == 0 { "fizzbuzz" }
  else if n % 3 == 0 { "fizz" }
  else if n % 5 == 0 { "buzz" }
  else { "{n}" }

fun main() {
  for i in 1..21 {
    println(fizzbuzz(i))
  }
}
```

## What's Next?

- Work through the [Learn hica](/hica/docs/learn) lessons — 20 programs that teach you one concept at a time
- Browse the [Language Reference](/hica/docs/language-reference) for full syntax details
- Check the [Standard Library](/hica/docs/standard-library) for available functions
