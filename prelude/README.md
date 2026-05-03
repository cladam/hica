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
| `show(n)` | `(a) -> string` | Convert a value to its string representation |

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

### `operators.hc` — operators as functions

Inspired by Python's [`operator`](https://docs.python.org/3/library/operator.html)
module. Wraps built-in operators as named functions so they can be passed to
`fold`, `map`, `filter`, etc.

Written in Hica. Source: [`prelude/operators.hc`](operators.hc)

#### Arithmetic

| Function | Signature | Description |
|----------|-----------|-------------|
| `add(a, b)` | `(int, int) -> int` | `a + b` |
| `sub(a, b)` | `(int, int) -> int` | `a - b` |
| `mul(a, b)` | `(int, int) -> int` | `a * b` |
| `div(a, b)` | `(int, int) -> int` | `a / b` |
| `mod(a, b)` | `(int, int) -> int` | `a % b` |
| `neg(n)` | `(int) -> int` | `-n` |
| `square(n)` | `(int) -> int` | `n * n` |

#### Comparison

| Function | Signature | Description |
|----------|-----------|-------------|
| `lt(a, b)` | `(int, int) -> bool` | `a < b` |
| `le(a, b)` | `(int, int) -> bool` | `a <= b` |
| `gt(a, b)` | `(int, int) -> bool` | `a > b` |
| `ge(a, b)` | `(int, int) -> bool` | `a >= b` |

#### Logical

| Function | Signature | Description |
|----------|-----------|-------------|
| `not_(b)` | `(bool) -> bool` | `!b` |
| `and_(a, b)` | `(bool, bool) -> bool` | `a && b` |
| `or_(a, b)` | `(bool, bool) -> bool` | `a \|\| b` |

#### Predicates

| Function | Signature | Description |
|----------|-----------|-------------|
| `is_positive(n)` | `(int) -> bool` | `n > 0` |
| `is_negative(n)` | `(int) -> bool` | `n < 0` |
| `is_zero(n)` | `(int) -> bool` | `n == 0` |
| `is_even(n)` | `(int) -> bool` | `n % 2 == 0` |
| `is_odd(n)` | `(int) -> bool` | `n % 2 != 0` |

#### Utility

| Function | Signature | Description |
|----------|-----------|-------------|
| `identity(x)` | `(a) -> a` | Return the value unchanged |

### `strings.hc` — string helpers

Higher-level string functions built on top of the string primitives.

Written in Hica. Source: [`prelude/strings.hc`](strings.hc)

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

## How to add a prelude function

**1. Write your function in a `.hc` file inside `prelude/`.**

Use any Hica feature that the compiler already supports. Prelude files go
through the same pipeline as user code: lex → parse → check → emit.

```hica
// prelude/math.hc
fun square(n) => n * n
```

**2. Register the file in `src/main.kk`.**

Add your file to the `prelude-files` list:

```koka
val prelude-files = ["prelude/math.hc"]
```

**3. Run the tests.**

```sh
koka -ilib/kunit -ilib/klap -isrc -e tests/test-codegen.kk
```

That's it. The function is now available to every Hica program.

## How it works

When the compiler processes a user's `.hc` file, it:

1. Reads and parses every file listed in `prelude-files`
2. Prepends the prelude declarations before the user's declarations
3. Type-checks the combined program (prelude + user code)
4. Emits Koka code for everything — prelude functions appear at the top of
   the generated `.kk` file

Because prelude functions are user-declared, they get the `hc_` name prefix
in generated Koka code (e.g. `abs` → `hc_abs`). This avoids clashing with
Koka's own stdlib. Extern functions like `println` pass through unchanged.

## Design principles

- **Written in Hica** — if a function *can* be expressed in Hica, it
  *should* be. Only I/O and polymorphic built-ins use extern signatures.
- **No magic** — prelude functions are ordinary Hica code. They follow the
  same rules, get the same type checking, and produce the same errors.
- **Small and focused** — include only universally useful functions. Domain-
  specific helpers belong in user code, not the prelude.
- **Anyone can contribute** — adding a function is just writing Hica code
  and adding a line to a list.

## Ideas for future prelude functions

These are candidates once the language adds the necessary features:

| Function | Needs | Description |
|----------|-------|-------------|
| `sign(n)` | — | Return -1, 0, or 1 |
| `sum(xs)` | — | Sum a list of integers (can use `fold(xs, 0, add)` today) |
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

The goal isn't to match their size — it's to notice the patterns. The
functions that appear in *all* of these libraries (`abs`, `min`, `max`,
`print`, `len`, `map`, `filter`) are the ones users expect to just work.
