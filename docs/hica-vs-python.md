---
layout: default
title: Hica vs. Python - hica
---

# Hica vs Python

If you're looking for a first programming language, whether for yourself, your kids, or your students, Python and hica are both excellent choices. But they take very different paths to the same goal: making programming accessible, with different trade-offs between simplicity, safety, and explicitness.

## At a Glance

| Dimension | Python | hica |
|-----------|--------|------|
| Type safety | Dynamic typing (errors at runtime unless using type hints) | Compile-time errors |
| Readability | Excellent (indentation) | Excellent (arrows, braces) |
| Mutability | Mutable by default | Immutable by design |
| Functions | `def` + simple lambdas (single-expression only) | `fun` + full closures + `|>` pipe |
| Error handling | Exceptions (implicit flow) | Result types + combinators (explicit handling) |
| Data structures | Classes / dataclasses | Structs + enums |
| Dictionaries | `dict` (built-in, mutable) | Maps (`{"k": v}`, immutable list of tuples) |
| Lists | List comprehensions | `map`/`filter`/`fold` + pipe |
| Pattern matching | Added in 3.10, optional | Core feature from day one |
| Loops | `for`, `while`, `break`, `continue` | `for`, `while`, `repeat`, `loop`, `break`, `continue` |
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
  let result = double(21)
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

**hica** defaults to immutable with `let`. You create new values instead of mutating:

```rust
let scores = [85, 92, 78]
let updated = scores + [95]
let doubled = map(scores, (x) => x * 2)
```

When you need mutation, use `var`:

```rust
var count = 0
while count < 10 {
  println(count)
  count = count + 1
}
```

`var` is locally scoped and effect-safe — the mutable state can't leak outside the function. This gives you the convenience of mutation when you need it, without the risks of shared mutable state.

## Functions and Closures

**Python** has `def` and simple lambdas (single-expression only):

```python
double = lambda x: x * 2
scores = list(map(double, [1, 2, 3, 4, 5]))
```

**hica** has `fun` and full closures with the pipe operator:

```rust
let double = (x) => x * 2
let scores = [1, 2, 3, 4, 5] |> map((x) => x * 2)
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

For chaining, hica has combinators that reduce the verbosity:

```rust
fun main() {
  let result = safe_divide(10, 2)
    |> map_result((n) => n * 10)                    // Ok(50)
    |> and_then_result((n) => safe_divide(n, 5))    // Ok(10)
  println(result)
}
```

This makes error paths explicit. Python's exception model is more concise for simple cases, but errors can silently propagate. hica forces you to handle each failure point, either with `match` or with combinators like `map_result` and `and_then_result`.

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

| Python | hica | Result |
|--------|------|--------|
| `s[0]` | `s[0]` | First character (hica returns `char`) |
| `s[-1]` | `s[-1]` | Last character |
| `s[1:4]` | `s[1:4]` | Substring (same syntax!) |
| `s[:3]` | `s[:3]` | First 3 characters |
| `s[2:]` | `s[2:]` | From index 2 to end |
| `s.capitalise()` | `capitalise(s)` | `"hello"` → `"Hello"` |
| `s.removeprefix("v")` | `removeprefix(s, "v")` | Strip prefix |
| `s.removesuffix(".txt")` | `removesuffix(s, ".txt")` | Strip suffix |

Python uses method syntax (`s.strip()`), hica uses function syntax (`trim(s)`) — but hica also supports dot-call syntax, so you can write `s.trim().to_upper()` just like method chaining. The pipe operator works too: `s |> trim |> to_upper`. Both styles are equivalent; use whichever you prefer.

## Parsing & Type Conversion

**Python** uses built-in constructors that raise exceptions on bad input:

```python
n = int("42")       # 42
f = float("3.14")   # 3.14
int("abc")          # ValueError at runtime
```

**hica** has safe parse functions that return `maybe` instead of crashing:

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

Python's `int()` / `float()` are concise but require `try`/`except` for safety. hica's `parse_int` / `parse_float` make the failure case explicit through `maybe`, so invalid input can never crash.

## Custom Data Types

**Python** uses classes or `dataclass` to define custom types:

```python
from dataclasses import dataclass

@dataclass
class Point:
    x: int
    y: int

p = Point(3, 4)
print(p.x)       # 3
print(p)         # Point(x=3, y=4)
```

**hica** uses `struct`:

```rust
struct Point { x: int, y: int }

fun main() {
  let p = Point { x: 3, y: 4 }
  println(p.x)    // 3
  println(p)      // Point(x: 3, y: 4)
}
```

Python has classes with inheritance, methods, and dunder protocols. hica has simple immutable structs with free functions, no `self`, `__init__` or inheritance. Functions that operate on structs are just regular functions:

```rust
struct Point { x: int, y: int }

fun distance_sq(p: Point) : int => p.x * p.x + p.y * p.y
```

## Enums (Algebraic Types)

**Python** doesn't have built-in algebraic types. You can approximate them with classes or `enum.Enum`, but there's no exhaustiveness checking and no variant data:

```python
from enum import Enum

class Color(Enum):
    RED = 1
    GREEN = 2
    BLUE = 3

# For variants with data, you need classes:
class Circle:
    def __init__(self, radius):
        self.radius = radius

class Rect:
    def __init__(self, w, h):
        self.w = w
        self.h = h

def area(shape):
    if isinstance(shape, Circle):
        return 3.14159 * shape.radius ** 2
    elif isinstance(shape, Rect):
        return shape.w * shape.h
    # Easy to forget a case — no compiler warning!
```

**hica** has first-class enum types with exhaustiveness checking:

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

If you forget a variant, the compiler warns you:

```
warning: non-exhaustive match: missing Point
```

Python's `isinstance` chains are error-prone and have no compile-time safety. hica's `match` is exhaustive — every case must be handled. This is one of hica's strongest advantages over Python for modelling data that comes in different shapes.

## Dictionaries / Maps

**Python** has a built-in mutable `dict` type:

```python
ages = {"kalle": 30, "olle": 25}
ages["lisa"] = 35         # mutates in place
print(ages["kalle"])      # 30
print(ages.get("nobody")) # None
del ages["olle"]
print(list(ages.keys()))  # ['kalle', 'lisa']
```

**hica** has map literals with the same `{"key": value}` syntax, but maps are immutable lists of tuples:

```rust
fun main() {
  let ages = {"kalle": 30, "olle": 25}
  let ages2 = ages.map_set("lisa", 35)
  println(ages2.map_get("kalle"))   // Just(30)
  println(ages2.map_get("nobody"))  // Nothing
  let ages3 = ages2.map_remove("olle")
  println(ages3.map_keys())         // ["kalle", "lisa"]
}
```

| Python | hica |
|--------|------|
| `d[key]` (raises `KeyError`) | `map_get(m, key)` (returns `maybe`) |
| `d[key] = val` (mutates) | `map_set(m, key, val)` (returns new map) |
| `del d[key]` | `map_remove(m, key)` |
| `d.keys()` | `map_keys(m)` |
| `d.values()` | `map_values(m)` |
| `key in d` | `map_contains_key(m, key)` |
| `len(d)` | `map_size(m)` |

Python dicts are mutable hash tables with O(1) lookup. hica maps are immutable association lists — simpler and composable with all list functions (`filter`, `map`, `fold`), but O(n) lookup. For small maps this is fine; for large data sets, Python's dict is more efficient.

## Pattern Matching

**Python** added `match` in 3.10, but it's optional:

```python
match command:
    case "quit":
        exit()
    case _:
        print("Unknown")
```

**hica** makes `match` central. It works with integers, strings, `Some`/`None`, `Ok`/`Err`, wildcards, or-patterns, range patterns, and struct destructuring:

```rust
fun describe(x) => match x {
  0       => "nothing",
  1 | 2   => "few",
  _       => "many"
}

fun grade(score: int) => match score {
  0..=59   => "F",
  60..=69  => "D",
  70..=79  => "C",
  80..=89  => "B",
  90..=100 => "A",
  _        => "invalid"
}

struct Point { x: int, y: int }

fun classify(p: Point) : string => match p {
  Point { x: 0, y: 0 } => "origin",
  Point { x, y }       => "({x}, {y})"
}
```

Python's `match` supports guards (`case x if x > 0`) but has no range pattern syntax. hica's `..=` makes numeric ranges concise and readable. Both languages support struct/class destructuring in patterns.

## Loops

**Python** has `for`, `while`, `break`, and `continue`:

```python
for x in [1, -2, 3]:
    if x < 0:
        continue
    print(x)

while True:
    line = input()
    if line == "quit":
        break
```

**hica** has the same constructs plus `repeat` and `loop`:

```rust
for x in [1, -2, 3] {
  if x < 0 { continue }
  println(x)
}

loop {
  // runs forever until break
  break
}

repeat(3) {
  println("tick")
}
```

`break` and `continue` work in all loop types: `while`, `for`, `repeat`, and `loop`. Python's `for/else` and `while/else` have no equivalent in hica.

## Bitwise Operations

**Python** uses infix operators for bitwise operations:

```python
flags = 0b1010_1100
masked = flags & 0x0F         # AND
shifted = flags >> 4          # shift right
flipped = flags ^ 0xFF        # XOR
complement = ~flags           # NOT
```

**hica** uses named functions instead of operators:

```rust
fun main() {
  let flags = 0b1010_1100
  let masked = bit_and(flags, 0x0F)
  let shifted = bit_shr(flags, 4)
  let flipped = bit_xor(flags, 0xFF)
  let complement = bit_not(flags)
}
```

Python's operators are concise; hica's named functions are explicit and self-documenting. Both support binary (`0b`) and hex (`0x`) literals with underscore separators (`0b1111_0000`).

hica also supports bit-level pattern matching with `?` wildcards, which Python has no equivalent for:

```rust
match byte {
  0b1100_???? => "high nibble is C",
  _           => "other"
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
