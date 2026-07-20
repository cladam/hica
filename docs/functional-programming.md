---
layout: default
title: Functional Programming in hica - hica
---

# Functional Programming in hica

Functional programming (FP) is a style where you build programs by composing functions rather than by writing sequences of instructions that change state. hica is designed around this style: immutable data, expressions everywhere, and functions as first-class values.

All examples are runnable. You don't need a background in FP; if you can write a function and read a match expression, you have enough.

## Expressions, not statements

In most languages, statements *do things* and expressions *produce values*. In hica, almost everything is an expression, including `if`, `match`, and blocks. That means you can use them anywhere a value is expected:

```hica
fun sign(x) => if x < 0 { "negative" } else { "non-negative" }
```

The body of a `{}` block is the value of its last expression. No `return` keyword:

```hica
fun clamp(x, lo, hi) {
  if x < lo { lo }
  else if x > hi { hi }
  else { x }
}
```

This single rule carries you through most of FP: when everything has a value, everything can be composed.

## Immutability by default

FP avoids shared mutable state. When you can't change a value after creating it, your functions are easier to reason about and test.

hica uses `let` for immutable bindings:

```hica
let name = "Alicia"
let scores = [85, 92, 78]
```

You never mutate `scores` in place. Instead, you create new lists:

```hica
let updated = scores + [95]          // new list: [85, 92, 78, 95]
let doubled = map(scores, (x) => x * 2)
```

When you need mutation (a counter, a loop variable), use `var`. It's locally scoped and can't leak out of the function:

```hica
var total = 0
for x in scores {
  total = total + x
}
```

`var` is opt-in. Everything else stays immutable.

## Pure functions

A *pure function* always returns the same output for the same input and has no side effects (no printing, no file I/O, no mutable state). Pure functions are easy to test and compose.

```hica
fun add(a, b) => a + b
fun square(x) => x * x
fun to_celsius(f: float) => (f - 32.0) * 5.0 / 9.0
```

In hica, functions are pure by default. The type system (inherited from Koka) tracks effects like I/O, so when a function *does* have a side effect, that's visible in its type.

Pure functions are what you build with. Everything else is composition.

## Functions as first-class values

In FP, functions are values like integers or strings. You can store them in variables, pass them to other functions, and return them from functions.

```hica
fun apply(f, x: int) => f(x)

fun main() {
  let double = (x) => x * 2
  let greet  = (name) => "Hello, " + name

  println(apply(double, 5))  // 10
  println(greet("Olle"))     // Hello, Olle
}
```

A function that takes or returns another function is called a *higher-order function*. `apply` above is one.

## Closures

A *closure* is a function that captures variables from its surrounding scope:

```hica
fun make_adder(n) => (x) => x + n

fun main() {
  let add5  = make_adder(5)
  let add10 = make_adder(10)

  println(add5(3))   // 8
  println(add10(3))  // 13
}
```

`make_adder` returns a new function each time. That function *closes over* `n`, meaning it remembers the value of `n` from when it was created, even after `make_adder` has returned.

This pattern lets you stamp out specialised functions on demand:

```hica
fun make_multiplier(factor) => (x) => x * factor

fun main() {
  let triple = make_multiplier(3)
  let nums = [1..5]
  println(map(nums, triple))   // [3, 6, 9, 12, 15]
}
```

## map, filter, fold

These three functions cover most of what you need for working with lists.

### map: transform every element

```hica
fun main() {
  let nums = [1..5]
  println(map(nums, (x) => x * x))   // [1, 4, 9, 16, 25]
  println(map(nums, show))            // ["1", "2", "3", "4", "5"]
}
```

`map` takes a list and a function. It applies the function to each element and returns a new list of the same length.

### filter: keep matching elements

```hica
fun main() {
  let nums = [1..8]
  let evens = filter(nums, (x) => x % 2 == 0)
  println(evens)   // [2, 4, 6, 8]
}
```

`filter` keeps only the elements for which the predicate returns `true`.

### fold: reduce to a single value

```hica
fun main() {
  let nums = [1..5]
  let total = fold(nums, 0, (acc, x) => acc + x)
  println(total)   // 15

  let product = fold(nums, 1, (acc, x) => acc * x)
  println(product)  // 120
}
```

`fold` accumulates a result. It starts with an initial value and applies the function to each element in turn: `acc` holds the running result, `x` is the current element.

You can implement many list operations with fold:

```hica
fun my_length(xs) => fold(xs, 0, (acc, _) => acc + 1)
fun my_max(xs)    => fold(xs, 0, (acc, x) => if x > acc { x } else { acc })
fun my_reverse(xs) => fold(xs, [], (acc, x) => [x] + acc)
```

## flatten and flat_map

`map` transforms every element. But sometimes the function you pass to `map` itself returns a list. The result is a list of lists, which is usually not what you want:

```hica
fun main() {
  let sentences = ["hello world", "foo bar", "one two three"]
  let split_words = map(sentences, (s) => split(s, " "))
  println(split_words)
  // [["hello", "world"], ["foo", "bar"], ["one", "two", "three"]]
}
```

You wanted a flat list of all words. Two functions solve this.

### concat: collapse one level of nesting

```hica
fun main() {
  let nested = [[1, 2], [3, 4], [5, 6]]
  println(concat(nested))   // [1, 2, 3, 4, 5, 6]
}
```

`concat` takes a list of lists and collapses one level. (Other languages call this `flatten`.)

### flat_map: map and flatten in one step

`flat_map` applies a function to each element and joins all the resulting lists together. It is `map` followed by `concat`, but written as one step:

```hica
fun main() {
  let sentences = ["hello world", "foo bar", "one two three"]
  let all_words = flat_map(sentences, (s) => split(s, " "))
  println(all_words)
  // ["hello", "world", "foo", "bar", "one", "two", "three"]
}
```

You reach for `flat_map` whenever the function you are mapping returns a list.

### Expanding elements in a pipe

`flat_map` fits naturally in a pipe. Use it at the step where a single element becomes multiple elements:

```hica
fun expand(n) => [n, n * 10]   // each element fans out to two

fun main() {
  let result = [1, 2, 3]
    |> flat_map(expand)           // [1, 10, 2, 20, 3, 30]
    |> filter((x) => x > 5)      // [10, 20, 30]
  println(result)
}
```

Without `flat_map` you would get `[[1, 10], [2, 20], [3, 30]]` and `filter` would be operating on lists, not numbers.

### The same idea applies to Maybe

The pattern: *apply a function that produces a wrapped value, then flatten the wrapping*, appears with Maybe too. `map_maybe` transforms the value inside a `Maybe`. But if the function itself returns `Maybe`, you'd end up with `Maybe<Maybe<x>>`. `and_then` prevents that by flattening the extra layer automatically:

```hica
fun parse_pos(s: string) : maybe<int> {
  let n = parse_int(s)?
  if n > 0 { Some(n) } else { None }
}

fun main() {
  // and_then chains steps that each return Maybe — no nesting, no nested match
  let result = Some("42")
    |> and_then((s) => parse_int(s))     // parse string → maybe<int>
    |> and_then((n) => parse_pos(show(n)))
    |> map_maybe((n) => n * 2)
  println(result)   // Some(84)

  let bad = Some("-5")
    |> and_then((s) => parse_int(s))
    |> and_then((n) => parse_pos(show(n)))
    |> map_maybe((n) => n * 2)
  println(bad)   // None
}
```

`flat_map` for lists and `and_then` for Maybe are the same idea with different names. Functional programmers call this operation *bind*. Knowing the pattern: "map over a wrapped value with a function that itself returns a wrapped value, and don't double-wrap", is the thing to take away, whatever the type.

## Composition with |>

The pipe operator `|>` feeds the result of one expression into the next function. It reads left to right, matching the order of operations:

```hica
fun main() {
  let result = [1..10]
    |> filter((x) => x % 2 == 0)     // [2, 4, 6, 8, 10]
    |> map((x) => x * x)             // [4, 16, 36, 64, 100]
    |> fold(0, (acc, x) => acc + x)  // 220

  println(result)
}
```

Without `|>` you'd write:

```hica
let result = fold(map(filter([1..10], (x) => x % 2 == 0), (x) => x * x), 0, (acc, x) => acc + x)
```

With `|>`, each step is on its own line and you read the transformation in the order it happens. That's the point: each step is one function, and they chain.

### Point-free style

When a lambda just passes its argument directly to a function, you can drop the lambda entirely:

```hica
fun is_even(x) => x % 2 == 0
fun square(x)  => x * x

fun main() {
  let result = [1..5]
    |> filter(is_even)   // same as filter(nums, (x) => is_even(x))
    |> map(square)
  println(result)   // [4, 16]
}
```

This style (naming the function rather than wrapping it in a lambda) is called *point-free*. Use it when the name says more than the lambda would.

## Lazy Streams

When we chain standard list transformations like `map` and `filter`, each step in the pipeline allocates an entirely new list:

```hica
[1..20] |> filter(is_even) |> map(square) |> take(5)
```

In this pipeline, `filter` allocates a new list of 10 elements, `map` allocates another list of 10 elements, and `take` finally allocates a list of 5 elements.

**Lazy streams** (provided by `std/stream`) solve this intermediate allocation problem by combining all operations into a single traversal. Elements flow through the pipeline one by one. No intermediate lists are built, and processing stops as soon as the terminal condition is satisfied.

To use lazy streams, import `std/stream` and wrap your list with the `stream` function:

```hica
import "std/stream"

fun main() {
  // 1. Zero-Allocation Pipelines
  let result = stream([1..20])
    .filter((x) => x % 2 == 0)
    .map((x) => x * x)
    .take(5)
    .collect() // Materialise the stream into a standard list

  println(result) // [4, 16, 36, 64, 100]
}
```

### Early Termination

With standard lists, filtering `[1..1000]` runs the predicate function 1000 times. With a stream, the generator halts immediately once its pipeline requirements (like `take(3)`) are satisfied, saving processor cycles:

```hica
import "std/stream"

fun main() {
  let first_multiples = stream([1..1000])
    .filter((x) => x % 7 == 0)
    .take(3)
    .collect()

  println(first_multiples) // [7, 14, 21]
}
```

### Stream Operations and Terminators

Streams support a variety of transformations and terminating aggregations:

- **Transformations (Lazy):** `map`, `filter`, `take`, `zip`, `enumerate`, and more. They immediately return a new stream without evaluating the elements.
- **Terminators (Eager):** `collect` (returns a list), `fold` (reduces to a single value), and `foreach` (runs side effects). These force the stream to evaluate.

```hica
import "std/stream"

fun main() {
  // Fold a stream directly without intermediate list allocation
  let sum_of_squares = stream([1..1000])
    .filter((x) => x % 2 == 0)
    .map((x) => x * x)
    .take(10)
    .fold(0, (acc, x) => acc + x)

  println(sum_of_squares) // 1540

  // Indexing elements lazily with enumerate()
  let indexed = stream(["a", "b", "c"])
    .enumerate()
    .collect()

  println(indexed) // [(0, "a"), (1, "b"), (2, "c")]
}
```

## Pipeline Transducers

Lazy streams are great for zero-allocation processing, but they must be bound to a data source immediately. You cannot build a stream transformation pipeline on its own, save it in a variable, and reuse it across different data sources.

**Transducers** (provided by `std/xform`) solve this. They decouple the transformation logic from the underlying data structure, allowing you to define reusable, source-independent query pipelines!

### Defining and Composing Transducers

A transducer is built using transducer constructors that start with `xf_`:

- **Starting constructors:** `xf_filter(pred)`, `xf_map_start(f)`, `xf_take_start(n)`, etc.
- **Chaining constructors:** `xf_map(xform, f)`, `xf_filter_with(xform, pred)`, `xf_take(xform, n)`, `xf_take_while(xform, pred)`, `xf_drop_while(xform, pred)`, `xf_flat_map(xform, f)`.

Because hica desugars `a |> f(b)` to `f(a, b)`, transducers compose perfectly left-to-right using the pipe operator `|>`:

```hica
import "std/stream"
import "std/xform"

// Define a reusable pipeline (no data source is bound yet!)
let double_evens =
  xf_filter((x) => x % 2 == 0)
  |> xf_map((x) => x * 2)
  |> xf_take(3)
```

### Applying Transducers with `transduce`

To apply a transducer to a list, use the `transduce(list, xform)` function. This converts the list to a stream, passes it through the transducer pipeline, and collects the result in a single, zero-allocation pass:

```hica
import "std/stream"
import "std/xform"

fun main() {
  let pipeline =
    xf_filter((x) => x % 2 == 0)
    |> xf_map((x) => x * 2)
    |> xf_take(5)

  let numbers1 = [1..10]
  let numbers2 = [11..20]

  // Apply the same pipeline to different sources!
  let r1 = numbers1 |> transduce(pipeline)
  let r2 = numbers2 |> transduce(pipeline)

  println(r1) // [4, 8, 12, 16]
  println(r2) // [24, 28, 32, 36, 40]
}
```

If you want to start your transducer with a mapping function instead of a filter, use `xf_map_start`:

```hica
import "std/stream"
import "std/xform"

fun main() {
  let double_only =
    xf_map_start((x) => x * 2)
    |> xf_filter_with((x) => x > 10)

  let r = [1..10] |> transduce(double_only)
  println(r) // [12, 14, 16, 18, 20]
}
```

## Recursion

FP uses recursion where imperative code uses loops. A recursive function calls itself with a smaller input until it hits a base case:

```hica
fun sum(xs) => match xs {
  []          => 0,
  [x, ..rest] => x + sum(rest)
}

fun main() {
  println(sum([1..5]))   // 15
}
```

The `[x, ..rest]` pattern splits a list into its first element and the rest. This pairs naturally with recursion:

```hica
fun contains(xs, target) => match xs {
  []          => false,
  [x, ..rest] => x == target || contains(rest, target)
}

fun map_r(xs, f) => match xs {
  []          => [],
  [x, ..rest] => [f(x)] + map_r(rest, f)
}
```

For mutual recursion (two functions that call each other), no forward declarations are needed:

```hica
fun is_even(n) => if n == 0 { true } else { is_odd(n - 1) }
fun is_odd(n)  => if n == 0 { false } else { is_even(n - 1) }
```

In practice you'll use `map`/`filter`/`fold` far more than explicit recursion, but recursion is the right tool for tree-shaped data, and knowing it helps you read other people's code.

## Algebraic data types

Functional programming uses *algebraic data types* (ADTs) to model data that comes in different shapes. hica has two kinds.

### Structs: product types

A struct bundles fields together:

```hica
struct Point { x: int, y: int }
struct Person { name: string, age: int }

fun greet(p: Person) => "Hi, {p.name}!"

fun distance(a: Point, b: Point) : int {
  let dx = a.x - b.x
  let dy = a.y - b.y
  dx * dx + dy * dy
}
```

Structs are immutable. To "update" a field, create a new struct:

```hica
struct Player { name: string, score: int }

fun add_score(p: Player, points: int) : Player =>
  Player { name: p.name, score: p.score + points }
```

### Enums: sum types

An enum represents a choice between distinct variants, each of which can carry its own data:

```hica
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
```

The compiler checks exhaustiveness: if you forget a variant, you get a warning. This makes adding new variants safe; the compiler tells you every place that needs updating.

Enums can be recursive, which is how you model tree-shaped data:

```hica
type Tree {
  Leaf,
  Node(value: int, left: Tree, right: Tree)
}

fun tree_sum(t: Tree) : int => match t {
  Leaf           => 0,
  Node(v, l, r)  => v + tree_sum(l) + tree_sum(r)
}
```

## Maybe and Result

Two built-in types handle failure without exceptions.

### Maybe: a value that might not exist

```hica
fun find_first(xs, pred) => match xs {
  []          => None,
  [x, ..rest] => if pred(x) { Some(x) } else { find_first(rest, pred) }
}

fun main() {
  let nums = [1, 3, 5, 4, 7]
  match find_first(nums, (x) => x % 2 == 0) {
    Some(n) => println("First even: {n}"),
    None    => println("No evens found")
  }
}
```

`Some(x)` wraps a value; `None` signals absence. The compiler forces you to handle both cases.

### Chaining with combinators

Nested `match` for every step gets unwieldy fast. Combinators keep the chain flat. There is also a subtlety: when the function you want to apply itself returns `Maybe`, using `map_maybe` would give you `Maybe<Maybe<x>>`. `and_then` prevents the double-wrapping by flattening one level, the same job `flat_map` does for lists:

```hica
fun main() {
  // map_maybe transforms the value inside, leaves None alone
  let x = Some(21) |> map_maybe((n) => n * 2)
  println(x)   // Some(42)

  // and_then chains a function that itself returns Maybe
  let y = Some("42")
    |> and_then((s) => parse_int(s))
    |> map_maybe((n) => n + 1)
  println(y)   // Some(43)

  // Short-circuits at the first None
  let z = Some("nope")
    |> and_then((s) => parse_int(s))
    |> map_maybe((n) => n + 1)
  println(z)   // None
}
```

### Result: success or a specific error

`Result` carries an error message on failure:

```hica
fun safe_divide(a, b) =>
  if b == 0 { Err("division by zero") }
  else { Ok(a / b) }

fun validate_positive(n) =>
  if n > 0 { Ok(n) }
  else { Err("must be positive") }

fun main() {
  let result = safe_divide(100, 4)
    |> and_then_result((n) => validate_positive(n))
    |> map_result((n) => n * 2)
  println(result)   // Ok(50)

  let bad = safe_divide(100, 0)
    |> and_then_result((n) => validate_positive(n))
  println(bad)   // Err("division by zero")
}
```

### The ? operator

For functions that chain many fallible steps, `?` keeps the code flat. It returns early with `None` or `Err` if a step fails:

```hica
fun add_strings(a: string, b: string) : maybe<int> {
  let x = parse_int(a)?
  let y = parse_int(b)?
  Some(x + y)
}

fun main() {
  println(add_strings("10", "32"))    // Some(42)
  println(add_strings("10", "oops"))  // None
}
```

Three constraints to know:

- The **return type annotation is required** on the enclosing function: the compiler needs it to emit the early return correctly.
- The wrapper type must match: `?` on `maybe` only works inside a `maybe`-returning function, and `?` on `result` only inside a `result`-returning function.
- `?` **cannot be used in `main()`**: `main()` returns `()`. Move fallible logic into a helper and call it from `main()` with `match`.

## Putting it together

A program that pulls it all together: structs, pure functions, closures, pipe, pattern matching, and `maybe`.

```hica
struct Student { name: string, grade: int }

fun letter_grade(g: int) : string => match g {
  90..=100 => "A",
  80..=89  => "B",
  70..=79  => "C",
  60..=69  => "D",
  _        => "F"
}

fun passing(s: Student) : bool => s.grade >= 60

fun summarise(students: list<Student>) {
  let passing_students = filter(students, passing)
  let names = map(passing_students, (s) => s.name)
  let avg = fold(passing_students, 0, (acc, s) => acc + s.grade)
    / length(passing_students)

  println("Passing: {join(names, ", ")}")
  println("Average grade (passing): {avg}")
  println("Letter grade: {letter_grade(avg)}")
}

fun main() {
  let students = [
    Student { name: "Alicia", grade: 92 },
    Student { name: "Björn",  grade: 55 },
    Student { name: "Cecilia", grade: 78 },
    Student { name: "David",  grade: 61 }
  ]
  summarise(students)
}
```

Output:
```
Passing: Alicia, Cecilia, David
Average grade (passing): 77
Letter grade: C
```

## Key ideas to take with you

| Concept | hica |
|---------|------|
| Immutable data | `let` by default, `var` when you need it |
| First-class functions | `(x) => x * 2`, `fun add(a, b) => a + b` |
| Closures | `fun make_adder(n) => (x) => x + n` |
| Composition | `\|>` pipe operator |
| Transforming lists | `map`, `filter`, `fold` |
| Flattening / expanding | `concat` (flatten), `flat_map` (map + flatten) |
| Chaining wrapped values | `and_then` (Maybe), `and_then_result` (Result), same idea as `flat_map` |
| Lazy Streams | `stream(xs)`, chain `.map()`, `.filter()`, etc., terminate with `.collect()`, `.fold()` |
| Pipeline Transducers | Reusable, decoupled pipelines via `std/xform` (e.g. `xf_filter` \|> `xf_map`) applied with `transduce` |
| Recursive data | `type Tree { Leaf, Node(...) }` |
| Safe failures | `Maybe` (`Some`/`None`) and `Result` (`Ok`/`Err`) |
| Exhaustive matching | `match` with compiler-checked variants |

The point isn't to avoid loops. It's that small functions composed together tend to be easier to test, name, and reuse. hica's design makes that the natural default.
