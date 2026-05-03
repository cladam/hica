---
layout: default
title: Standard Library - hica
---

# Standard Library

The prelude is hica's built-in standard library. Every function defined here is automatically available in every hica program. No imports needed.

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
| `find(xs, f)` | `(list<a>, (a) -> bool) -> maybe<a>` | First element where `f` returns true, or `None` |

## Math (`prelude/math.hc`)

Written in hica itself:

| Function | Signature | Description |
|----------|-----------|-------------|
| `abs(n)` | `(int) -> int` | Absolute value |
| `min(a, b)` | `(int, int) -> int` | Smaller of two values |
| `max(a, b)` | `(int, int) -> int` | Larger of two values |
| `clamp(v, lo, hi)` | `(int, int, int) -> int` | Constrain `v` to the range `[lo, hi]` |

## String Operations

Primitive string functions backed by Koka's string library:

| Function | Signature | Description |
|----------|-----------|-------------|
| `str_length(s)` | `(string) -> int` | Number of characters in a string |
| `contains(s, sub)` | `(string, string) -> bool` | True if `s` contains `sub` |
| `starts_with(s, pre)` | `(string, string) -> bool` | True if `s` starts with `pre` |
| `ends_with(s, suf)` | `(string, string) -> bool` | True if `s` ends with `suf` |
| `trim(s)` | `(string) -> string` | Remove leading and trailing whitespace |
| `trim_start(s)` | `(string) -> string` | Remove leading whitespace |
| `trim_end(s)` | `(string) -> string` | Remove trailing whitespace |
| `to_upper(s)` | `(string) -> string` | Convert to uppercase |
| `to_lower(s)` | `(string) -> string` | Convert to lowercase |
| `split(s, sep)` | `(string, string) -> list<string>` | Split a string by separator |
| `replace(s, old, new)` | `(string, string, string) -> string` | Replace all occurrences |
| `join(xs, sep)` | `(list<string>, string) -> string` | Join a list of strings with separator |
| `index_of(s, sub)` | `(string, string) -> maybe<int>` | Index of first occurrence of `sub`, or `None` |
| `to_int(s)` | `(string) -> int` | Parse string as integer (-1 if invalid) |

### String Comparison

Strings support `<`, `>`, `<=`, `>=` for lexicographic comparison:

```rust
fun main() {
  println("apple" < "banana");   // true
  println("zoo" > "abc");        // true
  println("abc" <= "abc")        // true
}
```

### String Indexing & Slicing

Strings support the same `[]` syntax as lists:

| Syntax | Returns | Description |
|--------|---------|-------------|
| `s[i]` | `char` | Character at index `i` |
| `s[i:j]` | `string` | Substring from `i` to `j` (exclusive) |
| `s[:j]` | `string` | First `j` characters |
| `s[i:]` | `string` | From index `i` to end |
| `s[-1]` | `char` | Last character (negative indexing) |

```rust
fun main() {
  let s = "hello";
  println(s[0]);      // 'h'
  println(s[1:4]);    // "ell"
  println(s[:3]);     // "hel"
  println(s[-1])      // 'o'
}
```

## String Helpers (`prelude/strings.hc`)

Written in hica itself:

| Function | Signature | Description |
|----------|-----------|-------------|
| `is_empty(s)` | `(string) -> bool` | True if the string has zero length |
| `is_blank(s)` | `(string) -> bool` | True if the string is empty after trimming |
| `words(s)` | `(string) -> list<string>` | Split on spaces, removing empty parts |
| `lines(s)` | `(string) -> list<string>` | Split on newlines |
| `repeat_str(s, n)` | `(string, int) -> string` | Repeat a string `n` times |
| `pad_left(s, width, ch)` | `(string, int, string) -> string` | Pad on the left to `width` |
| `pad_right(s, width, ch)` | `(string, int, string) -> string` | Pad on the right to `width` |
| `center(s, width, ch)` | `(string, int, string) -> string` | Center `s` in `width`, padding with `ch` |
| `surround(s, wrap)` | `(string, string) -> string` | Wrap `s` with `wrap` on both sides |
| `unwords(ws)` | `(list<string>) -> string` | Join words with a space |
| `unlines(ls)` | `(list<string>) -> string` | Join lines with a newline |
| `count_substr(s, sub)` | `(string, string) -> int` | Count occurrences of `sub` in `s` |
| `capitalize(s)` | `(string) -> string` | Uppercase first letter, lowercase rest |
| `capwords(s)` | `(string) -> string` | Capitalize each word |
| `removeprefix(s, pre)` | `(string, string) -> string` | Remove prefix if present |
| `removesuffix(s, suf)` | `(string, string) -> string` | Remove suffix if present |

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

### String operations

```rust
fun main() {
  let msg = "  Hello, World!  ";
  println(trim(msg));
  println(to_upper(trim(msg)));
  println(contains(msg, "World"));

  let csv = "kalle,lisa,olle";
  println(split(csv, ","));
  println(join(split(csv, ","), " & "));
  println(replace(csv, ",", " | "))
}
```

### String helpers from prelude

```rust
fun main() {
  println(words("the  quick   fox"));
  println(pad_left("42", 6, "0"));
  println(surround("hello", "**"))
}
```
