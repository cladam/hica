---
layout: default
title: Hica vs. Koka - hica
---

# Hica vs Koka

hica transpiles to Koka, so everything hica does ultimately *is* Koka. The question isn't "which is more powerful?" (Koka will always win that). The question is: **why add a layer on top?**

The short answer: the differences are about **intent, ergonomics, and tooling**. Koka is a world-class research language exploring the cutting edge of algebraic effects. hica is an industrial-pragmatic language designed for building everyday software (CLI tools, parsers, utilities) with a familiar syntax, a curated feature set, and an integrated toolchain.

## At a Glance

| Dimension | Koka | hica |
|-----------|------|------|
| Syntax style | Indentation-sensitive, ML-family | Braces + semicolons optional, C/Rust-family |
| Type annotations | Required on public functions | Optional everywhere (Hindley-Milner infers) |
| Effects | Explicit row-typed effect system (user declares and handles) | Implicit (inferred and emitted, not written by the programmer) |
| Pattern matching | Deep, exhaustive, with handlers | Common cases: primitives, Maybe/Result, structs, ranges, lists |
| Custom effects | First-class: `effect`, `handler`, `resume` | Not exposed (Koka handles it underneath) |
| Data types | `type`, `struct`, `alias`, `effect` with full generics | `struct` + `type` enums, inferred polymorphism |
| String interpolation | `println("x = " ++ x.show)` | `println("x = {x}")` |
| String concatenation | `++` | `+` |
| Pipe operator | Not built-in (use dot-call) | `\|>` built-in + dot-call |
| List syntax | `Cons(1, Cons(2, Nil))` or `[1,2,3]` | `[1, 2, 3]` always, `[h, ..rest]` patterns |
| Map literals | No built-in syntax | `{"key": value}` literals |
| Loops | `while`, `for`, `repeat` via effects | `while`, `for`, `repeat`, `loop`, `break`, `continue` |
| Mutability | Local `var` via effect handlers | `var` with familiar reassignment syntax |
| Module system | File-based, `pub` visibility | `import` / `from M import { f }` / `pub import` |
| Learning curve | Steep (effects, handlers, row types) | Gentle (write, run, iterate) |
| Target audience | PL researchers, effect-system enthusiasts | Beginners, educators, application programmers |

## Syntax: Familiar vs Novel

Koka's syntax is ML-inspired. It is clean but unfamiliar to most programmers:

```koka
fun factorial(n : int) : int
  if n <= 1 then 1
  else n * factorial(n - 1)

fun main()
  println(factorial(5))
```

hica uses braces, `=>` arrows, and `let`, patterns that developers recognise from Rust, TypeScript, and C#:

```hica
fun factorial(n) => if n <= 1 { 1 } else { n * factorial(n - 1) }

fun main() {
  println(factorial(5))
}
```

Neither is objectively better. But if you are teaching a class, onboarding junior developers, or writing your first compiled language, the brace style has less to explain.

## Effects: Curated Complexity

This is the biggest philosophical difference. Koka's effect system is its defining feature, and its steepest learning curve.

In Koka, every function signature tells you what effects it uses. You must understand effect rows, effect polymorphism, and how handlers work before you can write non-trivial programs:

```koka
fun greet() : console ()
  println("hello")

fun read-config() : <fsys, exn> string
  read-text-file("config.txt".path)
```

hica curates this power: you get the safety benefits of side-effect tracking (visible via `hica check`) without writing effect annotations yourself:

```hica
fun greet() {
  println("hello")
}

fun read_config() => read_file("config.txt")
```

The hica compiler infers and emits the correct effects in the generated Koka code. You get Koka's safety guarantees without the annotation burden. The trade-off is that you cannot define custom effects or write effect handlers. If you need that power, you are ready for Koka.

## Type Annotations: Required vs Optional

Koka requires type annotations on public function signatures:

```koka
pub fun add(a : int, b : int) : int
  a + b
```

hica infers types across function boundaries. Annotations are always optional:

```hica
pub fun add(a, b) => a + b
```

You can add them when you want documentation:

```hica
pub fun add(a: int, b: int) : int => a + b
```

This lowers the barrier for beginners. You do not need to understand the type system to write correct programs; the compiler figures it out.

## String Handling

Koka uses `++` for concatenation and `show` for conversion:

```koka
fun main()
  val name = "world"
  println("Hello, " ++ name ++ "! " ++ show(42))
```

hica uses `+` and has built-in string interpolation:

```hica
fun main() {
  let name = "world"
  println("Hello, {name}! {42}")
}
```

Small difference, big impact on readability when building messages and output.

## Data Structures

### Lists

Koka's list operations require understanding of effect signatures and sometimes explicit types:

```koka
fun main()
  val nums = [1, 2, 3, 4, 5]
  val evens = nums.filter(fn(x) x % 2 == 0)
  val doubled = evens.map(fn(x) x * 10)
  println(doubled.show)
```

hica has the same operations with lighter syntax and a pipe operator:

```hica
fun main() {
  let result = [1, 2, 3, 4, 5]
    |> filter((x) => x % 2 == 0)
    |> map((x) => x * 10)
  println(result)
}
```

### Maps

Koka has no built-in map literal syntax. You would use `std/data/dict` or build association lists manually.

hica has map literals:

```hica
fun main() {
  let ages = {"kalle": 30, "olle": 25}
  println(ages.map_get("kalle"))   // Just(30)
}
```

### Struct update syntax

Koka:

```koka
val p2 = p(x = 10)
```

hica:

```hica
let p2 = Point { ...p, x: 10 }
```

The hica spread syntax is more explicit about what is happening.

## Pattern Matching

Both languages have exhaustive pattern matching. Koka's is more powerful (nested destructuring, guards on handlers, effect matching), whilst hica covers the common cases with a syntax closer to Rust:

```hica
fun describe(x) => match x {
  0       => "zero",
  1 | 2   => "few",
  3..=10  => "several",
  _       => "many"
}

fun sum(xs: list<int>) : int => match xs {
  []          => 0,
  [x, ..rest] => x + sum(rest)
}
```

hica also has bit-level pattern matching with `?` wildcards, something Koka does not have:

```hica
match opcode {
  0b11??_???? => "category 3",
  0b10??_???? => "category 2",
  _           => "other"
}
```

## Loops and Control Flow

Koka models loops through effect handlers. `while` and `for` exist but `break` and `continue` require understanding effect-based control flow:

```koka
fun main()
  for(1, 10) fn(i)
    println(show(i))
```

hica has imperative-style loops with `break` and `continue` that work as you would expect:

```hica
fun main() {
  for i in 1..10 {
    if i % 3 == 0 { continue }
    println(i)
  }

  var count = 0
  while count < 5 {
    println(count)
    count = count + 1
  }

  loop {
    if count > 10 { break }
    count = count + 1
  }
}
```

## Modules and Imports

Koka uses qualified imports:

```koka
import std/os/path
import std/os/file
```

hica uses string-based imports with selective imports and re-exports:

```hica
import "std/os/path"
from "std/os/file" import { read_file, write_file }
pub import "mylib/utils"
```

## Error Handling

Koka uses effects for exceptions, which is powerful but requires understanding effect handlers:

```koka
fun safe-divide(a : int, b : int) : exn int
  if b == 0 then throw("division by zero")
  a / b
```

hica uses `Result` and `Maybe` types with combinators, the same approach as Rust:

```hica
fun safe_divide(a, b) =>
  if b == 0 { Err("division by zero") }
  else { Ok(a / b) }

fun main() {
  let result = safe_divide(10, 2)
    |> map_result((n) => n * 10)
    |> and_then_result((n) => safe_divide(n, 5))
  println(result)
}
```

## Integrated Toolchain

Koka provides a compiler. hica provides a workspace.

| Command | What it does |
|---------|-------------|
| `hica run file.hc` | Compile and run in one step |
| `hica test file.hc` | Run `test` blocks with built-in assertions |
| `hica check file.hc` | Analyse and report errors without building |
| `hica fmt file.hc` | Format source code |
| `hica repl` | Interactive read-eval-print loop |
| `hica new myproject` | Scaffold a new project |
| `hica build file.hc -o bin` | Build a standalone binary |
| `hica clean <file>` | Remove generated artifacts for a file |
| `hica clean --cache` | Remove the stdlib cache |

The test runner is built on [kunit](https://github.com/cladam/kunit), and the CLI argument parser on [klap](https://github.com/cladam/klap). Both are purpose-built Koka libraries that ship with hica. You do not install a test framework or argument parser separately; they are part of the toolchain.

Koka has `koka -e file.kk` to compile-and-run and `koka -o` to build, but testing, formatting, project scaffolding, and REPL are not built into the compiler workflow.

## HML: A Companion Configuration Language

hica has a purpose-built configuration library: [HML](https://github.com/cladam/hml) (Hica Markup Language). HML is a structured data format with first-class support for types like durations, date-times (RFC 3339), and tagged elements, primitives that most config languages encode as strings.

```
@server(port: 8080, public) {
    host: "localhost"
    timeout: 30s
    started: 2026-05-20T10:00:00Z
}
```

Add it as a submodule and import:

```sh
git submodule add https://github.com/cladam/hml.git lib/hml
```

```hica
import "./lib/hml/src/hml"
```

Koka has no companion config format; you would reach for JSON or YAML and write your own parsing layer.

## When to Use Which

**Use hica when:**

- You are learning your first compiled language
- You are teaching programming to students
- You want type safety and immutability without a steep learning curve
- You are building applications where you do not need custom effects
- You want a Rust-like syntax with automatic memory management

**Use Koka when:**

- You want to define and handle custom algebraic effects
- You are doing research in programming language theory
- You need fine-grained control over effect composition
- You have outgrown hica's feature set and want the full power underneath

## The Bridge

Because hica compiles to Koka, the transition is smooth:

1. **Import Koka modules from hica.** hica can import `.kk` files directly. Write a library in Koka, use it from hica.
2. **Read the generated code.** Run `hica build <file>.hc` to see the Koka output. As you learn, you will start recognising the patterns.
3. **Graduate when ready.** The concepts transfer: `match`, immutability, `Result`/`Maybe`, function composition are the same in both languages. Koka adds effects and handlers on top.

hica is not a replacement for Koka. It is a **front door**, a way in that does not require understanding row-typed effects before you can write hello world.

## Conclusion

Koka is a brilliant language with ideas that are ahead of their time. Its effect system is genuinely novel and powerful. But that power comes with a learning curve that puts it out of reach for many programmers.

hica keeps the parts that make Koka great (Perceus memory management, algebraic data types, expression-oriented design, compiled performance) and wraps them in a syntax and programming model that is immediately accessible. You lose custom effects and some type-system expressiveness. You gain an integrated toolchain, a companion config language, and a language you can teach in an afternoon.

In short: Koka provides the powerful underlying engine; hica provides a specific, ergonomic cockpit designed for building software tools quickly and safely.
