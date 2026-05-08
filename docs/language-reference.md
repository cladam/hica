---
layout: default
title: Language Reference - hica
---

# Language Reference

A comprehensive reference for hica's syntax and semantics.

## Functions

### Named functions

```rust
fun add(a, b) {
  a + b
}
```

### Expression-bodied functions (arrow syntax)

```rust
fun double(x) => x * 2
```

### Type annotations

```rust
fun add(a: int, b: int) : int => a + b
```

Type annotations are optional. Hindley-Milner inference handles most cases.

### Visibility

Mark a function as `pub` to make it public (exported from the module):

```rust
pub fun greet(name: string) : string => "Hello, " + name
```

Functions without `pub` are private to the module.

### Lambdas / closures

```rust
let sq = (n) => n * n
let add = (a, b) => a + b
```

Closures capture variables from their enclosing scope:

```rust
fun make_adder(n) => (x) => x + n

fun main() {
  let add5 = make_adder(5)
  println(add5(10))
}
```

## Variables

Variables are bound with `let` and are immutable:

```rust
let x = 42
let name = "Alicia"
let pi = 3.14
```

Integer literals support binary (`0b`), hexadecimal (`0x`), and underscore separators for readability:

```rust
let flags  = 0b1010        // binary → 10
let colour = 0xFF          // hex → 255
let big    = 1_000_000     // underscores are ignored → 1000000
let mask   = 0b1111_0000   // binary with separators → 240
```

### Mutable variables

Use `var` to declare a mutable variable. Reassign it with `=`:

```rust
var count = 0
count = count + 1
println(count)
```

`var` is locally scoped and effect-safe — mutable variables cannot leak out of the function they're declared in.

### The last-line rule

The last expression in a { } block is its return value. No need to write "return". Use println() to see output.

```rust
fun main() {
  let a = 10
  let b = 20
  let c = a + b
  println(c)
}
```

## Control Flow

### If / else

`if`/`else` are expressions that return values:

```rust
let sign = if x < 0 { "negative" } else { "non-negative" }
```

### Else-if chains

```rust
fun fizzbuzz(n) =>
  if n % 15 == 0 { "fizzbuzz" }
  else if n % 3 == 0 { "fizz" }
  else if n % 5 == 0 { "buzz" }
  else { "{n}" }
```

### Match expressions

Pattern matching with integer, string, and wildcard patterns:

```rust
fun describe(x) => match x {
  0 => "zero",
  1 => "one",
  _ => "many"
}
```

Match guards add conditions to patterns with `if`:

```rust
fun classify(n) => match n {
  x if x < 0   => "negative",
  0             => "zero",
  x if x > 100 => "big",
  _             => "small positive"
}
```

Guards work with all pattern types, including constructors:

```rust
match parse_int(input) {
  Some(n) if n < 0 => "negative",
  Some(n)          => "valid: {n}",
  None             => "not a number"
}
```

Works with `Maybe` and `Result` types:

```rust
match safe_divide(10, 3) {
  Ok(n)  => println(n),
  Err(e) => println(e)
}

match find_user(id) {
  Some(user) => println(user),
  None       => println("not found")
}
```

Or-patterns match multiple values in one arm with `|`:

```rust
fun day_type(day) => match day {
  "Saturday" | "Sunday" => "weekend",
  _                     => "weekday"
}

fun classify(n) => match n {
  1 | 2 | 3 => "low",
  4 | 5 | 6 => "mid",
  _         => "high"
}
```

Range patterns match a contiguous range of integers with `..=` (inclusive on both ends):

```rust
fun grade(score: int) => match score {
  0..=59   => "F",
  60..=69  => "D",
  70..=79  => "C",
  80..=89  => "B",
  90..=100 => "A",
  _        => "invalid"
}
```

Tuple destructuring patterns:

```rust
fun describe(point) => match point {
  (0, 0) => "origin",
  (x, 0) => "on x-axis at {x}",
  (0, y) => "on y-axis at {y}",
  (x, y) => "({x}, {y})"
}
```

Bit patterns match integers by their binary representation using `0b` literals with `?` wildcards. Each `?` matches either 0 or 1:

```rust
fun decode(opcode) => match opcode {
  0b1100_???? => "high nibble is C",
  0b0000_0001 => "exactly 1",
  _           => "other"
}
```

The `?` wildcard means "don't care" — the bit at that position is not checked. This is useful for matching bit fields in protocols, instruction encodings, or hardware registers:

```rust
fun classify_instruction(byte) => match byte {
  0b11??_???? => "category 3",
  0b10??_???? => "category 2",
  0b01??_???? => "category 1",
  0b00??_???? => "category 0"
}
```

Bit patterns combine with guards:

```rust
match flags {
  0b????_1??? if flags > 100 => "high bit 3 set and large",
  0b????_1??? => "bit 3 set",
  _ => "bit 3 clear"
}
```

## Loops

### For-range loops

```rust
for i in 0..10 {
  println(i)
}
```

### For-in collection loops

```rust
let names = ["Kalle", "Olle", "Lisa"]
for name in names {
  println(name)
}
```

### Repeat

```rust
repeat(5) {
  println("hello")
}
```

### While loops

```rust
var x = 5
while x > 0 {
  println(x)
  x = x - 1
}
```

The condition must be a `bool`. The body runs until the condition becomes `false`.

### Loop (infinite)

```rust
loop {
  println("running")
  if done { break }
}
```

Repeats forever until `break` is called.

### Break and continue

`break` exits the enclosing loop. `continue` skips to the next iteration. Both work in all loop types: `while`, `for`, `repeat`, and `loop`.

```rust
for i in 0..10 {
  if i % 2 == 0 { continue }
  if i > 7 { break }
  println(i)
}
```

## Data Types

### Primitives

| Type | Example | Description |
| ---- | ------- | ----------- |
| `int` | `42`, `-7` | Integer numbers |
| `float` | `3.14`, `-0.5` | Floating-point numbers |
| `string` | `"hello"` | Text strings |
| `char` | `'a'`, `'!'` | Single characters |
| `bool` | `true`, `false` | Boolean values |

### Strings

Concatenation with `+` and interpolation with `"{expr}"`:

```rust
let name = "world"
let greeting = "Hello, " + name
let msg = "2 + 2 = {2 + 2}"
```

Strings support `<`, `>`, `<=`, `>=` for lexicographic comparison:

```rust
println("apple" < "banana")    // true
println("abc" <= "abc")        // true
```

String utility functions are built in using hica's prelude library:

```rust
fun main() {
  let s = "  Hello, World!  "
  println(str_length(s))
  println(trim(s))
  println(to_upper(trim(s)))
  println(contains(s, "World"))
  println(starts_with(trim(s), "Hello"))
  println(split("a,b,c", ","))
  println(join(["a", "b", "c"], "-"))
  println(replace("hello", "l", "r"))
  println(index_of("hello-world", "-"))
  println(to_int("42"))
  println(parse_int("42"))
  println(parse_float("3.14"))
}
```

See the [Standard Library](standard-library.md) for the full list.

### Tuples

```rust
let pair = (1, "hello")
let x = pair.0    // 1
let y = pair.1    // "hello"

// Destructuring
let (a, b) = (10, 20)
```

### Structs

Named records with typed fields:

```rust
struct Point { x: int, y: int }

fun main() {
  let p = Point { x: 3, y: 4 }
  println(p.x)     // 3
  println(p.y)     // 4
  println(p)        // Point(x: 3, y: 4)
}
```

Structs work as function parameters and return types:

```rust
struct Point { x: int, y: int }

fun distance_sq(p: Point) : int => p.x * p.x + p.y * p.y

fun origin() : Point => Point { x: 0, y: 0 }
```

Struct names must start with an uppercase letter. Fields are accessed with dot notation.

### Lists

Homogeneous, immutable lists:

```rust
let nums = [1, 2, 3, 4, 5]
let empty = []
let words = ["hello", "world"]
```

### Maybe

Optional values:

```rust
let x = Some(42)
let y = None
```

### Result

Success or failure:

```rust
fun safe_divide(a, b) =>
  if b == 0 { Err("division by zero") }
  else { Ok(a / b) }
```

### User Input

Read a line from stdin with `input(prompt)`. The prompt is printed, and the user's response is returned as a `string`:

```rust
fun main() {
  let name = input("What is your name? ")
  println("Hello, " + name + "!")
}
```

Combine with `parse_int` or `parse_float` to read numbers:

```rust
fun main() {
  let age_str = input("How old are you? ")
  match parse_int(age_str) {
    Some(age) => println("In 10 years you'll be {age + 10}"),
    None      => println("That's not a number!")
  }
}
```

### Random Numbers

Generate random integers with `random(min, max)`. The result is in the range `[min, max]` — both ends included:

```rust
fun main() {
  let die = random(1, 6)     // 1–6
  let coin = random(0, 1)    // 0 or 1
  println("Die: {die}, Coin: {coin}")
}
```

Using `random` gives your program the `ndet` (non-determinism) effect, which `hica check` will report.

### Formatting Numbers

Format floats to a fixed number of decimal places with `show_fixed(value, decimals)`:

```rust
fun main() {
  println(show_fixed(3.14159, 2))       // "3.14"
  println(show_fixed(100.0 / 3.0, 1))   // "33.3"
}
```

Combine with `pad_left` and `pad_right` for aligned output:

```rust
fun main() {
  println(pad_left(show(42), 6, " "))     // "    42"
  println(pad_right("hi", 10, "."))       // "hi........"
}
```

See the [Standard Library](standard-library.md) for the full list of formatting and string helper functions.

## Operators

### Arithmetic

| Operator | Description |
| -------- | ----------- |
| `+` | Addition |
| `-` | Subtraction |
| `*` | Multiplication |
| `/` | Division |
| `%` | Remainder |

### Comparison

| Operator | Description |
| -------- | ----------- |
| `==` | Equal |
| `!=` | Not equal |
| `<` | Less than |
| `>` | Greater than |
| `<=` | Less than or equal |
| `>=` | Greater than or equal |

Comparison operators work on `int`, `float`, and `string` (lexicographic ordering).

### Logical

| Operator | Description |
| -------- | ----------- |
| `&&` | Logical AND |
| `||` | Logical OR |

### Pipe and dot-call syntax

hica has two equivalent ways to chain function calls left to right:

```rust
fun double(x) => x * 2
fun add_one(x) => x + 1

fun main() {
  // Pipe operator: a |> f desugars to f(a)
  let a = 5 |> double |> add_one
  println(a)

  // Dot-call (UFCS): a.f() also desugars to f(a)
  let b = 5.double().add_one()
  println(b)

  // They're identical — use whichever reads better
  println(a == b)
}
```

Both `a |> f` and `a.f()` desugar to `f(a)`. The pipe is compact for simple chains; dot-call reads naturally when passing extra arguments:

```rust
fun main() {
  // Dot-call with arguments: a.f(b) desugars to f(a, b)
  let nums = [1, 2, 3, 4, 5]
  let result = nums.filter((x) => x > 2).map((x) => x * 10)
  println(result)
}
```

Note: `expr.name` without parentheses is struct field access (`p.x`). With parentheses, `expr.name(...)` is a function call.

### Bitwise

Bitwise operations are provided as built-in functions. They work on 32-bit integer values internally (hica's `int` is converted to a 32-bit integer, the operation is applied, and the result is converted back).

| Function | Description |
| -------- | ----------- |
| `bit_and(a, b)` | Bitwise AND |
| `bit_or(a, b)` | Bitwise OR |
| `bit_xor(a, b)` | Bitwise XOR |
| `bit_not(a)` | Bitwise complement (flip all bits) |
| `bit_shl(a, n)` | Shift left by `n` bits |
| `bit_shr(a, n)` | Logical shift right by `n` bits |

```rust
fun main() {
  let flags = 255
  let masked = bit_and(flags, 15)   // keep low nibble → 15
  println(masked)

  let shifted = bit_shr(flags, 4)   // shift right 4 → 15
  println(shifted)

  let combined = bit_or(flags, 256)  // set bit 8 → 511
  println(combined)
}
```

With UFCS (dot-call syntax), bitwise functions chain naturally:

```rust
fun main() {
  let result = 255.bit_and(15).bit_shl(2)
  println(result)   // 60
}
```

**32-bit constraint:** Bitwise operations internally use 32-bit signed integers. Values are clamped to the `int32` range (−2,147,483,648 to 2,147,483,647). This is the same behaviour as C's `int` — suitable for flags, masks, and protocol work, but not for arbitrary-precision bit manipulation.
