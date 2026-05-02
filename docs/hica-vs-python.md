---
layout: default
title: hica vs Python — hica
---

# hica vs Python

If you're looking for a first programming language — for yourself, your kids, or your students — Python and hica are both excellent choices. But they take very different paths to the same goal: making programming accessible.

## At a Glance

| Dimension | Python | hica |
|-----------|--------|------|
| Type safety | Runtime errors | Compile-time errors |
| Readability | Excellent (indentation) | Excellent (arrows, braces) |
| Mutability | Mutable by default | Immutable by design |
| Functions | `def` + limited `lambda` | `fun` + full closures + `&#124;>` pipe |
| Error handling | Exceptions (easy to forget) | Result types (forced to handle) |
| Lists | List comprehensions | `map`/`filter`/`fold` + pipe |
| Pattern matching | Added in 3.10, optional | Core feature from day one |
| Performance | Interpreted, slow | Compiled to C, fast |
| Ecosystem | Massive | Small but growing |

## Type Safety

**Python** is dynamically typed. Errors like adding a number to a string only show up when the code runs:

```python
def greet(name):
    return "Hello, " + name

greet(42)  # TypeError at runtime
```

**hica** catches type errors at compile time:

```rust
fun greet(name) => "Hello, " + name

fun main() {
  greet(42)  // Compile error: expected string, got int
}
```

## Readability

**Python:**

```python
def double(x):
    return x * 2

result = double(21)
print(result)
```

**hica:**

```rust
fun double(x) => x * 2

fun main() {
  let result = double(21);
  println(result)
}
```

Both are very readable. Python wins on prose-like syntax; hica wins on explicitness — curly braces make nesting clear, `let` makes bindings visible.

## Immutability

**Python** has mutable variables by default:

```python
scores = [85, 92, 78]
scores.append(95)       # mutates the original list
scores[0] = 100         # changes in place
```

**hica** is immutable by design. You create new values instead of mutating:

```rust
let scores = [85, 92, 78];
let updated = scores + [95];
let doubled = map(scores, (x) => x * 2);
```

## Functions and Closures

**Python** has `def` and limited `lambda`:

```python
double = lambda x: x * 2
scores = list(map(double, [1, 2, 3, 4, 5]))
```

**hica** has `fun` and full closures with the pipe operator:

```hica
let double = (x) => x * 2;
let scores = [1, 2, 3, 4, 5] |> map((x) => x * 2);
```

## Error Handling

**Python** uses exceptions:

```python
def safe_divide(a, b):
    if b == 0:
        raise ValueError("division by zero")
    return a / b

try:
    result = safe_divide(10, 0)
except ValueError as e:
    print(e)
```

**hica** uses `Result` types — the compiler forces you to handle both cases:

```rust
fun safe_divide(a, b) =>
  if b == 0 { Err("division by zero") }
  else { Ok(a / b) }

fun main() {
  match safe_divide(10, 0) {
    Ok(n)  => println(n),
    Err(e) => println(e)
  }
}
```

## Pattern Matching

**Python** added `match` in 3.10, but it's optional:

```python
match command:
    case "quit":
        exit()
    case _:
        print("Unknown")
```

**hica** makes `match` central — it works with integers, strings, `Some`/`None`, `Ok`/`Err`, and wildcards:

```rust
fun describe(x) => match x {
  0 => "nothing",
  1 => "one",
  _ => "many"
}
```

## Performance

**Python** is interpreted. **hica** compiles through Koka to C — the resulting binaries run at native speed.

## Ecosystem

**Python** has an enormous ecosystem: NumPy, pandas, Django, thousands of tutorials, and answers for every question. **hica** is new with a growing set of examples and the Koka standard library underneath. Python wins decisively here.

## Conclusion

**Python** is the safe, proven choice with the largest ecosystem and lowest barrier to entry.

**hica** teaches stronger foundations: immutability, type safety, pattern matching, and explicit error handling. Students who learn hica carry these patterns into Python, Rust, TypeScript, or whatever they use next.

Why not both? Start with hica to build the foundations, then move to Python with a head start on the concepts that matter most.
