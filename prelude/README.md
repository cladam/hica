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

### `math.hc` — numeric helpers

Written in Hica. Source: [`prelude/math.hc`](math.hc)

| Function | Signature | Description |
|----------|-----------|-------------|
| `abs(n)` | `(int) -> int` | Absolute value |
| `min(a, b)` | `(int, int) -> int` | Smaller of two values |
| `max(a, b)` | `(int, int) -> int` | Larger of two values |
| `clamp(v, lo, hi)` | `(int, int, int) -> int` | Constrain `v` to the range `[lo, hi]` |
| `gcd(a, b)` | `(int, int) -> int` | Greatest common divisor |

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
| `is_even(n)` | modulo (`%`) | Check if a number is even |
| `is_odd(n)` | modulo (`%`) | Check if a number is odd |
| `sign(n)` | — | Return -1, 0, or 1 |
| `sum(xs)` | fold | Sum a list of integers |
| `range(a, b)` | lists, `for` loop | Generate a list from `a` to `b` |

## Inspiration

The prelude takes inspiration from the built-in standard libraries of
established languages — not to copy them, but to learn what functions
people reach for every day:

- [Python built-in functions](https://docs.python.org/3/library/functions.html) —
  `abs`, `all`, `any`, `filter`, `len`, `map`, `max`, `min`, `print`,
  `range`, `reversed`, `round`, `sorted`, `sum`, `zip`. Decades of
  refinement into ~70 functions that are always available.
- [Go `builtin` package](https://pkg.go.dev/builtin) — minimal by design:
  `len`, `cap`, `append`, `copy`, `delete`, `make`, `new`, `print`,
  `println`, `min`, `max`. Proof that a small prelude can be powerful.
- [Kotlin standard library](https://kotlinlang.org/api/core/kotlin-stdlib/) —
  rich collection operations, scope functions (`let`, `run`, `apply`),
  and extension functions that feel built-in.

The goal isn't to match their size — it's to notice the patterns. The
functions that appear in *all* of these libraries (`abs`, `min`, `max`,
`print`, `len`, `map`, `filter`) are the ones users expect to just work.
