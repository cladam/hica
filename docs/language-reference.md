---
layout: default
title: Language Reference - hica
---

# Language Reference

A comprehensive reference for hica's syntax and semantics.

## Functions

### Named functions

```hica
fun add(a, b) {
  a + b
}
```

### Expression-bodied functions (arrow syntax)

```hica
fun double(x) => x * 2
```

### Type annotations

```hica
fun add(a: int, b: int) : int => a + b
```

Type annotations are optional. Hindley-Milner inference handles most cases.

### Visibility

Mark a function as `pub` to make it public (exported from the module):

```hica
pub fun greet(name: string) : string => "Hello, " + name
```

Functions without `pub` are private to the module.

### Lambdas / closures

```hica
let sq = (n) => n * n
let add = (a, b) => a + b
```

Closures capture variables from their enclosing scope:

```hica
fun make_adder(n) => (x) => x + n

fun main() {
  let add5 = make_adder(5)
  println(add5(10))
}
```

### Recursion

Functions can call themselves (self-recursion):

```hica
fun factorial(n) => if n <= 1 { 1 } else { n * factorial(n - 1) }
```

Functions can also call each other (mutual recursion). The compiler
detects cycles automatically. No forward declarations needed:

```hica
fun check_even(n) => if n == 0 { true } else { check_odd(n - 1) }

fun check_odd(n) => if n == 0 { false } else { check_even(n - 1) }
```

## Variables

Variables are bound with `let` and are immutable:

```hica
let x = 42
let name = "Alicia"
let pi = 3.14
```

Integer literals support binary (`0b`), hexadecimal (`0x`), and underscore separators for readability:

```hica
let flags  = 0b1010        // binary → 10
let colour = 0xFF          // hex → 255
let big    = 1_000_000     // underscores are ignored → 1000000
let mask   = 0b1111_0000   // binary with separators → 240
```

### Mutable variables

Use `var` to declare a mutable variable. Reassign it with `=`:

```hica
var count = 0
count = count + 1
println(count)
```

`var` is locally scoped and effect-safe: mutable variables cannot leak out of the function they're declared in.

### The last-line rule

The last expression in a { } block is its return value. No need to write "return". Use println() to see output.

```hica
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

```hica
let sign = if x < 0 { "negative" } else { "non-negative" }
```

### Else-if chains

```hica
fun fizzbuzz(n) =>
  if n % 15 == 0 { "fizzbuzz" }
  else if n % 3 == 0 { "fizz" }
  else if n % 5 == 0 { "buzz" }
  else { "{n}" }
```

### Match expressions

Pattern matching with integer, string, and wildcard patterns:

```hica
fun describe(x) => match x {
  0 => "zero",
  1 => "one",
  _ => "many"
}
```

Match guards add conditions to patterns with `if`:

```hica
fun classify(n) => match n {
  x if x < 0   => "negative",
  0             => "zero",
  x if x > 100 => "big",
  _             => "small positive"
}
```

Guards work with all pattern types, including constructors:

```hica
match parse_int(input) {
  Some(n) if n < 0 => "negative",
  Some(n)          => "valid: {n}",
  None             => "not a number"
}
```

Works with `Maybe` and `Result` types:

```hica
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

```hica
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

```hica
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

```hica
fun describe(point) => match point {
  (0, 0) => "origin",
  (x, 0) => "on x-axis at {x}",
  (0, y) => "on y-axis at {y}",
  (x, y) => "({x}, {y})"
}
```

Struct destructuring patterns:

```hica
struct Point { x: int, y: int }

fun describe(p: Point) : string => match p {
  Point { x: 0, y: 0 } => "origin",
  Point { x, y: 0 }    => "on x-axis at {x}",
  Point { x: 0, y }    => "on y-axis at {y}",
  Point { x, y }       => "({x}, {y})"
}
```

Write just the field name (`x`) to bind it to a variable with that name, or `field: pattern` to match a specific value. Fields not mentioned in the pattern are ignored (treated as wildcards):

```hica
struct Player { name: string, score: int, level: int }

fun rank(p: Player) : string => match p {
  Player { score: 0 }      => "newcomer",
  Player { level, score }  => "level {level} with {score} pts"
}
```

List slice patterns destructure lists by shape. Use `[]` for empty, `[x]` for a single element, `[x, y]` for exactly two, and `[x, ..rest]` to split into head and tail:

```hica
fun describe(xs: list<int>) : string => match xs {
  []           => "empty",
  [x]          => "just {x}",
  [x, y]       => "{x} and {y}",
  [x, ..rest]  => "starts with {x}, {length(rest)} more"
}
```

Slice patterns make recursive list processing clean:

```hica
fun sum(xs: list<int>) : int => match xs {
  []          => 0,
  [x, ..rest] => x + sum(rest)
}
```

Use `..` without a name to ignore the tail:

```hica
[x, ..] => "starts with {x}"
```

Bit patterns match integers by their binary representation using `0b` literals with `?` wildcards. Each `?` matches either 0 or 1:

```hica
fun decode(opcode) => match opcode {
  0b1100_???? => "high nibble is C",
  0b0000_0001 => "exactly 1",
  _           => "other"
}
```

The `?` wildcard means "don't care": the bit at that position is not checked. This is useful for matching bit fields in protocols, instruction encodings, or hardware registers:

```hica
fun classify_instruction(byte) => match byte {
  0b11??_???? => "category 3",
  0b10??_???? => "category 2",
  0b01??_???? => "category 1",
  0b00??_???? => "category 0"
}
```

Bit patterns combine with guards:

```hica
match flags {
  0b????_1??? if flags > 100 => "high bit 3 set and large",
  0b????_1??? => "bit 3 set",
  _ => "bit 3 clear"
}
```

## Loops

### For-range loops

```hica
for i in 0..10 {
  println(i)
}
```

### For-in collection loops

```hica
let names = ["Kalle", "Olle", "Lisa"]
for name in names {
  println(name)
}
```

### Repeat

```hica
repeat(5) {
  println("hello")
}
```

### While loops

```hica
var x = 5
while x > 0 {
  println(x)
  x = x - 1
}
```

The condition must be a `bool`. The body runs until the condition becomes `false`.

### Loop (infinite)

```hica
loop {
  println("running")
  if done { break }
}
```

Repeats forever until `break` is called.

### Break and continue

`break` exits the enclosing loop. `continue` skips to the next iteration. Both work in all loop types: `while`, `for`, `repeat`, and `loop`.

```hica
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
| `char` | `'a'`, `'!'` | Single characters (see `chr`, `ord` in [Standard Library](standard-library.md#char--string-conversions)) |
| `bool` | `true`, `false` | Boolean values |

### Strings

Concatenation with `+` and interpolation with `"{expr}"`:

```hica
let name = "world"
let greeting = "Hello, " + name
let msg = "2 + 2 = {2 + 2}"
```

#### Escape sequences

Use backslash to include special characters in strings:

| Escape | Character |
| --- | --- |
| `\"` | Double quote |
| `\\` | Backslash |
| `\n` | Newline |
| `\t` | Tab |
| `\{` | Literal `{` (prevents interpolation) |
| `\}` | Literal `}` |

```hica
println("She said \"hello\"")
println("line one\nline two")
println("col1\tcol2")
println("C:\\Users\\file.txt")
println("use \{braces\} literally")
```

Escapes work in both plain and interpolated strings:

```hica
let name = "world"
println("hello, {name}!\nbye!")
```

Strings support `<`, `>`, `<=`, `>=` for lexicographic comparison:

```hica
println("apple" < "banana")    // true
println("abc" <= "abc")        // true
```

String utility functions are built in using hica's prelude library:

```hica
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

```hica
let pair = (1, "hello")
let x = pair.0    // 1
let y = pair.1    // "hello"

// Destructuring
let (a, b) = (10, 20)
```

### Structs

Named records with typed fields:

```hica
struct Point { x: int, y: int }

fun main() {
  let p = Point { x: 3, y: 4 }
  println(p.x)     // 3
  println(p.y)     // 4
  println(p)        // Point(x: 3, y: 4)
}
```

Structs work as function parameters and return types:

```hica
struct Point { x: int, y: int }

fun distance_sq(p: Point) : int => p.x * p.x + p.y * p.y

fun origin() : Point => Point { x: 0, y: 0 }
```

Struct names must start with an uppercase letter. Fields are accessed with dot notation.

#### Struct update syntax

Create a new struct from an existing one, overriding specific fields with `{ ...base, field: value }`:

```hica
struct Point { x: int, y: int }

fun main() {
  let p = Point { x: 3, y: 4 }
  let q = Point { ...p, x: 10 }     // Point(x: 10, y: 4)
  let r = Point { ...p }            // copy: Point(x: 3, y: 4)
}
```

The original value is unchanged (structs are immutable). The compiler checks that override fields exist in the struct and have the right types.

#### Opaque structs — type-safe boundaries

By default any module can construct a struct directly. Opaque structs lock the constructor to the defining module, forcing callers to go through a public *smart constructor* that can enforce invariants.

**`opaque struct`** — both the type name and the constructor are private to the defining module:

```hica
opaque struct Token { data: string }

// Only this module can build a Token:
pub fun make_token(s: string) : Token => Token { data: s }
pub fun token_str(t: Token) : string => t.data
```

**`pub struct … priv`** — the type name is public (usable in signatures across modules) but the constructor is private:

```hica
pub struct SqlParam priv { data: string }

// The only way to obtain a SqlParam:
pub fun param(s: string) : SqlParam => SqlParam { data: s }
pub fun param_value(p: SqlParam) : string => p.data
```

Attempting to construct an opaque struct from another module is a compile-time error:

```
error: cannot construct opaque struct 'SqlParam'
       — use its module's constructor function
```

**Rule of thumb:**

| Keyword | Type name visible externally | Constructor visible externally |
|---|---|---|
| `struct Foo {}` | ✓ | ✓ |
| `opaque struct Foo {}` | ✗ | ✗ |
| `pub struct Foo {}` | ✓ | ✓ |
| `pub struct Foo priv {}` | ✓ | ✗ |

Use `opaque struct` for internal handles. Use `pub struct … priv` when callers need to name the type in their own signatures (e.g. as function parameters) but must not be able to forge values.

#### Struct destructuring in match

Use struct patterns to destructure a struct in `match` arms:

```hica
struct Point { x: int, y: int }

fun classify(p: Point) : string => match p {
  Point { x: 0, y: 0 } => "origin",
  Point { x, y }       => "({x}, {y})"
}
```

See [Pattern Matching](#match-expressions) for the full syntax.

### Enums (Algebraic Types)

Define a type with named variants using `type`:

```hica
type Color {
  Red,
  Green,
  Blue
}
```

Variants can carry data. Each variant specifies its own fields:

```hica
type Shape {
  Circle(radius: float),
  Rect(width: float, height: float),
  Point
}
```

Construct enum values like function calls (no data → bare name, with data → parenthesised arguments):

```hica
let c = Red
let s = Circle(5.0)
let r = Rect(3.0, 4.0)
```

Pattern match on enums to handle each variant:

```hica
fun describe(s: Shape) : string => match s {
  Circle(r)  => "circle with radius {r}",
  Rect(w, h) => "{w} x {h} rectangle",
  Point      => "a point"
}
```

The compiler checks exhaustiveness: if you forget a variant, you get a warning:

```
warning: non-exhaustive match: missing Circle(…)
```

Enum names and variant names must start with an uppercase letter. `println` auto-shows enum values (e.g. `Circle(5)`, `Red`).

**Enum vs Struct:** Use a struct when every value has the same fields (AND of fields). Use an enum when a value can be one of several alternatives (OR of shapes).

### Lists

Homogeneous, immutable lists:

```hica
let nums = [1, 2, 3, 4, 5]
let empty = []
let words = ["hello", "world"]
```

### Maps

Key-value dictionaries using `{"key": value}` syntax:

```hica
let ages = {"kalle": 30, "olle": 25, "lisa": 35}
let empty = {:}
```

Maps are represented as lists of tuples under the hood. All list operations work on maps too.

Map functions:

| Function | Description |
|----------|-------------|
| `map_get(m, key)` | Look up a key, returns `maybe<v>` |
| `map_set(m, key, value)` | Add or update a key |
| `map_remove(m, key)` | Remove a key |
| `map_keys(m)` | List of all keys |
| `map_values(m)` | List of all values |
| `map_contains_key(m, key)` | Check if a key exists |
| `map_size(m)` | Number of entries |

```hica
fun main() {
  let m = {"x": 1, "y": 2}
  println(m.map_get("x"))           // Just(1)
  let m2 = m.map_set("z", 3)
  println(m2.map_keys())            // ["x", "y", "z"]
}
```

### Maybe

Optional values:

```hica
let x = Some(42)
let y = None
```

### Result

Success or failure:

```hica
fun safe_divide(a, b) =>
  if b == 0 { Err("division by zero") }
  else { Ok(a / b) }
```

### Combinators

Instead of nesting `match` expressions, use combinators to transform and chain `Maybe` and `Result` values. All are pipe-friendly (value first):

```hica
// Maybe: transform the inner value
let doubled = Some(5) |> map_maybe((x) => x * 2)       // Some(10)

// Maybe: chain functions that return Maybe
let parsed = Some("42") |> and_then((s) => parse_int(s))  // Some(42)

// Result: transform the Ok value
let r = safe_divide(10, 2) |> map_result((n) => n * 10)   // Ok(50)

// Result: chain fallible operations
let r2 = safe_divide(10, 2)
  |> and_then_result((n) => safe_divide(n, 1))             // Ok(5)
```

See the [Standard Library](standard-library) for the full list of combinators.

### User Input

Read a line from stdin with `input(prompt)`. The prompt is printed, and the user's response is returned as a `string`:

```hica
fun main() {
  let name = input("What is your name? ")
  println("Hello, " + name + "!")
}
```

Combine with `parse_int` or `parse_float` to read numbers:

```hica
fun main() {
  let age_str = input("How old are you? ")
  match parse_int(age_str) {
    Some(age) => println("In 10 years you'll be {age + 10}"),
    None      => println("That's not a number!")
  }
}
```

### Random Numbers

Generate random integers with `random(min, max)`. The result is in the range `[min, max]`, both ends included. Use `random_float()` for a random `float` in `[0.0, 1.0)`:

```hica
fun main() {
  let die = random(1, 6)     // 1–6
  let coin = random(0, 1)    // 0 or 1
  println("Die: {die}, Coin: {coin}")

  let f = random_float()     // e.g. 0.7342...
  println(f >= 0.0 && f < 1.0)  // true
}
```

Using `random` or `random_float` gives your program the `ndet` (non-determinism) effect, which `hica check` will report.

### Formatting Numbers

Format floats to a fixed number of decimal places with `show_fixed(value, decimals)`:

```hica
fun main() {
  println(show_fixed(3.14159, 2))       // "3.14"
  println(show_fixed(100.0 / 3.0, 1))   // "33.3"
}
```

Combine with `pad_left` and `pad_right` for aligned output:

```hica
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

```hica
fun double(x) => x * 2
fun add_one(x) => x + 1

fun main() {
  // Pipe operator: a |> f desugars to f(a)
  let a = 5 |> double |> add_one
  println(a)

  // Dot-call (UFCS): a.f() also desugars to f(a)
  let b = 5.double().add_one()
  println(b)

  // They're identical, use whichever reads better
  println(a == b)
}
```

Both `a |> f` and `a.f()` desugar to `f(a)`. The pipe is compact for simple chains; dot-call reads naturally when passing extra arguments:

```hica
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

```hica
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

```hica
fun main() {
  let result = 255.bit_and(15).bit_shl(2)
  println(result)   // 60
}
```

**32-bit constraint:** Bitwise operations internally use 32-bit signed integers. Values are clamped to the `int32` range (−2,147,483,648 to 2,147,483,647). This is the same behaviour as C's `int`, suitable for flags, masks, and protocol work, but not for arbitrary-precision bit manipulation.

### Error propagation (`?`)

The `?` operator provides early-return propagation for both `maybe<T>` and `result<T,E>`.

**With `maybe<T>`:** if the value is `Some(v)`, `?` evaluates to `v`; if it is `None`, the enclosing function returns `None` immediately.

```hica
fun add_strings(a: string, b: string) : maybe<int> {
  let x = parse_int(a)?     // None → return None early
  let y = parse_int(b)?
  Some(x + y)
}

fun main() {
  println(add_strings("3", "4"))    // Some(7)
  println(add_strings("3", "abc"))  // None
}
```

**With `result<T,E>`:** if the value is `Ok(v)`, `?` evaluates to `v`; if it is `Err(e)`, the enclosing function returns `Err(e)` immediately, propagating the error up the call chain.

```hica
fun read_config(path: string) : result<string, string> {
  let content = read_file(path)?   // Err → return Err early
  let trimmed = trim(content)
  Ok(trimmed)
}

fun double_parsed(s: string) : result<int, string> {
  // parse_int returns maybe<int>; convert to result before using ?
  let n = match parse_int(s) { Some(n) => Ok(n), None => Err("not a number") }?
  Ok(n * 2)
}

fun main() {
  match double_parsed("42") {
    Ok(n)  => println(n),    // 84
    Err(e) => println(e)
  }
}
```

Without `?`, the same logic requires nesting:

```hica
fun add_strings(a: string, b: string) : maybe<int> {
  match parse_int(a) {
    None    => None,
    Some(x) => match parse_int(b) {
      None    => None,
      Some(y) => Some(x + y)
    }
  }
}
```

Rules:
- The expression before `?` must be of type `maybe<T>` or `result<T,E>`.
- The enclosing function's **return type annotation is required** — `?` forces an early return and the compiler must know the return type to emit it correctly. Without an annotation, inference may fail.
- The enclosing function must return the **same wrapper type**: `maybe<...>` inside a `maybe`-returning function, `result<...,E>` inside a `result`-returning function. You cannot use `?` on a `maybe` value inside a function that returns `result`, or vice versa.
- `?` cannot be used in `main()` — `main()` returns `()`, which is neither `maybe` nor `result`. Move fallible logic into a helper function and call it from `main()` with a `match`.
- `?` is a postfix operator and binds tighter than binary operators, so `parse_int(a)? + parse_int(b)?` works as expected.

## Testing

### Test blocks

Define tests alongside your code using `test` blocks:

```hica
fun double(n: int) : int => n * 2

test "double works" {
  assert(double(3) == 6)
  assert_eq(double(0), 0)
}

test "string operations" {
  let s = "hello"
  assert(str_length(s) == 5)
  assert_eq(to_upper(s), "HELLO")
}
```

Run tests with `hica test`:

```sh
hica test my_file.hc
```

### Assertions

| Function | Signature | Behaviour |
|----------|-----------|-----------|
| `assert(cond)` | `(bool) -> ()` | Fails with "assertion failed" if `cond` is `false` |
| `assert_eq(expected, actual)` | `(a, a) -> ()` | Fails with "expected X but got Y" if values differ |
| `assert_ne(a, b)` | `(a, a) -> ()` | Fails with "expected values to differ" if equal |
| `assert_true(cond)` | `(bool) -> ()` | Fails with "expected true but got false" |
| `assert_false(cond)` | `(bool) -> ()` | Fails with "expected false but got true" |
| `assert_contains(list, elem)` | `(list<a>, a) -> ()` | Fails if list does not contain element |
| `assert_empty(list)` | `(list<a>) -> ()` | Fails if list is not empty |
| `assert_not_empty(list)` | `(list<a>) -> ()` | Fails if list is empty |

### Test structure

- Tests are declared at the top level (alongside functions and structs)
- Each test has a string name and a block body
- Tests can call any function defined in the same file
- No imports needed. `assert` and `assert_eq` are built-in
- Exit code is 0 on success, 1 on failure

## Modules & Imports

### Modules

Any `.hc` file is a module. Mark functions with `pub` to make them available to other files:

```hica
// greet.hc
pub fun hello(name: string) {
  println("hello, " + name + "!")
}

pub fun goodbye(name: string) {
  println("goodbye, " + name + "!")
}

fun secret() {
  println("this is private")
}
```

Only `pub` items are visible to importers. Functions without `pub` stay private to their file.

### Import

Use `import` to bring all `pub` items from another file into scope:

```hica
import "greet"

fun main() {
  hello("world")     // works: hello is pub
  goodbye("world")   // works: goodbye is pub
  // secret()        // error: secret is not pub
}
```

The path is relative to the importing file, without the `.hc` extension:

- `import "greet"` → looks for `greet.hc` in the same directory
- `import "lib/utils"` → looks for `lib/utils.hc` relative to the importing file

### Selective import

Use `from ... import { ... }` to import only specific names:

```hica
from "greet" import { hello }

fun main() {
  hello("world")     // works: explicitly imported
  // goodbye("world")  // error: not imported
}
```

This is useful when a module exports many items but you only need a few, or when you want to make it clear where a name comes from.

### Re-exporting with `pub import`

Prefix `import` with `pub` to re-export the imported items to your own importers:

```hica
// prelude.hc
pub import "math_helpers"
pub import "string_helpers"
```

Anyone who imports `prelude` gets the `pub` items from both `math_helpers` and `string_helpers`. This is useful for building library packages.

### Import resolution rules

- Imports are resolved **relative to the importing file**, not the working directory
- **Circular imports** are detected and reported as errors
- Each imported file is compiled to its own Koka module, so names do not collide across files
- The import graph is processed before the main file, so imported functions are available throughout your code
