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
| `eprintln(s)` | `(a) -> ()` | Print a value to stderr with a newline |
| `show(n)` | `(a) -> string` | Convert a value to its string representation |
| `show_fixed(value, n)` | `(float, int) -> string` | Format a float with `n` decimal places |

## Environment

| Function | Signature | Description |
|----------|-----------|-------------|
| `get_args()` | `() -> list<string>` | Command-line arguments (excluding the program name) |
| `get_env(key)` | `(string) -> maybe<string>` | Look up an environment variable; returns `Some(value)` or `None` |

## File I/O

| Function | Signature | Description |
|----------|-----------|-------------|
| `read_file(path)` | `(string) -> result<string, string>` | Read entire file; returns `Ok(content)` or `Err(message)` |
| `write_file(path, content)` | `(string, string) -> ()` | Write a string to a file (throws on error) |

## Maybe Combinators

| Function | Signature | Description |
|----------|-----------|-------------|
| `map_maybe(m, f)` | `(maybe<a>, (a) -> b) -> maybe<b>` | Transform the value inside a `Some`; pass `None` through |
| `and_then(m, f)` | `(maybe<a>, (a) -> maybe<b>) -> maybe<b>` | Chain a function that returns `maybe`; short-circuits on `None` |
| `unwrap_maybe(m)` | `(maybe<a>) -> a` | Extract the `Some` value, or throw on `None` |
| `unwrap_maybe_or(m, default)` | `(maybe<a>, a) -> a` | Extract the `Some` value, or return `default` |
| `is_some(m)` | `(maybe<a>) -> bool` | True if `Some` |
| `is_none(m)` | `(maybe<a>) -> bool` | True if `None` |

```rust
fun main() {
  // Transform a maybe value
  let doubled = Some(5) |> map_maybe((x) => x * 2)
  println(doubled)                // Some(10)

  // Chain maybe-returning functions
  let parsed = Some("42") |> and_then((s) => parse_int(s))
  println(parsed)                 // Some(42)

  // Safe extraction
  println(unwrap_maybe_or(None, 0))   // 0
  println(is_some(Some(1)))           // true
}
```

## Result Combinators

| Function | Signature | Description |
|----------|-----------|-------------|
| `unwrap(r)` | `(result<a, b>) -> a` | Extract the `Ok` value, or throw on `Err` |
| `unwrap_or(r, default)` | `(result<a, b>, a) -> a` | Extract the `Ok` value, or return `default` |
| `map_result(r, f)` | `(result<a, b>, (a) -> c) -> result<c, b>` | Transform the `Ok` value; pass `Err` through |
| `map_err(r, f)` | `(result<a, b>, (b) -> c) -> result<a, c>` | Transform the `Err` value; pass `Ok` through |
| `and_then_result(r, f)` | `(result<a, b>, (a) -> result<c, b>) -> result<c, b>` | Chain a function that returns `result`; short-circuits on `Err` |
| `is_ok(r)` | `(result<a, b>) -> bool` | True if `Ok` |
| `is_err(r)` | `(result<a, b>) -> bool` | True if `Err` |

### File Helpers (`prelude/io.hc`)

Written in hica itself:

| Function | Signature | Description |
|----------|-----------|-------------|
| `read_lines(path)` | `(string) -> list<string>` | Read a file and split it into lines (throws on error) |
| `write_lines(path, lines)` | `(string, list<string>) -> ()` | Join lines with newlines and write to a file |

```rust
fun main() {
  // Write and read back
  write_file("greeting.txt", "hello, world!\n")
  let content = read_file("greeting.txt") |> unwrap
  println(content)

  // Line-oriented I/O (throws on error)
  write_lines("names.txt", ["Kalle", "Olle", "Lisa"])
  let names = read_lines("names.txt")
  for name in names {
    println("Hi, {name}!")
  }

  // Handle errors explicitly
  match read_file("missing.txt") {
    Ok(text) => println(text),
    Err(msg) => println("Could not read: {msg}")
  }

  // Provide a fallback
  let data = read_file("config.txt") |> unwrap_or("default")
  println(data)
}
}
```

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
| `head(xs)` | `(list<a>) -> maybe<a>` | First element, or `None` if empty |
| `tail(xs)` | `(list<a>) -> list<a>` | All elements except the first |
| `last(xs)` | `(list<a>) -> maybe<a>` | Last element, or `None` if empty |
| `flat_map(xs, f)` | `(list<a>, (a) -> list<b>) -> list<b>` | Map then flatten |
| `sort_by(xs, cmp)` | `(list<a>, (a, a) -> bool) -> list<a>` | Sort using a comparison; `cmp(a, b)` returns true if `a` comes first |

### List Helpers (`prelude/lists.hc`)

Written in hica itself:

| Function | Signature | Description |
|----------|-----------|-------------|
| `sum(xs)` | `(list<int>) -> int` | Sum all elements |
| `product(xs)` | `(list<int>) -> int` | Multiply all elements |
| `unique(xs)` | `(list<int>) -> list<int>` | Remove duplicates (keeps first occurrence) |
| `intersperse(xs, sep)` | `(list<a>, a) -> list<a>` | Insert `sep` between every element |
| `zip_with(xs, ys, f)` | `(list<a>, list<b>, (a, b) -> c) -> list<c>` | Zip and transform in one step |
| `scan(xs, init, f)` | `(list<a>, b, (b, a) -> b) -> list<b>` | Like `fold` but keeps all intermediate results |
| `chunks(xs, n)` | `(list<a>, int) -> list<list<a>>` | Split into groups of `n` |

```rust
fun main() {
  println(sum([1, 2, 3, 4, 5]))           // 15
  println(sort_by([3, 1, 4], (a, b) => a <= b))  // [1, 3, 4]
  println(unique([1, 2, 3, 2, 1]))        // [1, 2, 3]
  println(chunks([1, 2, 3, 4, 5], 2))     // [[1, 2], [3, 4], [5]]
  println(head([10, 20, 30]))             // Some(10)
  println(last([10, 20, 30]))             // Some(30)
  println(flat_map([1, 2, 3], (x) => [x, x * 10]))  // [1, 10, 2, 20, 3, 30]
}
```

## Map Operations

Maps use `{"key": value}` syntax and are represented as `list<(k, v)>`. Use `{:}` for an empty map.

| Function | Signature | Description |
|----------|-----------|-------------|
| `map_get(m, key)` | `(list<(k, v)>, k) -> maybe<v>` | Look up a key |
| `map_set(m, key, value)` | `(list<(k, v)>, k, v) -> list<(k, v)>` | Add or update a key |
| `map_remove(m, key)` | `(list<(k, v)>, k) -> list<(k, v)>` | Remove a key |
| `map_keys(m)` | `(list<(k, v)>) -> list<k>` | All keys |
| `map_values(m)` | `(list<(k, v)>) -> list<v>` | All values |
| `map_contains_key(m, key)` | `(list<(k, v)>, k) -> bool` | Check if a key exists |
| `map_size(m)` | `(list<(k, v)>) -> int` | Number of entries |

```rust
fun main() {
  let scores = {"kalle": 95, "olle": 87}
  println(scores.map_get("kalle"))       // Just(95)

  let scores2 = scores.map_set("lisa", 92)
  println(scores2.map_keys())            // ["kalle", "olle", "lisa"]

  let scores3 = scores2.map_remove("olle")
  println(scores3.map_size())            // 2
}
```

Since maps are lists of tuples, all list operations (`filter`, `map`, `fold`, etc.) work on them too.

## Random Numbers

| Function | Signature | Description |
|----------|-----------|-------------|
| `random(min, max)` | `(int, int) -> int` | Random integer in `[min, max]`, both ends included |

Using `random` gives your program the `ndet` (non-determinism) effect.

```rust
fun main() {
  let die = random(1, 6)
  println("You rolled a {die}")
}
```

## Bitwise Operations

Bitwise functions operate on 32-bit integers internally. Values are converted from hica's arbitrary-precision `int` to `int32`, the operation is applied, and the result is converted back.

| Function | Signature | Description |
|----------|-----------|-------------|
| `bit_and(a, b)` | `(int, int) -> int` | Bitwise AND |
| `bit_or(a, b)` | `(int, int) -> int` | Bitwise OR |
| `bit_xor(a, b)` | `(int, int) -> int` | Bitwise XOR |
| `bit_not(a)` | `(int) -> int` | Bitwise complement (flip all bits) |
| `bit_shl(a, n)` | `(int, int) -> int` | Shift left by `n` bits |
| `bit_shr(a, n)` | `(int, int) -> int` | Shift right by `n` bits |

```rust
fun main() {
  let flags = 0b1010_1100
  let masked = bit_and(flags, 0x0F)   // keep low nibble → 12
  println(masked)

  // UFCS / dot-call style
  let shifted = flags.bit_shr(4)       // → 10
  println(shifted)
}
```

**32-bit constraint:** Values are clamped to the `int32` range (−2,147,483,648 to 2,147,483,647). Suitable for flags, masks, and protocol work.

## Formatting

| Function | Signature | Description |
|----------|-----------|-------------|
| `show_fixed(value, decimals)` | `(float, int) -> string` | Format a float with a fixed number of decimal places |

```rust
fun main() {
  println(show_fixed(3.14159, 2))  // "3.14"
  println(show_fixed(100.0 / 3.0, 1))  // "33.3"
}
```

## User Input

| Function | Signature | Description |
|----------|-----------|-------------|
| `input(prompt)` | `(string) -> string` | Display a prompt and read a line from stdin |

```rust
fun main() {
  let name = input("What is your name? ")
  println("Hello, {name}!")
}
```

## Math (`prelude/math.hc`)

Written in hica itself:

| Function | Signature | Description |
|----------|-----------|-------------|
| `abs(n)` | `(int) -> int` | Absolute value |
| `min(a, b)` | `(int, int) -> int` | Smaller of two values |
| `max(a, b)` | `(int, int) -> int` | Larger of two values |
| `clamp(v, lo, hi)` | `(int, int, int) -> int` | Constrain `v` to the range `[lo, hi]` |
| `gcd(a, b)` | `(int, int) -> int` | Greatest common divisor |
| `lcm(a, b)` | `(int, int) -> int` | Least common multiple |
| `pow(base, exp)` | `(int, int) -> int` | Integer exponentiation |
| `sign(n)` | `(int) -> int` | Returns -1, 0, or 1 |

## Float Math

| Function | Signature | Description |
|----------|-----------|-------------|
| `sqrt(x)` | `(float) -> float` | Square root |
| `floor(x)` | `(float) -> int` | Round down to integer |
| `ceil(x)` | `(float) -> int` | Round up to integer |
| `round(x)` | `(float) -> int` | Round to nearest integer |
| `to_float(n)` | `(int) -> float` | Convert integer to float |

```rust
fun main() {
  println(sqrt(16.0))     // 4.0
  println(floor(3.7))     // 3
  println(ceil(3.2))      // 4
  println(round(3.5))     // 4
  println(to_float(42))   // 42.0
  println(pow(2, 10))     // 1024
  println(lcm(12, 18))    // 36
}
```

## Char / String Conversions

| Function | Signature | Description |
|----------|-----------|-------------|
| `chars(s)` | `(string) -> list<char>` | Convert a string to a list of characters |
| `from_chars(cs)` | `(list<char>) -> string` | Convert a list of characters back to a string |
| `chr(code)` | `(int) -> char` | Construct a char from a Unicode code point |
| `ord(c)` | `(char) -> int` | Get the Unicode code point of a char |
| `char_to_string(c)` | `(char) -> string` | Convert a single char to a string |

```rust
fun main() {
  let cs = chars("hello")
  println(cs)              // ['h', 'e', 'l', 'l', 'o']
  println(from_chars(cs))  // "hello"

  // Construct chars from code points
  println(chr(65))         // A
  println(ord('A'))        // 65

  // Build strings from code points
  let hi = from_chars([chr(72), chr(105)])
  println(hi)              // Hi
}
```

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
| `parse_int(s)` | `(string) -> maybe<int>` | Parse string as integer, returning `None` if invalid |
| `parse_float(s)` | `(string) -> maybe<float>` | Parse string as float, returning `None` if invalid |

### String Comparison

Strings support `<`, `>`, `<=`, `>=` for lexicographic comparison:

```rust
fun main() {
  println("apple" < "banana")   // true
  println("zoo" > "abc")        // true
  println("abc" <= "abc")       // true
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
  let s = "hello"
  println(s[0])      // 'h'
  println(s[1:4])    // "ell"
  println(s[:3])     // "hel"
  println(s[-1])     // 'o'
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
| `capitalise(s)` | `(string) -> string` | Uppercase first letter, lowercase rest |
| `capwords(s)` | `(string) -> string` | Capitalise each word |
| `removeprefix(s, pre)` | `(string, string) -> string` | Remove prefix if present |
| `removesuffix(s, suf)` | `(string, string) -> string` | Remove suffix if present |

## Examples

### Map and filter

```rust
fun main() {
  let nums = [1, 2, 3, 4, 5]
  let evens = filter(nums, (x) => x % 2 == 0)
  let doubled = map(nums, (x) => x * 2)
  println(evens)
  println(doubled)
}
```

### Fold

```rust
fun main() {
  let nums = [1, 2, 3, 4, 5]
  let total = fold(nums, 0, (acc, x) => acc + x)
  println(total)
}
```

### Pipe and dot-call with standard library

Both `|>` and dot-call syntax work with any standard library function:

```rust
fun main() {
  // Pipe style
  let a = [1, 2, 3, 4, 5]
    |> filter((x) => x % 2 == 0)
    |> map((x) => x * 10)
    |> fold(0, (acc, x) => acc + x)
  println(a)

  // Dot-call style (equivalent)
  let b = [1, 2, 3, 4, 5]
    .filter((x) => x % 2 == 0)
    .map((x) => x * 10)
    .fold(0, (acc, x) => acc + x)
  println(b)
}
```

### String operations

```rust
fun main() {
  let msg = "  Hello, World!  "
  println(trim(msg))
  println(to_upper(trim(msg)))
  println(contains(msg, "World"))

  let csv = "kalle,olle,lisa"
  println(split(csv, ","))
  println(join(split(csv, ","), " & "))
  println(replace(csv, ",", " | "))
}
```

### String helpers from prelude

```rust
fun main() {
  println(words("the  quick   fox"))
  println(pad_left("42", 6, "0"))
  println(surround("hello", "**"))
}
```
