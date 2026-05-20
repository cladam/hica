---
layout: default
title: REPL Playbook - hica
---

# REPL Playbook

Interactive reference for the hica REPL. Covers expressions, definitions,
type queries, file loading, and workflow patterns.

## Getting Started

```sh
hica repl                       # launch (auto-wraps with rlwrap if available)
hica repl lib/mylib.hc          # launch with a file preloaded
```

Tab completion, arrow-key history, and line editing are provided automatically
when `rlwrap` is installed. The REPL writes a completions file with all
prelude names, keywords, and commands.

## Expressions

Arithmetic, strings, lists — anything that evaluates to a value.

```hica
hica=> 2 + 3
5
hica=> "hello" + " " + "world"
hello world
hica=> [1, 2, 3] |> map(fn(x) { x * x })
[1, 4, 9]
```

`_` holds the last expression result:

```hica
hica=> 6 * 7
42
hica=> _ + 8
50
```

Note: `_` captures the *return value*, not what was printed.
`println("hi")` prints `hi` but returns `()`, so `_` becomes `()`.
Use a bare expression to capture a value:

```hica
hica=> "hi"
hi
hica=> _ + " there"
hi there
```

## Bindings

`let` creates a named value that persists for the session.

```hica
hica=> let tau = 6.283
6.283
hica=> let xs = [10, 20, 30]
[10, 20, 30]
hica=> xs |> length
3
```

## Functions

Single-line or multiline. The REPL continues reading when braces are
unbalanced (`...>` prompt).

```hica
hica=> fun square(n: int): int { n * n }
  defined: square

hica=> fun fib(n: int): int {
...>   if n <= 1 { n } else { fib(n - 1) + fib(n - 2) }
...> }
  defined: fib
hica=> fib(10)
55
```

## Structs and Enums

```hica
hica=> struct Point { x: int, y: int }
  defined: struct Point
hica=> let p = Point(3, 4)
Point(3, 4)
hica=> p.x + p.y
7

hica=> type Color { Red, Green, Blue }
  defined: type Color
hica=> match Green { Red => 0, Green => 1, Blue => 2 }
1
```

## Pattern Matching

```hica
hica=> fun classify(n: int): string {
...>   match n {
...>     0 => "zero",
...>     1 => "one",
...>     _ => "other: " + n.show
...>   }
...> }
  defined: classify
hica=> classify(42)
other: 42
```

## Type Queries

Inspect types without evaluating. Works on expressions, bindings, and
function declarations.

```hica
hica=> :t 1 + 2
  int
hica=> :t "hello" |> length
  int
hica=> :t [1, 2, 3]
  list<int>
hica=> :t fun add(a: int, b: int): int { a + b }
  (a: int, b: int) : int
```

## Loading Files

```hica
hica=> :load examples/fizzbuzz.hc
  loading examples/fizzbuzz.hc
  loaded: fizzbuzz
hica=> fizzbuzz(15)
FizzBuzz
```

## Startup File

`~/.hicarc` is loaded automatically on every REPL launch. Put frequently
used helpers here:

```hica
fun is_even(n: int): bool { n % 2 == 0 }
fun clamp(v: int, lo: int, hi: int): int { min(max(v, lo), hi) }
```

## Commands

| Command        | Action                                |
|----------------|---------------------------------------|
| `:help`, `:h`  | Show available commands               |
| `:defs`        | List current definitions              |
| `:type EXPR`   | Show inferred type of expression      |
| `:t EXPR`      | Short form of `:type`                 |
| `:load FILE`   | Load definitions from a `.hc` file    |
| `:reset`       | Clear all definitions and state       |
| `:history`     | Show recent input history             |
| `:quit`, `:q`  | Exit (or Ctrl-D)                      |

## Workflow Tips

- **Tab completion**: prelude functions, keywords, and commands are all
  completable. Install `rlwrap` for the best experience.
- **`_` chains**: pipe the last result forward: `_ |> filter(fn(x) { x > 0 })`.
- **`:t` before you run**: check types to catch mistakes before evaluation.
- **Incremental builds**: define, test, refine. `:defs` shows accumulated state.
- **`:reset`**: clean slate without restarting.
- **Multiline**: unbalanced `{`, `(`, `[` trigger continuation. Close all
  brackets to submit. If stuck, type `}` and Enter.
- **Preload**: `hica repl mylib.hc` starts with definitions already available.
- **Pipe-friendly**: stdin piping works: `echo '1 + 2' | hica repl`.
