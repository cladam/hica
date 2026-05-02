---
layout: default
title: Hica vs. Rust - hica
---

# hica vs Rust

hica and Rust share values like immutability, expression-oriented design, `match` as a core feature, and `Result`/`Option` types. They diverge in how much complexity they expose to achieve control and performance.

## At a Glance

| Dimension | Rust | hica |
|-----------|------|------|
| Type system | Ownership + lifetimes + traits | Hindley-Milner inference (little to no annotations in practice) |
| Memory model | Borrow checker, zero-cost abstractions | Automatic reference counting with compile-time optimisation (Koka/Perceus) |
| Mutability | Immutable by default, `mut` opt-in | Immutable, no `mut` |
| Error handling | `Result<T, E>` + `?` operator | `Result` + `match` |
| Closures | `Fn` / `FnMut` / `FnOnce` traits | Single closure type, always captured |
| Pattern matching | Exhaustive, deeply nested | Common cases (primitives + Maybe/Result), not deeply nested |
| Generics | Monomorphized generics + traits | Inferred polymorphism |
| Compilation target | LLVM (native) | Koka -> C (native) |
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
  let s1 = "hello";
  let s2 = s1;
  println(s1);
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
  let add5 = make_adder(5);
  println(add5(10));
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

Rust's `?` is more ergonomic for chaining fallible operations. hica favours explicit control flow via `match` rather than implicit propagation. This keeps behaviour visible but can be more verbose for deeply chained operations.

## Pattern Matching

Rust has deep, exhaustive pattern matching with guards, nested destructuring, and `if let`:

```rust
match point {
    (0, 0) => println!("origin"),
    (x, 0) | (0, x) => println!("on axis: {x}"),
    (x, y) if x == y => println!("diagonal"),
    (x, y) => println!("({x}, {y})"),
}
```

hica supports integer, string, wildcard, and `Maybe`/`Result` patterns:

```rust
fun describe(x) => match x {
  0 => "zero",
  1 => "one",
  _ => "many"
}

fun main() {
  match Some(42) {
    Some(n) => println(n),
    None    => println("nothing")
  }
}
```

Rust's pattern matching is more powerful. hica covers the common cases with fewer constructs and edge cases to learn.

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
  let nums = [1, 2, 3];
  let doubled = map(nums, (x) => x * 2);
  println(doubled)
}
```

## Pipe Operator

Rust doesn't have a built-in pipe operator. Method chaining on iterators fills a similar role:

```rust
let result: Vec<i32> = vec![1, 2, 3, 4, 5]
    .iter()
    .filter(|x| *x % 2 == 0)
    .map(|x| x * 10)
    .collect();
```

hica has a first-class pipe `|>` that works with any function, not just methods:

```rust
fun main() {
  let result = [1, 2, 3, 4, 5]
    |> filter((x) => x % 2 == 0)
    |> map((x) => x * 10)
    |> fold(0, (acc, x) => acc + x);
  println(result)
}
```

## Compilation and Performance

Rust compiles through LLVM to native code with fine-grained control over performance, allocation, and inlining.

hica compiles through Koka to C. The resulting binaries are fast in practice, but without fine-grained control over allocation patterns, inlining, or memory layout.

## Ecosystem

Rust has crates.io with over 150,000 packages, extensive documentation, an active community, and production use at major companies. hica is a new language with a small but growing set of examples, backed by the Koka standard library. Rust wins here by orders of magnitude.

## Conclusion

**Rust** is the right choice when you need zero-cost abstractions, fine-grained memory control, and a battle-tested ecosystem for production systems.

**hica** is the right choice when you want the same values (immutability, type safety, expression-oriented design) without the learning curve of ownership and lifetimes. It's a good stepping stone toward Rust, or a simpler alternative when automatic reference counting is sufficient and you don't need fine-grained control over memory or performance.

If you already know Rust, you'll read hica code fluently. If you're learning hica first, you'll find that many of its patterns (Result types, match expressions, immutability) transfer directly when you're ready for Rust.
