# Hica Prelude

The prelude is Hica's built-in standard library. Every function defined here
is automatically available in every Hica program — no imports needed.

This is how Hica bootstraps itself: the standard library is written *in Hica*.

## What's included

### Extern functions (Koka built-ins)

These functions are provided by the Koka runtime and cannot be written in
Hica. Their type signatures are declared in the compiler
(`src/semantics/prelude.kk`).

#### I/O & display

| Function | Signature | Description |
|----------|-----------|-------------|
| `println(s)` | `(a) -> ()` | Print a value to stdout with a newline |
| `eprintln(s)` | `(a) -> ()` | Print a value to stderr with a newline |
| `show(n)` | `(a) -> string` | Convert a value to its string representation |
| `show_fixed(v, n)` | `(float, int) -> string` | Format a float with `n` decimal places |

#### File I/O

| Function | Signature | Description |
|----------|-----------|-------------|
| `read_file(path)` | `(string) -> result<string, string>` | Read entire file; returns `Ok(content)` or `Err(message)` |
| `write_file(path, content)` | `(string, string) -> ()` | Write a string to a file (throws on error) |

#### User input

| Function | Signature | Description |
|----------|-----------|-------------|
| `input(prompt)` | `(string) -> string` | Display a prompt and read a line from stdin |

#### Random numbers

| Function | Signature | Description |
|----------|-----------|-------------|
| `random(min, max)` | `(int, int) -> int` | Random integer in `[min, max]` — both ends included |

#### Environment

| Function | Signature | Description |
|----------|-----------|-------------|
| `get_args()` | `() -> list<string>` | Command-line arguments (excluding the program name) |
| `get_env(key)` | `(string) -> maybe<string>` | Look up an environment variable; returns `Some(value)` or `None` |

#### Result combinators

| Function | Signature | Description |
|----------|-----------|-------------|
| `unwrap(r)` | `(result<a, b>) -> a` | Extract the `Ok` value, or throw on `Err` |
| `unwrap_or(r, default)` | `(result<a, b>, a) -> a` | Extract the `Ok` value, or return `default` |

#### List operations

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

#### String operations

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
| `split(s, sep)` | `(string, string) -> list<string>` | Split a string by separator |
| `replace(s, old, new)` | `(string, string, string) -> string` | Replace all occurrences |
| `join(xs, sep)` | `(list<string>, string) -> string` | Join a list of strings with separator |

### `math.hc` — numeric helpers

Written in Hica. Source: [`prelude/math.hc`](math.hc)

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

### `strings.hc` — string helpers

Higher-level string functions built on top of the string primitives.

Written in Hica. Source: [`prelude/strings.hc`](strings.hc)

| Function | Signature | Description |
|----------|-----------|-------------|
| `is_empty(s)` | `(string) -> bool` | True if the string has zero length |
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

## Standard Library Modules (opt-in)

Functions beyond the prelude are organised into stdlib modules. Import them
explicitly when you need them:

```hica
import "std/io"       // read_lines, write_lines
import "std/datetime" // date/time validation, decomposition, comparison
import "std/list"     // sum, product, unique, intersperse, chunks, ...
import "std/string"   // capitalise, capwords, surround, removesuffix, ...
import "std/ops"      // add, sub, mul, lt, gt, is_even, identity, ...
import "std/cli"      // CLI argument parsing (flags, options, subcommands)
import "std/actor"    // process_messages (sequential actor model)
import "std/term"     // terminal colour & styling
```

See the [Standard Library reference](../docs/standard-library.md) for full
API documentation for each module.

## How to add a prelude function

**1. Write your function in a `.hc` file inside `prelude/`.**

Use any Hica feature that the compiler already supports. Prelude files go
through the same pipeline as user code: lex → parse → check → emit.

```hica
// prelude/math.hc
fun square(n) => n * n
```

**2. Register the file in `scripts/bundle-prelude.sh`.**

Add your file to the `PRELUDE_FILES` array:

```sh
PRELUDE_FILES=(
  "prelude/math.hc"
  "prelude/glob.hc"
  "prelude/strings.hc"
  "prelude/yourfile.hc"   # ← add here
)
```

**3. Rebuild the bundle and run the tests.**

```sh
bash scripts/bundle-prelude.sh
koka -ilib/kunit -ilib/klap -isrc -e tests/test-codegen.kk
```

That's it. The function is now available to every Hica program.

## How it works

When the compiler processes a user's `.hc` file, it:

1. Reads and parses every file listed in `scripts/bundle-prelude.sh` (embedded at build time)
2. Prepends the prelude declarations before the user's declarations
3. Type-checks the combined program (prelude + user code)
4. Emits Koka code for everything — prelude functions appear at the top of
   the generated `.kk` file

Because prelude functions are user-declared, they get the `hc_` name prefix
in generated Koka code (e.g. `abs` → `hc_abs`). This avoids clashing with
Koka's own stdlib. Extern functions like `println` pass through unchanged.

## Design principles

- **Written in hica**: if a function *can* be expressed in hica, it *should* be. 
  Only I/O and polymorphic built-ins use extern signatures.
- **No magic**: prelude functions are ordinary hica code. They follow the
  same rules, get the same type checking, and produce the same errors.
- **Small and focused**: include only universally useful functions. Domain-
  specific helpers belong in user code, not the prelude.
- **Anyone can contribute**: adding a function is just writing hica code
  and adding a line to a list.

## Ideas for future prelude functions

These are candidates for the prelude (always-available, no import needed):

| Function | Needs | Description |
|----------|-------|-------------|
| `range(a, b)` | lists, `for` loop | Generate a list from `a` to `b` |

## Inspiration

The prelude takes inspiration from the built-in standard libraries of
established languages — not to copy them, but to learn what functions
people reach for every day:

- [Python built-in functions](https://docs.python.org/3/library/functions.html) —
  `abs`, `all`, `any`, `filter`, `len`, `map`, `max`, `min`, `print`,
  `range`, `reversed`, `round`, `sorted`, `sum`, `zip`. Decades of
  refinement into ~70 functions that are always available.
- [Python `operator` module](https://docs.python.org/3/library/operator.html) —
  operators as first-class functions (`add`, `mul`, `eq`, `lt`, …). Makes
  `fold(xs, 0, add)` possible instead of `fold(xs, 0, fun(a, b) => a + b)`.
- [Go `builtin` package](https://pkg.go.dev/builtin) — minimal by design:
  `len`, `cap`, `append`, `copy`, `delete`, `make`, `new`, `print`,
  `println`, `min`, `max`. Proof that a small prelude can be powerful.
- [Kotlin standard library](https://kotlinlang.org/api/core/kotlin-stdlib/) —
  rich collection operations, scope functions (`let`, `run`, `apply`),
  and extension functions that feel built-in.

The goal isn't to match their size, it's to notice the patterns. The
functions that appear in *all* of these libraries (`abs`, `min`, `max`,
`print`, `len`, `map`, `filter`) are the ones users expect to just work.
