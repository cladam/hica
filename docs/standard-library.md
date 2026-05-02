---
layout: default
title: Standard Library — hica
---

# Standard Library

The prelude is hica's built-in standard library. Every function defined here is automatically available in every hica program — no imports needed.

## I/O & Display

| Function | Signature | Description |
|----------|-----------|-------------|
| `println(s)` | `(a) -> ()` | Print a value to stdout with a newline |
| `show(n)` | `(a) -> string` | Convert a value to its string representation |

## List Operations

| Function | Signature | Description |
|----------|-----------|-------------|
| `map(xs, f)` | `(list<a>, (a) -> b) -> list<b>` | Apply `f` to each element |
| `filter(xs, f)` | `(list<a>, (a) -> bool) -> list<a>` | Keep elements where `f` returns true |
| `fold(xs, init, f)` | `(list<a>, b, (b, a) -> b) -> b` | Reduce a list to a single value |
| `length(xs)` | `(list<a>) -> int` | Length of a list |
| `reverse(xs)` | `(list<a>) -> list<a>` | Reverse a list |
| `take(xs, n)` | `(list<a>, int) -> list<a>` | Take the first `n` elements |
| `drop(xs, n)` | `(list<a>, int) -> list<a>` | Drop the first `n` elements |
| `zip(xs, ys)` | `(list<a>, list<b>) -> list<(a, b)>` | Pair up elements from two lists |
| `concat(xss)` | `(list<list<a>>) -> list<a>` | Flatten a list of lists |
| `any(xs, f)` | `(list<a>, (a) -> bool) -> bool` | True if `f` holds for any element |
| `all(xs, f)` | `(list<a>, (a) -> bool) -> bool` | True if `f` holds for all elements |
| `foreach(xs, f)` | `(list<a>, (a) -> ()) -> ()` | Call `f` on each element for side effects |
| `enumerate(xs)` | `(list<a>) -> list<(int, a)>` | Pair each element with its index |

## Math (`prelude/math.hc`)

Written in hica itself:

| Function | Signature | Description |
|----------|-----------|-------------|
| `abs(n)` | `(int) -> int` | Absolute value |
| `min(a, b)` | `(int, int) -> int` | Smaller of two values |
| `max(a, b)` | `(int, int) -> int` | Larger of two values |
| `clamp(v, lo, hi)` | `(int, int, int) -> int` | Constrain `v` to the range `[lo, hi]` |

## Examples

### Map and filter

```rust
fun main() {
  let nums = [1, 2, 3, 4, 5];
  let evens = filter(nums, (x) => x % 2 == 0);
  let doubled = map(nums, (x) => x * 2);
  println(evens);
  println(doubled)
}
```

### Fold

```rust
fun main() {
  let nums = [1, 2, 3, 4, 5];
  let total = fold(nums, 0, (acc, x) => acc + x);
  println(total)
}
```

### Pipe with standard library

```rust
fun main() {
  let result = [1, 2, 3, 4, 5]
    |> filter((x) => x % 2 == 0)
    |> map((x) => x * 10)
    |> fold(0, (acc, x) => acc + x);
  println(result)
}
```
