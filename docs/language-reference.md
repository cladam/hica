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
let sq = (n) => n * n
let add = (a, b) => a + b
```

Closures capture variables from their enclosing scope:

```rust
fun make_adder(n) => (x) => x + n

fun main() {
  let add5 = make_adder(5)
  println(add5(10))
}
```

## Variables

Variables are bound with `let` and are immutable:

```rust
let x = 42
let name = "Alicia"
let pi = 3.14
```

### The last-line rule

The last expression in a { } block is its return value. No need to write "return". Use println() to see output.

```rust
fun main() {
  let a = 10
  let b = 20
  let c = a + b
  println(c)
}
```

## Control Flow

### If / else

`if`/`else` are expressions that return values:

```rust
let sign = if x < 0 { "negative" } else { "non-negative" }
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

Match guards add conditions to patterns with `if`:

```rust
fun classify(n) => match n {
  x if x < 0   => "negative",
  0             => "zero",
  x if x > 100 => "big",
  _             => "small positive"
}
```

Guards work with all pattern types, including constructors:

```rust
match parse_int(input) {
  Some(n) if n < 0 => "negative",
  Some(n)          => "valid: {n}",
  None             => "not a number"
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

Tuple destructuring patterns:

```rust
fun describe(point) => match point {
  (0, 0) => "origin",
  (x, 0) => "on x-axis at {x}",
  (0, y) => "on y-axis at {y}",
  (x, y) => "({x}, {y})"
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
let names = ["Kalle", "Lisa", "Olle"]
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
let name = "world"
let greeting = "Hello, " + name
let msg = "2 + 2 = {2 + 2}"
```

Strings support `<`, `>`, `<=`, `>=` for lexicographic comparison:

```rust
println("apple" < "banana")    // true
println("abc" <= "abc")        // true
```

String utility functions are built in using hica's prelude library:

```rust
fun main() {
  let s = "  Hello, World!  "
  println(str_length(s))
  println(trim(s))
  println(to_upper(trim(s)))
  println(contains(s, "World"))
  println(starts_with(trim(s), "Hello"))
  println(split("a,b,c", ","))
  println(join(["a", "b", "c"], "-"))
  println(replace("hello", "l", "r"))
  println(index_of("hello-world", "-"))
  println(to_int("42"))
  println(parse_int("42"))
  println(parse_float("3.14"))
}
```

See the [Standard Library](standard-library.md) for the full list.

### Tuples

```rust
let pair = (1, "hello")
let x = pair.0    // 1
let y = pair.1    // "hello"

// Destructuring
let (a, b) = (10, 20)
```

### Structs

Named records with typed fields:

```rust
struct Point { x: int, y: int }

fun main() {
  let p = Point { x: 3, y: 4 }
  println(p.x)     // 3
  println(p.y)     // 4
  println(p)        // Point(x: 3, y: 4)
}
```

Structs work as function parameters and return types:

```rust
struct Point { x: int, y: int }

fun distance_sq(p: Point) : int => p.x * p.x + p.y * p.y

fun origin() : Point => Point { x: 0, y: 0 }
```

Struct names must start with an uppercase letter. Fields are accessed with dot notation.

### Lists

Homogeneous, immutable lists:

```rust
let nums = [1, 2, 3, 4, 5]
let empty = []
let words = ["hello", "world"]
```

### Maybe

Optional values:

```rust
let x = Some(42)
let y = None
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

Comparison operators work on `int`, `float`, and `string` (lexicographic ordering).

### Logical

| Operator | Description |
| -------- | ----------- |
| `&&` | Logical AND |
| `||` | Logical OR |

### Pipe

The pipe operator passes the left-hand value as the first argument to the right-hand function:

```rust
fun double(x) => x * 2
fun add_one(x) => x + 1

fun main() {
  let result = 5 |> double |> add_one
  println(result)
}
```
