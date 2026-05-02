---
layout: default
title: Language Reference - hica
---

# Language Reference

A comprehensive reference for hica's syntax and semantics.

## Functions

### Named functions

```rust
fun add(a, b) {
  a + b
}
```

### Expression-bodied functions (arrow syntax)

```rust
fun double(x) => x * 2
```

### Type annotations

```rust
fun add(a: int, b: int) : int => a + b
```

Type annotations are optional. Hindley-Milner inference handles most cases.

### Lambdas / closures

```rust
let sq = (n) => n * n;
let add = (a, b) => a + b;
```

Closures capture variables from their enclosing scope:

```rust
fun make_adder(n) => (x) => x + n

fun main() {
  let add5 = make_adder(5);
  println(add5(10))
}
```

## Variables

Variables are bound with `let` and are immutable:

```rust
let x = 42;
let name = "Alicia";
let pi = 3.14;
```

### The last-line rule

The last expression in a { } block is its return value. No need to write "return". Use println() to see output.

```rust
fun main() {
  let a = 10;
  let b = 20;
  let c = a + b;
  println(c)
}
```

## Control Flow

### If / else

`if`/`else` are expressions that return values:

```rust
let sign = if x < 0 { "negative" } else { "non-negative" };
```

### Else-if chains

```rust
fun fizzbuzz(n) =>
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
```

Works with `Maybe` and `Result` types:

```rust
match safe_divide(10, 3) {
  Ok(n)  => println(n),
  Err(e) => println(e)
}

match find_user(id) {
  Some(user) => println(user),
  None       => println("not found")
}
```

## Loops

### For-range loops

```rust
for i in 0..10 {
  println(i)
}
```

### For-in collection loops

```rust
let names = ["Kalle", "Lisa", "Olle"];
for name in names {
  println(name)
}
```

### Repeat

```rust
repeat(5) {
  println("hello")
}
```

## Data Types

### Primitives

| Type | Example | Description |
| ---- | ------- | ----------- |
| `int` | `42`, `-7` | Integer numbers |
| `float` | `3.14`, `-0.5` | Floating-point numbers |
| `string` | `"hello"` | Text strings |
| `char` | `'a'`, `'!'` | Single characters |
| `bool` | `true`, `false` | Boolean values |

### Strings

Concatenation with `+` and interpolation with `"{expr}"`:

```rust
let name = "world";
let greeting = "Hello, " + name;
let msg = "2 + 2 = {2 + 2}";
```

### Tuples

```rust
let pair = (1, "hello");
let x = pair.0;    // 1
let y = pair.1;    // "hello"

// Destructuring
let (a, b) = (10, 20);
```

### Lists

Homogeneous, immutable lists:

```rust
let nums = [1, 2, 3, 4, 5];
let empty = [];
let words = ["hello", "world"];
```

### Maybe

Optional values:

```rust
let x = Some(42);
let y = None;
```

### Result

Success or failure:

```rust
fun safe_divide(a, b) =>
  if b == 0 { Err("division by zero") }
  else { Ok(a / b) }
```

## Operators

### Arithmetic

| Operator | Description |
| -------- | ----------- |
| `+` | Addition |
| `-` | Subtraction |
| `*` | Multiplication |
| `/` | Division |
| `%` | Remainder |

### Comparison

| Operator | Description |
| -------- | ----------- |
| `==` | Equal |
| `!=` | Not equal |
| `<` | Less than |
| `>` | Greater than |
| `<=` | Less than or equal |
| `>=` | Greater than or equal |

### Logical

| Operator | Description |
| -------- | ----------- |
| `&&` | Logical AND |
| `\|\|` | Logical OR |

### Pipe

The pipe operator passes the left-hand value as the first argument to the right-hand function:

```rust
fun double(x) => x * 2
fun add_one(x) => x + 1

fun main() {
  let result = 5 |> double |> add_one;
  println(result)
}
```
