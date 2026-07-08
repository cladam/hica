---
layout: default
title: Standard Library - hica
---

# Standard Library

hica's standard library has two layers:

- **Prelude** (`math.hc`, `glob.hc`, `strings.hc`) – always available, no import needed.
- **Stdlib modules** (`std/io`, `std/datetime`, `std/list`, `std/string`, `std/ops`, `std/cli`, `std/actor`, `std/term`, `std/env`, `std/dotenv`, `std/trusted`) – opt-in via `import "std/..."`.

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
| `set_env(key, value)` | `(string, string) -> ()` | Set an environment variable (overwrites existing) |
| `exit(code)` | `(int) -> ()` | Exit the process with the given exit code |

### Environment Helpers (`std/env`, `import "std/env"` required)

| Function | Signature | Description |
|----------|-----------|-------------|
| `env_or(key, default)` | `(string, string) -> string` | Look up env var; return `default` if missing |
| `env_require(key)` | `(string) -> string` | Look up env var; print error and return `""` if missing |
| `env_int(key)` | `(string) -> maybe<int>` | Look up env var and parse as int; `None` if missing or non-numeric |

```hica
import "std/env"

fun main() {
  let host = env_or("HOST", "localhost")
  let port = env_int("PORT")             // maybe<int>
  println("Connecting to {host}")
  match port {
    Some(p) => println("port: {p}"),
    None => println("port not set")
  }
}
```

### .env File Support (`std/dotenv`, `import "std/dotenv"` required)

Reads `.env` files and loads key=value pairs into the process environment.

| Function | Signature | Description |
|----------|-----------|-------------|
| `dotenv_load(path)` | `(string) -> ()` | Load a `.env` file; skip vars already set in environment |
| `dotenv_load_override(path)` | `(string) -> ()` | Load a `.env` file; overwrite existing environment variables |
| `dotenv_parse(content)` | `(string) -> list<(string, string)>` | Parse `.env` format string into key/value pairs |
| `dotenv_apply(pairs)` | `(list<(string, string)>) -> ()` | Set env vars from a list; skip already-set keys |
| `dotenv_apply_override(pairs)` | `(list<(string, string)>) -> ()` | Set env vars from a list; overwrite existing keys |

Supported `.env` format:
- `KEY=value` — plain value
- `KEY="quoted value"` — double-quoted (quotes stripped)
- `KEY='single quoted'` — single-quoted (quotes stripped)
- `export KEY=value` — optional `export` prefix
- `# comment` — lines starting with `#` are ignored

```hica
import "std/dotenv"
import "std/env"

fun main() {
  dotenv_load(".env")             // load .env; don't overwrite existing vars
  let db = env_or("DB_URL", "sqlite://dev.db")
  let port = env_or("PORT", "3000")
  println("DB: {db}")
  println("PORT: {port}")
}
```

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

```hica
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

### File Helpers (`std/io`, `import "std/io"` required)

Written in hica itself:

| Function | Signature | Description |
|----------|-----------|-------------|
| `read_lines(path)` | `(string) -> list<string>` | Read a file and split it into lines (throws on error) |
| `write_lines(path, lines)` | `(string, list<string>) -> ()` | Join lines with newlines and write to a file |

```hica
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
```

## List Operations

| Function | Signature | Description |
|----------|-----------|-------------|
| `map(xs, f)` | `(list<a>, (a) -> b) -> list<b>` | Apply `f` to each element |
| `filter(xs, f)` | `(list<a>, (a) -> bool) -> list<a>` | Keep elements where `f` returns true |
| `fold(xs, init, f)` | `(list<a>, b, (b, a) -> b) -> b` | Reduce a list to a single value |
| `length(xs)` | `(list<a>) -> int` | Length of a list (also works on strings: `length(s)`) |
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

### List Helpers (`std/list`, `import "std/list"` required)

Written in hica itself:

| Function | Signature | Description |
|----------|-----------|-------------|
| `range(lo, hi)` | `(int, int) -> list<int>` | Integers from `lo` up to (not including) `hi` — Python-style half-open range |
| `range_inc(lo, hi)` | `(int, int) -> list<int>` | Integers from `lo` to `hi` inclusive |
| `sum(xs)` | `(list<int>) -> int` | Sum all elements |
| `product(xs)` | `(list<int>) -> int` | Multiply all elements |
| `unique(xs)` | `(list<int>) -> list<int>` | Remove duplicates (keeps first occurrence) |
| `intersperse(xs, sep)` | `(list<a>, a) -> list<a>` | Insert `sep` between every element |
| `zip_with(xs, ys, f)` | `(list<a>, list<b>, (a, b) -> c) -> list<c>` | Zip and transform in one step |
| `scan(xs, init, f)` | `(list<a>, b, (b, a) -> b) -> list<b>` | Like `fold` but keeps all intermediate results |
| `chunks(xs, n)` | `(list<a>, int) -> list<list<a>>` | Split into groups of `n` |
| `head_or(xs, default)` | `(list<a>, a) -> a` | First element or `default` if the list is empty |
| `take_while(xs, pred)` | `(list<a>, (a) -> bool) -> list<a>` | Take elements from the front while predicate holds |
| `drop_while(xs, pred)` | `(list<a>, (a) -> bool) -> list<a>` | Drop elements from the front while predicate holds |
| `count(xs, pred)` | `(list<a>, (a) -> bool) -> int` | Count elements matching the predicate |
| `group_by(xs, f)` | `(list<a>, (a) -> string) -> list<(string, list<a>)>` | Group elements by a string key function; preserves insertion order |
| `min_by(xs, f)` | `(list<a>, (a) -> int) -> maybe<a>` | Element with the smallest int key; `None` on empty list |
| `max_by(xs, f)` | `(list<a>, (a) -> int) -> maybe<a>` | Element with the largest int key; `None` on empty list |

```hica
fun main() {
  println(range(0, 5))                      // [0, 1, 2, 3, 4]
  println(range_inc(1, 5))                   // [1, 2, 3, 4, 5]
  println(sum([1, 2, 3, 4, 5]))           // 15
  println(sort_by([3, 1, 4], (a, b) => a <= b))  // [1, 3, 4]
  println(unique([1, 2, 3, 2, 1]))        // [1, 2, 3]
  println(chunks([1, 2, 3, 4, 5], 2))     // [[1, 2], [3, 4], [5]]
  println(head([10, 20, 30]))             // Some(10)
  println(last([10, 20, 30]))             // Some(30)
  println(flat_map([1, 2, 3], (x) => [x, x * 10]))  // [1, 10, 2, 20, 3, 30]
  println(head_or([], 0))                 // 0
  println(take_while([1,2,3,4,5], (n) => n < 4))  // [1, 2, 3]
  println(drop_while([1,2,3,4,5], (n) => n < 4))  // [4, 5]
  println(count([1,2,3,4,5], (n) => n % 2 == 0))  // 2
  let gs = group_by(["cat","cup","dog"], (w) => w[0:1])
  println(length(gs))                     // 2 groups: "c", "d"
  let words = ["hi", "hello", "hey"]
  match min_by(words, (s) => str_length(s)) {
    Some(w) => println(w),               // hi
    None => println("empty")
  }
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

```hica
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
| `random_float()` | `() -> float` | Random float in `[0.0, 1.0)` |

Using `random` or `random_float` gives your program the `ndet` (non-determinism) effect.

## System Clock

| Function | Signature | Description |
|----------|-----------|-------------|
| `now_unix()` | `() -> int` | Current UTC time as a Unix epoch timestamp (seconds since 1970-01-01) |
| `now_iso()` | `() -> string` | Current UTC time as an ISO 8601 string (e.g. `"2026-05-26T21:30:16Z"`) |
| `unix_to_iso(epoch)` | `(int) -> string` | Convert a Unix epoch integer to an ISO 8601 UTC string |

Backed by Koka's `std/time` library. Using any of these gives your program the `ndet` effect.

```hica
fun main() {
  let t = now_unix()
  let s = now_iso()
  println("epoch: {t}")
  println("iso:   {s}")
  println(unix_to_iso(1716800000))   // "2024-05-27T08:53:20Z"
}
```

See also the epoch/duration helpers in `std/datetime` for working with stored timestamps.

```hica
fun main() {
  let die = random(1, 6)
  println("You rolled a {die}")
  let f = random_float()
  println(f >= 0.0 && f < 1.0)   // true
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

```hica
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

```hica
fun main() {
  println(show_fixed(3.14159, 2))  // "3.14"
  println(show_fixed(100.0 / 3.0, 1))  // "33.3"
}
```

## User Input

| Function | Signature | Description |
|----------|-----------|-------------|
| `input(prompt)` | `(string) -> string` | Display a prompt and read a line from stdin |

```hica
fun main() {
  let name = input("What is your name? ")
  println("Hello, {name}!")
}
```

## Math (`prelude/math.hc`)

Always available with no import needed. Written in hica itself:

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
| `isqrt(n)` | `(int) -> int` | Integer square root, floor of √n |

## Float Math

| Function | Signature | Description |
|----------|-----------|-------------|
| `sqrt(x)` | `(float) -> float` | Square root |
| `floor(x)` | `(float) -> int` | Round down to integer |
| `ceil(x)` | `(float) -> int` | Round up to integer |
| `round(x)` | `(float) -> int` | Round to nearest integer |
| `to_float(n)` | `(int) -> float` | Convert integer to float |

```hica
fun main() {
  println(sqrt(16.0))     // 4.0
  println(floor(3.7))     // 3
  println(ceil(3.2))      // 4
  println(round(3.5))     // 4
  println(to_float(42))   // 42.0
  println(pow(2, 10))     // 1024
  println(lcm(12, 18))    // 36
  println(isqrt(25))      // 5
  println(isqrt(26))      // 5
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

```hica
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
| `str_contains(s, sub)` | `(string, string) -> bool` | Alias for `contains` |
| `starts_with(s, pre)` | `(string, string) -> bool` | True if `s` starts with `pre` |
| `ends_with(s, suf)` | `(string, string) -> bool` | True if `s` ends with `suf` |
| `trim(s)` | `(string) -> string` | Remove leading and trailing whitespace |
| `trim_start(s)` | `(string) -> string` | Remove leading whitespace |
| `trim_end(s)` | `(string) -> string` | Remove trailing whitespace |
| `to_upper(s)` | `(string) -> string` | Convert to uppercase |
| `to_lower(s)` | `(string) -> string` | Convert to lowercase |
| `split(s, sep)` | `(string, string) -> list<string>` | Split a string by separator. Empty separator splits into individual characters |
| `replace(s, old, new)` | `(string, string, string) -> string` | Replace all occurrences |
| `join(xs, sep)` | `(list<string>, string) -> string` | Join a list of strings with separator |
| `index_of(s, sub)` | `(string, string) -> maybe<int>` | Index of first occurrence of `sub`, or `None` |
| `to_int(s)` | `(string) -> int` | Parse string as integer (-1 if invalid) |
| `parse_int(s)` | `(string) -> maybe<int>` | Parse string as integer, returning `None` if invalid |
| `parse_float(s)` | `(string) -> maybe<float>` | Parse string as float, returning `None` if invalid |

### String Comparison

Strings support `<`, `>`, `<=`, `>=` for lexicographic comparison:

```hica
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

```hica
fun main() {
  let s = "hello"
  println(s[0])      // 'h'
  println(s[1:4])    // "ell"
  println(s[:3])     // "hel"
  println(s[-1])     // 'o'
}
```

## String Helpers (`prelude/strings.hc`)

Always available with no import needed. Written in hica itself:

| Function | Signature | Description |
|----------|-----------|-------------|
| `is_empty(s)` | `(string) -> bool` | True if the string has zero length (also works on lists: `is_empty(xs)`) |
| `is_blank(s)` | `(string) -> bool` | True if the string is empty after trimming |
| `words(s)` | `(string) -> list<string>` | Split on spaces, removing empty parts |
| `lines(s)` | `(string) -> list<string>` | Split on newlines |
| `unwords(ws)` | `(list<string>) -> string` | Join words with a space |
| `unlines(ls)` | `(list<string>) -> string` | Join lines with a newline |
| `repeat_str(s, n)` | `(string, int) -> string` | Repeat a string `n` times |
| `pad_left(s, width, ch)` | `(string, int, string) -> string` | Pad on the left to `width` |
| `pad_right(s, width, ch)` | `(string, int, string) -> string` | Pad on the right to `width` |
| `center(s, width, ch)` | `(string, int, string) -> string` | Center `s` in `width`, padding with `ch` |
| `removeprefix(s, pre)` | `(string, string) -> string` | Remove prefix if present |

## Trust Boundaries (`std/trusted`, `import "std/trusted"` required)

Provides the `Trusted` type: a string that has explicitly crossed a validation boundary. The constructor is private to `std/trusted`, so the only way to obtain a `Trusted` value is through one of the validators or the explicit `trust()` escape hatch. Functions that require validated data declare their parameters as `Trusted` instead of `string`, making it a compile-time error to pass a raw string.

See also: [`opaque struct` / `pub struct … priv`](/docs/language-reference#opaque-structs--type-safe-boundaries) in the language reference.

### Core

| Function | Signature | Description |
|----------|-----------|-------------|
| `trust(s)` | `(string) -> Trusted` | Explicit trust marker — wrap a string you have manually verified is safe |
| `trusted_value(t)` | `(Trusted) -> string` | Unwrap the inner string from a `Trusted` value |

### Validators

Each validator returns `Some(Trusted)` on success, `None` on failure.

| Function | Signature | Description |
|----------|-----------|-------------|
| `validate_nonempty(s)` | `(string) -> maybe<Trusted>` | Accept any non-empty string |
| `validate_maxlen(s, n)` | `(string, int) -> maybe<Trusted>` | Accept strings whose length does not exceed `n` |
| `validate_alnum(s)` | `(string) -> maybe<Trusted>` | Accept non-empty strings containing only `[A-Za-z0-9]` |
| `validate_with(s, pred)` | `(string, (string) -> bool) -> maybe<Trusted>` | Accept strings that satisfy a custom predicate |

### Combinators

| Function | Signature | Description |
|----------|-----------|-------------|
| `validate_and(a, b)` | `(maybe<Trusted>, maybe<Trusted>) -> maybe<Trusted>` | Both validators must pass |
| `trusted_or(t, fallback)` | `(maybe<Trusted>, string) -> Trusted` | Unwrap or use fallback (the fallback is implicitly trusted) |

```hica
import "std/trusted"

// Only Trusted values may reach this function — enforced at compile time.
fun audit_log(event: string, actor: Trusted) {
  println("[AUDIT] " + event + " actor=" + trusted_value(actor))
}

fun handle_request(raw_actor: string) {
  let actor = validate_and(
    validate_nonempty(raw_actor),
    validate_alnum(raw_actor)        // rejects spaces, control chars, metacharacters
  )
  match actor {
    Some(a) => audit_log("login", a),
    None    => println("rejected: invalid actor")
  }

  // This does NOT compile — raw string cannot be passed where Trusted is required:
  // audit_log("login", raw_actor)
}
```

## Extended String Helpers (`std/string`, `import "std/string"` required)

Written in hica itself:

| Function | Signature | Description |
|----------|-----------|-------------|
| `count_substr(s, sub)` | `(string, string) -> int` | Count occurrences of `sub` in `s` |
| `surround(s, wrap)` | `(string, string) -> string` | Wrap `s` with `wrap` on both sides |
| `capitalise(s)` | `(string) -> string` | Uppercase first letter, lowercase rest |
| `capwords(s)` | `(string) -> string` | Capitalise each word |
| `shout(s)` | `(string) -> string` | Convert to uppercase and append `!` |
| `removesuffix(s, suf)` | `(string, string) -> string` | Remove suffix if present |

## Glob & Character Classification (`prelude/glob.hc`)

Always available with no import needed. Written in hica itself. Provides character-level classification and glob pattern matching.

### Character Classification

| Function | Signature | Description |
|----------|-----------|-------------|
| `is_digit(c)` | `(char) -> bool` | True if `c` is `0`–`9` |
| `is_upper(c)` | `(char) -> bool` | True if `c` is `A`–`Z` |
| `is_lower(c)` | `(char) -> bool` | True if `c` is `a`–`z` |
| `is_alpha(c)` | `(char) -> bool` | True if `c` is a letter |
| `is_alnum(c)` | `(char) -> bool` | True if `c` is a letter or digit |
| `is_space(c)` | `(char) -> bool` | True if `c` is whitespace (space, tab, newline, carriage return) |
| `is_punct(c)` | `(char) -> bool` | True if `c` is punctuation (printable, non-alnum, non-space) |

### String-Level Helpers

| Function | Signature | Description |
|----------|-----------|-------------|
| `all_digits(s)` | `(string) -> bool` | True if every character is a digit |
| `all_alpha(s)` | `(string) -> bool` | True if every character is a letter |
| `all_upper(s)` | `(string) -> bool` | True if every character is uppercase |
| `all_lower(s)` | `(string) -> bool` | True if every character is lowercase |
| `all_alnum(s)` | `(string) -> bool` | True if every character is alphanumeric |

### Glob Matching

| Function | Signature | Description |
|----------|-----------|-------------|
| `glob_match(pattern, s)` | `(string, string) -> bool` | Match with `*` (any chars, not `/`) and `?` (one char) |
| `glob_match_path(pattern, path)` | `(string, string) -> bool` | Path-aware matching with `**` (zero or more directories) |

```hica
fun main() {
  // Character classification
  println(is_digit(chr(48)))          // true ('0')
  println(is_alpha(chr(65)))          // true ('A')
  println(all_digits("12345"))        // true
  println(all_upper("HELLO"))         // true

  // Simple glob
  println(glob_match("*.txt", "readme.txt"))   // true
  println(glob_match("h?llo", "hello"))        // true

  // Path glob with **
  println(glob_match_path("src/**/*.hc", "src/lib/util.hc"))   // true
  println(glob_match_path("**/*.txt", "a/b/c/file.txt"))       // true
}
```

## Datetime (`std/datetime`, `import "std/datetime"` required) — v0.1.0

> **Note:** This is a string-based datetime implementation. All datetimes are represented as plain strings in ISO 8601 format. No rich datetime types or timezone database. hica supports validation, decomposition, comparison, and epoch-based duration helpers. For obtaining the current time use the built-in `now_unix()`, `now_iso()`, and `unix_to_iso()` primitives (no import needed).

Written in hica itself. Import with `import "std/datetime"`. Supports the four ISO 8601 datetime variants:

- **Offset datetime:** `2024-05-15T07:32:00Z` or `2024-05-15T07:32:00+02:00`
- **Local datetime:** `2024-05-15T07:32:00`
- **Local date:** `2024-05-15`
- **Local time:** `07:32:00` or `07:32:00.123456`

### Validation

| Function | Signature | Description |
|----------|-----------|-------------|
| `is_valid_date(s)` | `(string) -> bool` | Validate `YYYY-MM-DD` (handles leap years) |
| `is_valid_time(s)` | `(string) -> bool` | Validate `HH:MM:SS` or `HH:MM:SS.frac` |
| `is_valid_offset(s)` | `(string) -> bool` | Validate `Z`, `+HH:MM`, or `-HH:MM` |
| `is_local_date(s)` | `(string) -> bool` | Check local date format |
| `is_local_time(s)` | `(string) -> bool` | Check local time format |
| `is_local_datetime(s)` | `(string) -> bool` | Check `YYYY-MM-DDThh:mm:ss[.frac]` |
| `is_iso_datetime(s)` | `(string) -> bool` | Check offset datetime (with `Z`/`±HH:MM`) |
| `datetime_kind(s)` | `(string) -> string` | Classify: `"local-time"`, `"local-date"`, `"local-datetime"`, `"offset-datetime"`, or `"invalid"` |

### Decomposition

| Function | Signature | Description |
|----------|-----------|-------------|
| `date_parts(s)` | `(string) -> result<(int, int, int), string>` | Decompose into `(year, month, day)` |
| `time_parts(s)` | `(string) -> result<(int, int, int), string>` | Decompose into `(hour, minute, second)` |
| `datetime_date(s)` | `(string) -> result<string, string>` | Extract the date portion |
| `datetime_time(s)` | `(string) -> result<string, string>` | Extract the time portion (offset stripped) |
| `datetime_offset(s)` | `(string) -> maybe<string>` | Extract the offset, or `None` for local |

### Comparison

| Function | Signature | Description |
|----------|-----------|-------------|
| `date_cmp(d1, d2)` | `(string, string) -> int` | Returns -1, 0, or 1 |
| `time_cmp(t1, t2)` | `(string, string) -> int` | Returns -1, 0, or 1 |
| `datetime_cmp(d1, d2)` | `(string, string) -> int` | Compare local datetimes; returns -1, 0, or 1 |
| `is_before(d1, d2)` | `(string, string) -> bool` | Works on dates, times, and local datetimes |

### Offset & Weekday

| Function | Signature | Description |
|----------|-----------|-------------|
| `offset_to_minutes(s)` | `(string) -> result<int, string>` | `"+02:00"` → `120`, `"Z"` → `0` |
| `day_of_week(s)` | `(string) -> result<string, string>` | Returns `"monday"` through `"sunday"` |

### Epoch & Duration

Work with Unix epoch timestamps obtained from `now_unix()`. No import is needed for `now_unix()`/`now_iso()`/`unix_to_iso()` — they are built-in.

| Function | Signature | Description |
|----------|-----------|-------------|
| `secs_since(epoch)` | `(int) -> int` | Seconds elapsed since a stored epoch |
| `mins_since(epoch)` | `(int) -> int` | Minutes elapsed since a stored epoch |
| `hours_since(epoch)` | `(int) -> int` | Hours elapsed since a stored epoch |
| `days_since(epoch)` | `(int) -> int` | Days elapsed since a stored epoch |
| `is_older_than_days(epoch, days)` | `(int, int) -> bool` | True if the epoch is more than `days` days ago |
| `is_older_than_hours(epoch, hours)` | `(int, int) -> bool` | True if the epoch is more than `hours` hours ago |
| `secs_diff(a, b)` | `(int, int) -> int` | Absolute difference in seconds between two epochs |
| `days_diff(a, b)` | `(int, int) -> int` | Absolute difference in days between two epochs |

### Date String → Epoch

Convert a calendar date into a Unix epoch so you can store and compare it using the duration helpers above.

| Function | Signature | Description |
|----------|-----------|-------------|
| `date_to_unix(s)` | `(string) -> int` | Parse `"YYYY-MM-DD"` and return the Unix epoch at midnight UTC; returns `-1` for invalid or pre-1970 dates |

```hica
import "std/datetime"

fun main() {
  let deadline = date_to_unix("2026-12-31")
  let release  = date_to_unix("2024-01-01")
  println(days_since(release))                    // days since release
  println(is_older_than_days(deadline, 365))      // false — still in the future
  println(days_diff(deadline, date_to_unix("2026-01-01")))  // 364
}
```

```hica
import "std/datetime"

fun main() {
  let created_at = now_unix() - 7300   // simulate a 2-hour-old record
  println(hours_since(created_at))           // 2
  println(is_older_than_hours(created_at, 1)) // true
  let updated_at = now_unix() - 172800
  println(days_diff(now_unix(), updated_at))  // 2
}
```

### Internal Helpers

These are implementation details exposed as `pub` due to hica's flat module model. They are available after `import "std/datetime"` but are not part of the stable public API:

| Function | Signature | Description |
|----------|-----------|-------------|
| `all_digits(s)` | `(string) -> bool` | True if every character is a digit |
| `in_range(n, lo, hi)` | `(int, int, int) -> bool` | Inclusive range check |
| `days_in_month(year, month)` | `(int, int) -> int` | Days in a month (handles leap years) |
| `parse_part(s, start, len)` | `(string, int, int) -> maybe<int>` | Parse substring as integer |
| `is_valid_time_short(s)` | `(string) -> bool` | Validate `HH:MM` (no seconds) |
| `is_valid_time_full(s)` | `(string) -> bool` | Validate `HH:MM:SS[.frac]` |
| `check_z_offset(rest)` | `(string) -> bool` | Validate time+`Z`/`z` suffix |
| `check_numeric_offset(rest)` | `(string) -> bool` | Validate time+`±HH:MM` suffix |
| `strip_offset(rest)` | `(string) -> string` | Strip offset suffix from time string |
| `list_int_nth(xs, i)` | `(list<int>, int) -> int` | Lookup by index with 0 default |

```hica
import "std/datetime"

fun main() {
  println(datetime_kind("07:32:00"))                // "local-time"

  // Decompose a date
  match date_parts("2024-05-15") {
    Ok(parts) => println("{parts.0}-{parts.1}-{parts.2}"),
    Err(e) => println(e)
  }

  // Compare dates
  println(is_before("2024-01-01", "2024-12-31"))    // true

  // Offset conversion
  match offset_to_minutes("+05:30") {
    Ok(m) => println(m),   // 330
    Err(e) => println(e)
  }

  // Weekday
  match day_of_week("2026-05-15") {
    Ok(d) => println(d),   // "friday"
    Err(e) => println(e)
  }
}
```

## Examples

### Map and filter

```hica
fun main() {
  let nums = [1, 2, 3, 4, 5]
  let evens = filter(nums, (x) => x % 2 == 0)
  let doubled = map(nums, (x) => x * 2)
  println(evens)
  println(doubled)
}
```

### Fold

```hica
fun main() {
  let nums = [1, 2, 3, 4, 5]
  let total = fold(nums, 0, (acc, x) => acc + x)
  println(total)
}
```

### Pipe and dot-call with standard library

Both `|>` and dot-call syntax work with any standard library function:

```hica
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

```hica
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

```hica
fun main() {
  println(words("the  quick   fox"))
  println(pad_left("42", 6, "0"))
  println(surround("hello", "**"))
}
```
