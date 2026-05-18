---
layout: default
title: Hica for Beginners - hica
---

# Hica for Beginners

Welcome! This guide walks you through hica by building small programs, one concept at a time. By the end you'll have written functions, used pattern matching, worked with lists, and combined everything into a real program.

If you already know Python, JavaScript, or Rust, you'll feel at home quickly. If this is your first language, even better: hica was designed to be clear from the start.

## Getting started

### Prerequisites

Install [Koka](https://koka-lang.github.io/koka/doc/book.html#install) version 3.2 or newer.

### Install hica

#### Linux / macOS / Chromebook

```sh
curl -fsSL https://cladam.github.io/hica/install.sh | sh
```

This downloads the latest release binary and installs it to `~/.local/bin`.
Make sure that directory is on your `PATH`.

To install elsewhere:

```sh
curl -fsSL https://cladam.github.io/hica/install.sh | HICA_INSTALL_DIR=/usr/local/bin sh
```

#### Windows (PowerShell)

```powershell
irm https://cladam.github.io/hica/install.ps1 | iex
```

This installs hica to `%LOCALAPPDATA%\hica` and adds it to your user PATH.
Override the install directory with `$env:HICA_INSTALL_DIR`.

#### Build from source

```sh
git clone https://github.com/cladam/hica.git
cd hica
koka -O2 -ilib/klap -isrc src/main.kk -o hica
chmod +x hica
```

Verify the installation:

```sh
hica --version
```

Create a file called `hello.hc` and run it:

```sh
./hica run hello.hc
```

That's all. No project setup, no config files. One file, one command.

### Try it interactively

Don't want to create a file yet? Start the REPL and type expressions directly:

```sh
hica repl
```

```
hica=> 1 + 2
3
hica=> "hello" + " world"
hello world
hica=> let x = 10
10
hica=> x * 3
30
```

The `_` variable always holds the last result. Type `:help` for commands, `:quit` to exit.
For arrow-key history, use `rlwrap hica repl`.

---

## Your first program

```rust
fun main() {
  println("Hello, world!")
}
```

Every hica program starts at `main`. The last expression in a block is its return value, so there's no `return` keyword. That simple rule carries you a long way.

## Giving things names

Use `let` to create a variable. Variables declared with `let` are immutable: once set, they don't change:

```rust
fun main() {
  let name = "Alicia"
  let age = 15
  println("{name} is {age} years old")
}
```

When you need a variable that changes, use `var`:

```rust
fun main() {
  var count = 0
  count = count + 1
  println(count)
}
```

`let` for values that stay fixed, `var` for values that change. Both are locally scoped.

Notice the `{name}` inside the string? That's **string interpolation**. Any expression works inside the braces, so `"{2 + 2}"` prints `4`.

## Writing functions

Functions look like this:

```rust
fun add(a, b) {
  a + b
}
```

When the body is just a single expression, you can use the arrow shorthand:

```rust
fun double(x) => x * 2
fun greet(name) => "Hello, " + name
```

You don't need to write types; hica's Hindley-Milner type system infers them for you, including function arguments and return types. But you *can* add annotations when it makes things clearer or when you want the compiler to double-check your intent:

```rust
fun add(a: int, b: int) : int => a + b
```

## Testing your code

Once you've written a function, how do you know it works? Use `test` blocks. They sit right next to your functions. No separate files, no imports:

```rust
fun double(x) => x * 2

test "double works" {
  assert(double(3) == 6)
  assert_eq(double(0), 0)
}
```

Run tests with `hica test`:

```sh
./hica test my_file.hc
```

```
running 1 test(s)...

  ✓ double works

1 test(s) passed
```

When a test fails, you see exactly what went wrong:

```rust
test "oops" {
  assert_eq(double(3), 5)
}
```

```
  ✗ oops
    expected 6 but got 5
```

Here are the assertions you can use:

| Function | What it checks |
|----------|---------------|
| `assert(cond)` | `cond` is `true` |
| `assert_eq(a, b)` | `a` equals `b` |
| `assert_ne(a, b)` | `a` does not equal `b` |
| `assert_true(cond)` | same as `assert`, with a clearer failure message |
| `assert_false(cond)` | `cond` is `false` |
| `assert_contains(list, x)` | `list` contains `x` |
| `assert_empty(list)` | `list` is empty |
| `assert_not_empty(list)` | `list` has at least one element |

Get in the habit of writing tests alongside your functions. When you come back to your code later, you'll thank yourself.

## Making decisions

`if`/`else` is an expression, meaning it produces a value:

```rust
fun abs(x) => if x < 0 { -x } else { x }
```

For longer chains, use `else if`:

```rust
fun fizzbuzz(n) =>
  if n % 15 == 0 { "fizzbuzz" }
  else if n % 3 == 0 { "fizz" }
  else if n % 5 == 0 { "buzz" }
  else { "{n}" }
```

## Pattern matching

When you have several cases to check, `match` is cleaner than nested `if`/`else`:

```rust
fun describe(x) => match x {
  0 => "zero",
  1 => "one",
  _ => "many"
}
```

The `_` is a wildcard: it catches everything else. Always include one so no case is missed. If you forget, the compiler tells you exactly what's missing. For example, matching on a `Maybe` without handling `Some`:

```rust
fun main() {
  match Some(1) {
    None => "nothing"
  }
}
```

```
warning[example.hc:2:3]: non-exhaustive match: missing Some(_)
 2 |   match Some(1) {
   |   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
```

This acts as a safety net. The compiler checks that you've covered every possible case for `Maybe`, `Result`, `bool`, and other types, so bugs from unhandled branches are caught before your code runs.

### Adding conditions with guards

Sometimes the pattern alone isn't enough. Add `if` after a pattern to refine it:

```rust
fun classify(n) => match n {
  x if x < 0    => "negative",
  0             => "zero",
  x if x > 100  => "big",
  _             => "small positive"
}
```

The variable `x` is bound by the pattern and available in the guard. This is much cleaner than nested `if`/`else` chains.

### List slice patterns

You can match on the shape of a list with slice patterns. This is great for recursive functions:

```rust
fun sum(xs: list<int>) : int => match xs {
  []          => 0,
  [x, ..rest] => x + sum(rest)
}
```

`[]` matches empty, `[x]` matches exactly one element, and `[x, ..rest]` splits the list into its first element and the remainder.

## Loops

hica has five ways to repeat things:

```rust
// Count from 0 to 4
for i in 0..5 {
  println(i)
}

// Walk through a list
let names = ["Kalle", "Olle", "Lisa"]
for name in names {
  println("Hello, " + name)
}

// Do something N times
repeat(3) {
  println("tick")
}

// Loop while a condition is true
var x = 5
while x > 0 {
  println(x)
  x = x - 1
}

// Loop forever until you break
var i = 1
loop {
  if i > 1000 { break }
  i = i * 2
}
println(i)  // 1024
```

All loops support `break` to exit early and `continue` to skip to the next iteration:

```rust
for n in [1, -2, 3, -4, 5] {
  if n < 0 { continue }  // skip negatives
  println(n)
}
```

## Working with lists

Lists are ordered, homogeneous collections. The standard library gives you the usual toolkit:

```rust
fun main() {
  let nums = [1, 2, 3, 4, 5]

  let doubled = map(nums, (x) => x * 2)
  println(doubled)

  let evens = filter(nums, (x) => x % 2 == 0)
  println(evens)

  let total = fold(nums, 0, (acc, x) => acc + x)
  println(total)
}
```

### The pipe operator and dot-call syntax

hica gives you two ways to chain functions left to right. Pick whichever reads better to you. They're equivalent:

```rust
fun main() {
  // Pipe style
  let a = [1, 2, 3, 4, 5]
    |> filter((x) => x % 2 == 0)
    |> map((x) => x * 10)
    |> fold(0, (acc, x) => acc + x)
  println(a)

  // Dot-call style (same result)
  let b = [1, 2, 3, 4, 5]
    .filter((x) => x % 2 == 0)
    .map((x) => x * 10)
    .fold(0, (acc, x) => acc + x)
  println(b)
}
```

`a |> f` and `a.f()` both desugar to `f(a)`. The pipe operator doesn't take extra arguments; dot-call does: `a.f(b)` becomes `f(a, b)`.

Rule of thumb:
- Use `|>` when each step is a single-argument function: `5 |> double |> inc`
- Use `.f()` when passing additional arguments: `nums.filter((x) => x > 2).map((x) => x * 10)`

### More list tools

Beyond `map`/`filter`/`fold`, the standard library has everything you'd expect:

```rust
fun main() {
  let nums = [3, 1, 4, 1, 5]

  println(head(nums))           // Some(3)
  println(tail(nums))           // [1, 4, 1, 5]
  println(last(nums))           // Some(5)
  println(sum(nums))            // 14
  println(unique(nums))         // [3, 1, 4, 5]

  let sorted = sort_by(nums, (a, b) => a <= b)
  println(sorted)               // [1, 1, 3, 4, 5]
}
```

`head` and `last` return `Maybe` since the list might be empty. `sort_by` takes a comparison function: return `true` when the first argument should come first. See the [Standard Library](standard-library) for the full list including `flat_map`, `scan`, `chunks`, and more.

## Tuples: quick grouping

When you need to bundle two or three values together, use a tuple:

```rust
let pair = (1, "hello")
println(pair.0)   // 1
println(pair.1)   // "hello"

let (x, y) = (10, 20)
println(x + y)    // 30
```

## Structs: when tuples aren't enough

If you'd need a comment to explain what `.0` and `.1` mean, it's time for a struct:

```rust
struct Point { x: int, y: int }

fun distance_sq(p: Point) : int => p.x * p.x + p.y * p.y

fun main() {
  let p = Point { x: 3, y: 4 }
  println("distance² = {distance_sq(p)}")
}
```

Struct names start uppercase. Fields are accessed with dot notation. Functions that work with structs are just regular functions, with no methods or `self`.

Since structs are immutable, you create a modified copy with update syntax:

```rust
let moved = Point { ...p, x: 10 }   // y stays the same
```

You can also destructure structs directly in `match`:

```rust
fun classify(p: Point) : string => match p {
  Point { x: 0, y: 0 } => "origin",
  Point { x, y: 0 }    => "on x-axis",
  Point { x, y }       => "({x}, {y})"
}
```

Write just the field name to bind it as a variable. Fields you don't mention are ignored.

## Enums: when a value can be one of several things

A struct says "every value has these fields." An enum says "a value is one of these alternatives":

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

fun main() {
  let shapes = [Circle(5.0), Rect(3.0, 4.0), Point]
  for s in shapes {
    println("area: {area(s)}")
  }
}
```

Each variant can carry different data (or none at all, like `Point`). Use `match` to handle each case. The compiler warns you if you forget a variant, so you can't accidentally miss a case.

Simple enums work like named constants:

```rust
type Direction { North, South, East, West }

fun opposite(d: Direction) : Direction => match d {
  North => South,
  South => North,
  East  => West,
  West  => East
}
```

Rule of thumb:
- **Struct** → every value looks the same (AND of fields)
- **Enum** → each value is one of several alternatives (OR)

## Maps: key-value lookups

When you need to associate keys with values, like a phone book or a scoreboard then use a map:

```rust
let scores = {"kalle": 95, "olle": 87, "lisa": 92}
println(scores.map_get("kalle"))   // Just(95)
println(scores.map_get("nobody"))  // Nothing
```

Maps use curly braces with `"key": value` pairs. Use `{:}` for an empty map.

Update, add, and remove entries:

```rust
let scores2 = scores.map_set("pelle", 88)
let scores3 = scores2.map_remove("olle")
println(scores3.map_keys())   // ["kalle", "lisa", "pelle"]
```

Under the hood, maps are lists of tuples. That means all list functions (`filter`, `map`, `fold`) work on maps too:

```rust
let high_scores = scores.filter((entry) => entry.1 >= 90)
println(high_scores)   // [("kalle", 95), ("lisa", 92)]
```

| Function | What it does |
|----------|-------------|
| `map_get(m, key)` | Look up a key → `maybe<v>` |
| `map_set(m, key, val)` | Add or update a key |
| `map_remove(m, key)` | Remove a key |
| `map_keys(m)` | List of all keys |
| `map_values(m)` | List of all values |
| `map_contains_key(m, key)` | Check if a key exists |
| `map_size(m)` | Number of entries |

## User Input

`input(prompt)` prints the prompt and reads a line from your input. It returns a `string`.

```rust
let name = input("What is your name? ")
println("Hello, " + name)
```

For numbers, combine input with `parse_int` or `parse_float`:

```rust
match parse_int(input("Age: ")) {
  Some(n) => println("You are {n}"),
  None    => println("Not a number!")
}
```

## Handling missing values

Not every operation succeeds. hica has two types for this.

### Maybe: it might not be there

```rust
fun main() {
  match find([1, 3, 4, 7], (x) => x % 2 == 0) {
    Some(n) => println("Found even: {n}"),
    None    => println("No even number")
  }
}
```

### Result: it worked, or here's why it didn't

```rust
fun safe_divide(a, b) =>
  if b == 0 { Err("division by zero") }
  else { Ok(a / b) }

fun main() {
  match safe_divide(10, 3) {
    Ok(n)  => println("Result: {n}"),
    Err(e) => println("Error: " + e)
  }
}
```

### Combinators: chaining without nesting

When you have several operations that each might fail, nesting `match` gets deep. Combinators let you chain them with pipes instead:

```rust
// Transform the value inside a Maybe
let doubled = Some(5) |> map_maybe((x) => x * 2)   // Some(10)

// Chain functions that return Maybe
let parsed = Some("42") |> and_then((s) => parse_int(s))  // Some(42)

// Extract with a fallback
let n = None |> unwrap_maybe_or(0)   // 0
```

Result has its own set:

```rust
let result = safe_divide(10, 2)
  |> map_result((n) => n * 10)       // Ok(50)
  |> and_then_result((n) => safe_divide(n, 5))  // Ok(10)
```

See the [Standard Library](standard-library) for the full list.

### Parsing strings safely

`parse_int` and `parse_float` return `Maybe`, so you always know whether the conversion worked:

```rust
match parse_int("42") {
  Some(n) => println("Got: {n}"),
  None    => println("Not a number")
}
```

Guards combine naturally with parsing:

```rust
match parse_int(input) {
  Some(n) if n < 0 => println("negative"),
  Some(n)          => println("valid: {n}"),
  None             => println("not a number")
}
```

### The `?` shortcut

When a function returns `maybe`, the `?` operator saves you from writing nested matches. It unwraps `Some(v)` into `v`, or returns `None` from the enclosing function immediately:

```rust
fun add_strings(a: string, b: string) : maybe<int> {
  let x = parse_int(a)?   // None → the whole function returns None
  let y = parse_int(b)?
  Some(x + y)
}

fun main() {
  println(add_strings("3", "4"))    // Some(7)
  println(add_strings("3", "abc"))  // None
}
```

Think of `?` as asking "did this work?" If not, bail out.

## Strings

Strings support concatenation (`+`), interpolation (`{expr}`), escape sequences, indexing, and slicing:

```rust
let s = "hello"
s[0]      // 'h' (a char)
s[1:4]    // "ell" (a string)
s[-1]     // 'o' (negative indexing)
```

Use backslash escapes for special characters: `\"` for a literal quote, `\\` for a backslash, `\n` for a newline, `\t` for a tab, and `\{` / `\}` for literal braces (useful in interpolated strings):

```rust
println("She said \"hi\"")     // She said "hi"
println("line1\nline2")        // two lines
println("col1\tcol2")          // tab-separated
println("path\\to\\file")      // path\to\file
println("use \{braces\}")      // use {braces}
```

Escapes work inside interpolated strings too: `"hello, {name}!\nbye!"`.

There's a full set of utility functions: `trim`, `split`, `replace`, `to_upper`, `starts_with`, `capitalise`, `removeprefix`, and more. See the [Standard Library](/hica/docs/standard-library) for the complete list.

You can also convert between strings and character lists:

```rust
let cs = chars("hello")        // ['h', 'e', 'l', 'l', 'o']
let s = from_chars(cs)         // "hello"
```

## Math

The prelude includes common integer math (`abs`, `min`, `max`, `gcd`, `lcm`, `pow`, `sign`) and float functions (`sqrt`, `floor`, `ceil`, `round`, `to_float`):

```rust
fun main() {
  println(pow(2, 10))          // 1024
  println(sqrt(25.0))          // 5.0
  println(floor(3.7))          // 3
  let n = floor(sqrt(to_float(50)))
  println(n)                   // 7
}
```

## Closures

Functions are values. You can store them, pass them around, and return them:

```rust
fun make_adder(n) => (x) => x + n

fun main() {
  let add5 = make_adder(5)
  println(add5(10))   // 15
  println(add5(20))   // 25
}
```

The inner function `(x) => x + n` captures `n` from the enclosing scope. This is how `map`, `filter`, and `fold` work: you pass them a function and they call it for you.

## Importing modules

As your programs grow, you'll want to split code across files. Any `.hc` file can be a module. Just mark the functions you want to share with `pub`:

```rust
// helpers.hc
pub fun double(x) => x * 2
pub fun triple(x) => x * 3
fun secret() => 42   // private, not visible outside this file
```

Then import from another file:

```rust
// main.hc
import "helpers"

fun main() {
  println(double(5))   // 10
  println(triple(5))   // 15
}
```

The path is relative to the importing file, without `.hc`. Use `from ... import { }` to pick specific names:

```rust
from "helpers" import { double }

fun main() {
  println(double(5))   // works
  // triple(5)         // error: not imported
}
```

And `pub import` re-exports to your own importers, handy for building libraries.

## Putting it all together

Here's a complete program that uses most of what you've learned:

```rust
fun fizzbuzz(n) => match n {
  n if n % 15 == 0 => "fizzbuzz",
  n if n % 3 == 0  => "fizz",
  n if n % 5 == 0  => "buzz",
  _                => "{n}"
}

fun main() {
  for i in 1..21 {
    println(fizzbuzz(i))
  }
}
```

Functions, match guards, string interpolation, and a loop, all in a few lines. That's hica.

## Where to go next

- **[Learn hica](/hica/docs/learn)**: 39 standalone programs, each teaching one concept. Run them, modify them, break them.
- **[Language Reference](/hica/docs/language-reference)**: every syntax detail, for when you need the precise rules.
- **[Standard Library](/hica/docs/standard-library)**: all built-in functions covering strings, lists, math, and more.
