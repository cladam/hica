---
layout: default
title: Hica vs. Rust - hica
---

# Hica vs Rust

hica and Rust share values like immutability, expression-oriented design, `match` as a core feature, and `Result`/`Option` types. They diverge in how much complexity they expose to achieve control and performance.

## At a Glance

| Dimension | Rust | hica |
|-----------|------|------|
| Type system | Ownership + lifetimes + traits | Hindley-Milner inference (little to no annotations in practice) |
| Memory model | Borrow checker, zero-cost abstractions | Automatic reference counting with compile-time optimisation (Koka/Perceus) |
| Mutability | Immutable by default, `mut` opt-in | Immutable, no `mut` |
| Error handling | `Result<T, E>` + `?` operator | `Result` + `match` + combinators (`map_result`, `and_then_result`) |
| Closures | `Fn` / `FnMut` / `FnOnce` traits | Single closure type, always captured |
| Pattern matching | Exhaustive, deeply nested | Common cases (primitives + Maybe/Result + ranges), not deeply nested |
| Custom types | `struct` + `enum` + `impl` + `derive` | `struct` + `type` enums (simple, no `impl` blocks) |
| Maps | `HashMap<K, V>` (mutable, hash-based) | `{"k": v}` literals (immutable, list of tuples) |
| Generics | Monomorphized generics + traits | Inferred polymorphism |
| Compilation target | LLVM (native) | Koka -> C (native) |
| Loops | `loop`, `while`, `for`, `break`/`continue`, labeled breaks | `loop`, `while`, `for`, `repeat`, `break`/`continue` |
| Learning curve | Steep (ownership, lifetimes, traits) | Gentle (write, run, iterate) |
| Ecosystem | Massive (crates.io) | Small, growing |

## Type Inference

Rust infers local variable types but requires annotations on function signatures:

```rust
fn add(a: i32, b: i32) -> i32 {
    a + b
}

let x = add(2, 3); // x inferred as i32
```

hica infers types across function boundaries. Annotations are optional rather than required:

```rust
fun add(a, b) => a + b

fun main() {
  println(add(2, 3))
}
```

You can add them when you want clarity:

```rust
fun add(a: int, b: int) : int => a + b
```

## Memory Management

This is where the languages diverge most. Rust uses ownership and borrowing, enforced at compile time:

```rust
fn main() {
    let s1 = String::from("hello");
    let s2 = s1;          // s1 is moved, no longer valid
    // println!("{}", s1); // compile error: value used after move
    println!("{}", s2);
}
```

hica has no ownership system. Koka's Perceus reference counting handles memory automatically, so you never think about borrows, lifetimes, or moves:

```rust
fun main() {
  let s1 = "hello"
  let s2 = s1
  println(s1)
  println(s2)
}
```

Rust enforces memory safety at compile time through ownership. hica delegates memory management to Perceus reference counting, trading compile-time guarantees and fine-grained control for a simpler programming model.

## Functions and Closures

Rust closures come in three flavors depending on how they capture:

```rust
let x = 5;
let add_x = |n| n + x;         // captures by reference (Fn)
let mut v = vec![];
let push = |n| v.push(n);      // captures by mutable reference (FnMut)
let name = String::from("hi");
let take = move || println!("{}", name); // captures by move (FnOnce)
```

hica has one closure type. Closures capture values implicitly, without exposing capture modes (no by-ref vs by-move distinction):

```rust
fun make_adder(n) => (x) => x + n

fun main() {
  let add5 = make_adder(5)
  println(add5(10))
  println(add5(20))
}
```

No `Fn` vs `FnMut` vs `FnOnce` to reason about.

## Error Handling

Both use `Result` types. Rust adds the `?` operator for ergonomic early returns:

```rust
fn read_config() -> Result<Config, io::Error> {
    let contents = fs::read_to_string("config.toml")?;
    let config = parse(contents)?;
    Ok(config)
}
```

hica uses `match` explicitly:

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

hica also has combinators for chaining without deeply nested `match`:

```rust
fun main() {
  let result = safe_divide(10, 2)
    |> map_result((n) => n * 10)                    // Ok(50)
    |> and_then_result((n) => safe_divide(n, 5))    // Ok(10)
  println(result)
}
```

Rust's `?` is still more ergonomic for long chains, but hica's combinators (`map_result`, `and_then_result`, `map_err`) close much of the gap. hica doesn't yet have a `?` operator (it would require an effect-based early-return mechanism).

## String Operations

Rust distinguishes `String` (owned, heap-allocated) from `&str` (borrowed slice), and string methods live on these types:

```rust
let msg = "  Hello, World!  ";
println!("{}", msg.trim());
println!("{}", msg.to_uppercase());
println!("{}", msg.contains("World"));
let parts: Vec<&str> = "a,b,c".split(',').collect();
let joined = ["a", "b"].join(", ");
println!("{}", msg.replace("World", "Rust"));
```

hica has one string type and free functions:

```rust
fun main() {
  let msg = "  Hello, World!  "
  println(trim(msg))
  println(to_upper(msg))
  println(contains(msg, "World"))
  println(split("a,b,c", ","))
  println(join(["a", "b"], ", "))
  println(replace(msg, "World", "hica"))
}
```

### Indexing & slicing

| Rust | hica |
|------|------|
| `s.chars().nth(0).unwrap()` | `s[0]` |
| `&s[1..4]` (byte indices, can panic) | `s[1:4]` (char indices, safe) |
| `&s[..3]` | `s[:3]` |
| `s.strip_prefix("v").unwrap_or(s)` | `removeprefix(s, "v")` |
| `s.strip_suffix(".txt").unwrap_or(s)` | `removesuffix(s, ".txt")` |

Rust requires understanding `String` vs `&str` ownership and byte vs char indexing. hica has a single immutable `string` type with char-based indexing that is simpler to learn, although without Rust's fine-grained control over allocation.

## Parsing & Type Conversion

Rust uses `parse()` with turbofish syntax and returns `Result`:

```rust
let n: i32 = "42".parse().unwrap();        // 42
let bad: Result<i32, _> = "abc".parse();   // Err(...)
let f: f64 = "3.14".parse().unwrap();      // 3.14
```

hica uses `parse_int` and `parse_float`, returning `maybe`:

```rust
fun main() {
  println(parse_int("42"))     // Some(42)
  println(parse_int("abc"))    // None
  println(parse_float("3.14")) // Some(3.14)
  println(parse_float("xyz"))  // None

  match parse_int("100") {
    Some(n) => println("Got: {n}"),
    None    => println("Not a number")
  }
}
```

Rust's `parse()` is generic over the target type and returns `Result`. hica uses separate named functions and returns `maybe`, trading generality for simplicity.

## Pattern Matching

Rust has deep, exhaustive pattern matching with guards, nested destructuring, ranges, and `if let`:

```rust
match point {
    (0, 0) => println!("origin"),
    (x, 0) | (0, x) => println!("on axis: {x}"),
    (x, y) if x == y => println!("diagonal"),
    (x, y) => println!("({x}, {y})"),
}

match score {
    0..=59 => println!("F"),
    60..=69 => println!("D"),
    _ => println!("C or above"),
}
```

hica supports integer, string, wildcard, `Maybe`/`Result`, tuple, or-patterns, range patterns, and struct destructuring:

```rust
fun describe(x) => match x {
  0 => "zero",
  1 | 2 | 3 => "low",
  _ => "many"
}

fun grade(score: int) => match score {
  0..=59   => "F",
  60..=69  => "D",
  90..=100 => "A",
  _        => "other"
}

struct Point { x: int, y: int }

fun classify(p: Point) : string => match p {
  Point { x: 0, y: 0 } => "origin",
  Point { x, y }       => "({x}, {y})"
}

fun sum(xs: list<int>) : int => match xs {
  []          => 0,
  [x, ..rest] => x + sum(rest)
}
```

Both languages use `..=` for inclusive range patterns, support struct destructuring, and have list/slice patterns in match. Rust uses `[first, rest @ ..]` syntax; hica uses `[first, ..rest]`. Rust's pattern matching is still more powerful (`if let`, `@` bindings, exclusive ranges with `..`, nested destructuring). hica covers the common cases — including or-patterns, guards, ranges, struct patterns, and list slice patterns — with fewer constructs and edge cases to learn.

## Custom Data Types

Rust uses `struct` with `impl` blocks and `derive` macros:

```rust
#[derive(Debug)]
struct Point {
    x: i32,
    y: i32,
}

impl Point {
    fn distance_sq(&self) -> i32 {
        self.x * self.x + self.y * self.y
    }
}

fn main() {
    let p = Point { x: 3, y: 4 };
    println!("{}", p.distance_sq());  // 25
    println!("{:?}", p);              // Point { x: 3, y: 4 }
}
```

hica uses `struct` without `impl` blocks. Functions that operate on structs are regular free functions:

```rust
struct Point { x: int, y: int }

fun distance_sq(p: Point) : int => p.x * p.x + p.y * p.y

fun main() {
  let p = Point { x: 3, y: 4 }
  println(distance_sq(p))   // 25
  println(p)                 // Point(x: 3, y: 4)
}
```

Rust's `impl` blocks group methods on a type with `self` access, `derive` generates common trait implementations, and traits provide polymorphism. hica keeps it simple: structs hold data, free functions operate on them, and `show` is auto-generated. Both support struct update syntax: Rust's `Point { x: 10, ..p }` is hica's `Point { ...p, x: 10 }`.

## Enums (Algebraic Types)

Rust has powerful `enum` types with `impl` blocks and `derive`:

```rust
#[derive(Debug)]
enum Shape {
    Circle(f64),
    Rect(f64, f64),
    Point,
}

impl Shape {
    fn area(&self) -> f64 {
        match self {
            Shape::Circle(r) => std::f64::consts::PI * r * r,
            Shape::Rect(w, h) => w * h,
            Shape::Point => 0.0,
        }
    }
}
```

hica has the same core concept with a lighter syntax:

```rust
type Shape {
  Circle(radius: float),
  Rect(width: float, height: float),
  Point
}

fun area(s: Shape) : float => match s {
  Circle(r)  => 3.14159 * r * r,
  Rect(w, h) => w * h,
  Point      => 0.0
}
```

| Rust | hica |
|------|------|
| `enum Shape { Circle(f64), ... }` | `type Shape { Circle(radius: float), ... }` |
| `Shape::Circle(5.0)` (qualified) | `Circle(5.0)` (unqualified) |
| `match self { Shape::Circle(r) => ... }` | `match s { Circle(r) => ... }` |
| `#[derive(Debug)]` for printing | Auto-generated `show` |
| `impl` blocks for methods | Free functions |

Both languages have exhaustive matching — the compiler ensures every variant is handled. Rust adds generic type parameters (`Option<T>`, `Result<T, E>`), nested destructuring, and `if let` / `let else` for partial matching. hica covers the common cases with less syntax: no qualified paths (`Shape::`), no `derive`, no `impl` blocks.

## Maps / Dictionaries

Rust uses `HashMap` from the standard library, requiring an import and explicit type:

```rust
use std::collections::HashMap;

fn main() {
    let mut ages = HashMap::new();
    ages.insert("kalle", 30);
    ages.insert("olle", 25);
    println!("{:?}", ages.get("kalle"));  // Some(30)
    ages.remove("olle");
}
```

hica has built-in map literals with `{"key": value}` syntax. Maps are immutable lists of tuples:

```rust
fun main() {
  let ages = {"kalle": 30, "olle": 25}
  println(ages.map_get("kalle"))     // Just(30)
  let ages2 = ages.map_set("lisa", 35)
  let ages3 = ages2.map_remove("olle")
  println(ages3.map_keys())          // ["kalle", "lisa"]
}
```

| Rust | hica |
|------|------|
| `map.get(&key)` → `Option<&V>` | `map_get(m, key)` → `maybe<v>` |
| `map.insert(key, val)` (mutates) | `map_set(m, key, val)` (returns new map) |
| `map.remove(&key)` | `map_remove(m, key)` |
| `map.keys()` | `map_keys(m)` |
| `map.values()` | `map_values(m)` |
| `map.contains_key(&key)` | `map_contains_key(m, key)` |
| `map.len()` | `map_size(m)` |

Rust's `HashMap` is a mutable hash table with O(1) average lookup and full generic support. hica maps are immutable association lists — no imports, built-in literal syntax, and composable with all list functions (`filter`, `map`, `fold`), but O(n) lookup. Rust gives performance and flexibility; hica gives simplicity and immutability by default.

## Immutability

Both are immutable by default. Rust lets you opt in to mutability:

```rust
let x = 5;         // immutable
let mut y = 10;    // mutable
y += 1;
```

hica has no `mut`. All bindings are immutable. State changes are expressed by creating new values rather than mutating existing ones:

```rust
fun main() {
  let nums = [1, 2, 3]
  let doubled = map(nums, (x) => x * 2)
  println(doubled)
}
```

## Pipe Operator and Dot-Call Syntax

Rust doesn't have a built-in pipe operator. Method chaining on iterators fills a similar role:

```rust
let result: Vec<i32> = vec![1, 2, 3, 4, 5]
    .iter()
    .filter(|x| *x % 2 == 0)
    .map(|x| x * 10)
    .collect();
```

hica has both a pipe operator `|>` and dot-call syntax — they're equivalent and both work with any function:

```rust
fun main() {
  // Pipe style
  let a = [1, 2, 3, 4, 5]
    |> filter((x) => x % 2 == 0)
    |> map((x) => x * 10)

  // Dot-call style (same result, closer to Rust's method chaining)
  let b = [1, 2, 3, 4, 5]
    .filter((x) => x % 2 == 0)
    .map((x) => x * 10)

  println(a == b)
}
```

Unlike Rust, hica's dot-call isn't limited to methods defined in `impl` blocks — any function can be called with dot syntax. `a.f(b)` desugars to `f(a, b)`.

## Loops

Rust has `loop`, `while`, and `for` with `break`/`continue`:

```rust
for x in &[1, -2, 3] {
    if *x < 0 { continue; }
    println!("{}", x);
}

let result = loop {
    break 42;
};
```

Rust's `loop` can return a value via `break expr`. Labeled breaks (`'outer: loop { break 'outer; }`) allow breaking from nested loops.

hica has the same set: `while`, `for`, `repeat`, `loop`, `break`, and `continue`:

```rust
for x in [1, -2, 3] {
  if x < 0 { continue }
  println(x)
}

loop {
  break
}
```

hica's `break` cannot return a value and there are no labeled breaks. `break`/`continue` always apply to the innermost loop.

## Bitwise Operations

Rust uses infix operators and works across multiple integer types:

```rust
let flags: u8 = 0b1010_1100;
let masked = flags & 0x0F;       // AND
let shifted = flags >> 4;        // shift right
let flipped = flags ^ 0xFF;      // XOR
let complement = !flags;         // NOT
```

hica uses named functions. All operations work on 32-bit integers internally:

```rust
fun main() {
  let flags = 0b1010_1100
  let masked = bit_and(flags, 0x0F)
  let shifted = bit_shr(flags, 4)
  let flipped = bit_xor(flags, 0xFF)
  let complement = bit_not(flags)
}
```

Rust's operators are familiar to C programmers and work on every integer type (`u8`, `i32`, `u64`, etc.). hica has a single `int` type with named functions — less flexible, but no concerns about integer width mismatches.

hica adds bit-level pattern matching with `?` wildcards, inspired by hardware description languages:

```rust
match opcode {
  0b11??_???? => "category 3",
  0b10??_???? => "category 2",
  _           => "other"
}
```

Rust has no direct equivalent — you'd write explicit mask-and-compare guards.

## Compilation and Performance

Rust compiles through LLVM to native code with fine-grained control over performance, allocation, and inlining.

hica compiles through Koka to C. The resulting binaries are fast in practice, but without fine-grained control over allocation patterns, inlining, or memory layout.

## Ecosystem

Rust has crates.io with over 150,000 packages, extensive documentation, an active community, and production use at major companies. hica is a new language with a small but growing set of examples, backed by the Koka standard library. Rust wins here by orders of magnitude.

## Conclusion

**Rust** is the right choice when you need zero-cost abstractions, fine-grained memory control, and a battle-tested ecosystem for production systems.

**hica** is the right choice when you want the same values (immutability, type safety, expression-oriented design) without the learning curve of ownership and lifetimes. It's a good stepping stone toward Rust, or a simpler alternative when automatic reference counting is sufficient and you don't need fine-grained control over memory or performance.

If you already know Rust, you'll read hica code fluently. If you're learning hica first, you'll find that many of its patterns (Result types, match expressions, immutability) transfer directly when you're ready for Rust.
