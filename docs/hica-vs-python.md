---
layout: default
title: Hica vs. Python - hica
---

# hica vs Python

If you're looking for a first programming language, whether for yourself, your kids, or your students, Python and hica are both excellent choices. But they take very different paths to the same goal: making programming accessible, with different trade-offs between simplicity, safety, and explicitness.

## At a Glance

| Dimension | Python | hica |
|-----------|--------|------|
| Type safety | Dynamic typing (errors at runtime unless using type hints) | Compile-time errors |
| Readability | Excellent (indentation) | Excellent (arrows, braces) |
| Mutability | Mutable by default | Immutable by design |
| Functions | `def` + simple lambdas (single-expression only) | `fun` + full closures + `|>` pipe |
| Error handling | Exceptions (implicit flow) | Result types (explicit handling) |
| Lists | List comprehensions | `map`/`filter`/`fold` + pipe |
| Pattern matching | Added in 3.10, optional | Core feature from day one |
| Performance | Interpreted (generally slower) | Compiled to C (generally faster) |
| Ecosystem | Massive | Small but growing |

## Type Safety

**Python** is dynamically typed. Errors like adding a number to a string only show up when the code runs:

```python
def greet(name):
    return "Hello, " + name

greet(42)  # TypeError at runtime
```

**hica** catches most type errors at compile time:

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

Both are very readable. Python wins on prose-like syntax; hica wins on explicitness: curly braces make nesting clear, `let` makes bindings visible.

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

This avoids accidental side effects, but requires a different way of thinking about state.

## Functions and Closures

**Python** has `def` and simple lambdas (single-expression only):

```python
double = lambda x: x * 2
scores = list(map(double, [1, 2, 3, 4, 5]))
```

**hica** has `fun` and full closures with the pipe operator:

```rust
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

**hica** uses `Result` types. The compiler forces you to handle both cases:

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

This makes error paths explicit, but can feel more verbose than Python's exception model.

## String Operations

**Python** has extensive string methods built into the `str` type:

```python
msg = "  Hello, World!  "
print(msg.strip())              # "Hello, World!"
print(msg.upper())              # "  HELLO, WORLD!  "
print("World" in msg)           # True
print("a,b,c".split(","))       # ['a', 'b', 'c']
print(", ".join(["a", "b"]))    # "a, b"
print(msg.replace("World", "Python"))  # "  Hello, Python!  "
```

**hica** has the same operations as free functions:

```rust
fun main() {
  let msg = "  Hello, World!  ";
  println(trim(msg));
  println(to_upper(msg));
  println(contains(msg, "World"));
  println(split("a,b,c", ","));
  println(join(["a", "b"], ", "));
  println(replace(msg, "World", "hica"))
}
```

Python uses method syntax (`s.strip()`), hica uses function syntax (`trim(s)`). Both are readable; hica's style plays well with the pipe operator: `msg |> trim |> to_upper`.

## Pattern Matching

**Python** added `match` in 3.10, but it's optional:

```python
match command:
    case "quit":
        exit()
    case _:
        print("Unknown")
```

**hica** makes `match` central. It works with integers, strings, `Some`/`None`, `Ok`/`Err`, and wildcards:

```rust
fun describe(x) => match x {
  0 => "nothing",
  1 => "one",
  _ => "many"
}
```

## Performance

**Python** is interpreted. **hica** compiles through Koka to C, so the resulting binaries can run at native speed for many workloads.

## Ecosystem

**Python** has an enormous ecosystem: NumPy, pandas, Django, thousands of tutorials, and answers for every question. **hica** is new with a growing set of examples and the Koka standard library underneath. Python wins decisively here.

## Conclusion

**Python** is the safe, proven choice with the largest ecosystem and lowest barrier to entry.

**hica** emphasises foundations like immutability, type safety, pattern matching, and explicit error handling. Students who learn hica carry these patterns into Python, Rust, TypeScript, or whatever they use next.

Why not both? Start with hica to build the foundations, then move to Python with a head start on the concepts that matter most.
