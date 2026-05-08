---
layout: default
title: Learn hica - hica
---

# Learn hica

A progressive set of 27 lessons that teach hica one concept at a time. Each lesson is a standalone `.hc` file you can run:

```sh
./hica run learn/01-hello.hc
./hica run learn/02-arrow.hc
```

## Lessons

| # | File | Concept | What you'll learn |
|---|------|---------|-------------------|
| 01 | [`01-hello.hc`](https://github.com/cladam/hica/blob/main/learn/01-hello.hc) | Hello, world! | `fun main()`, blocks, implicit return |
| 02 | [`02-arrow.hc`](https://github.com/cladam/hica/blob/main/learn/02-arrow.hc) | Expression-bodied functions | The `=>` arrow, single-expression functions |
| 03 | [`03-variables.hc`](https://github.com/cladam/hica/blob/main/learn/03-variables.hc) | Variables and `let` | `let` bindings, the last-line rule |
| 04 | [`04-functions.hc`](https://github.com/cladam/hica/blob/main/learn/04-functions.hc) | Functions and chaining | Multiple functions, calling one from another |
| 05 | [`05-if-else.hc`](https://github.com/cladam/hica/blob/main/learn/05-if-else.hc) | Conditional expressions | `if`/`else` as expressions, setting variables |
| 06 | [`06-match.hc`](https://github.com/cladam/hica/blob/main/learn/06-match.hc) | Pattern matching | `match` with integer patterns, wildcards `_`, match guards, or-patterns, range patterns `..=` |
| 07 | [`07-logic.hc`](https://github.com/cladam/hica/blob/main/learn/07-logic.hc) | Boolean logic | `&&`, comparisons, combining conditions |
| 08 | [`08-fizzbuzz.hc`](https://github.com/cladam/hica/blob/main/learn/08-fizzbuzz.hc) | Putting it all together | `else if` chains, multi-step logic |
| 09 | [`09-repeat.hc`](https://github.com/cladam/hica/blob/main/learn/09-repeat.hc) | Repeating things | `repeat(n) { body }`, running code n times |
| 10 | [`10-strings.hc`](https://github.com/cladam/hica/blob/main/learn/10-strings.hc) | Strings | `+` concat, `"{}"` interpolation, `s[i]` indexing, `s[1:3]` slicing, utility functions |
| 11 | [`11-pipe.hc`](https://github.com/cladam/hica/blob/main/learn/11-pipe.hc) | The pipe operator | `|>` to chain functions left to right |
| 12 | [`12-floats.hc`](https://github.com/cladam/hica/blob/main/learn/12-floats.hc) | Floating-point numbers | Float literals (`3.14`), float arithmetic |
| 13 | [`13-tuples.hc`](https://github.com/cladam/hica/blob/main/learn/13-tuples.hc) | Tuples | `(a, b)` literals, `.0`/`.1`, destructuring |
| 14 | [`14-lists.hc`](https://github.com/cladam/hica/blob/main/learn/14-lists.hc) | Lists | `[1, 2, 3]` literals, homogeneous elements |
| 15 | [`15-for.hc`](https://github.com/cladam/hica/blob/main/learn/15-for.hc) | For loops | `for i in start..end { body }`, counted loops |
| 16 | [`16-recursion.hc`](https://github.com/cladam/hica/blob/main/learn/16-recursion.hc) | Recursion | Functions calling themselves, base cases |
| 17 | [`17-chars.hc`](https://github.com/cladam/hica/blob/main/learn/17-chars.hc) | Characters | `'c'` char literals, char lists, comparisons |
| 18 | [`18-maybe.hc`](https://github.com/cladam/hica/blob/main/learn/18-maybe.hc) | Maybe | `Some(x)`, `None`, matching on optional values |
| 19 | [`19-result.hc`](https://github.com/cladam/hica/blob/main/learn/19-result.hc) | Result | `Ok(x)`, `Err(e)`, handling success and failure |
| 20 | [`20-closures.hc`](https://github.com/cladam/hica/blob/main/learn/20-closures.hc) | Closures | Capturing variables, returning functions, HOFs |
| 21 | [`21-structs.hc`](https://github.com/cladam/hica/blob/main/learn/21-structs.hc) | Structs | `struct` definitions, construction, field access |
| 22 | [`22-env.hc`](https://github.com/cladam/hica/blob/main/learn/22-env.hc) | Environment | `get_args()`, `get_env(key)`, `eprintln` |
| 23 | [`23-parsing.hc`](https://github.com/cladam/hica/blob/main/learn/23-parsing.hc) | Parsing | `parse_int`, `parse_float`, safe string-to-number |
| 24 | [`24-while.hc`](https://github.com/cladam/hica/blob/main/learn/24-while.hc) | While loops & var | `var` mutable variables, `while` loops, reassignment |
| 25 | [`25-break-continue.hc`](https://github.com/cladam/hica/blob/main/learn/25-break-continue.hc) | Break, continue, and loop | `break`, `continue`, `loop`, early exit from any loop |
| 26 | [`26-file-io.hc`](https://github.com/cladam/hica/blob/main/learn/26-file-io.hc) | File I/O | `read_file`, `write_file`, `read_lines`, `write_lines` |
| 27 | [`27-input.hc`](https://github.com/cladam/hica/blob/main/learn/27-input.hc) | User input | `input(prompt)`, combining with `parse_int`, interactive programs |
| 28 | `28-random.hc`        | Random numbers                   | `random(min, max)`, non-determinism, dice and coin examples |
| 29 | `29-format.hc`        | Formatted output                 | `show_fixed`, `pad_left`, `pad_right`, aligned tables |


## Feature Index

| Feature                        | Where to look                         |
| ------------------------------ | ------------------------------------- |
| Implicit return (last line)    | `01-hello.hc`, `03-variables.hc`      |
| `=>` arrow bodies              | `02-arrow.hc`, `04-functions.hc`      |
| `let` bindings                 | `03-variables.hc`, `04-functions.hc`  |
| `if`/`else` expressions        | `05-if-else.hc`, `07-logic.hc`        |
| `else if` chains               | `08-fizzbuzz.hc`                      |
| `match` + wildcards            | `06-match.hc`                         |
| Match guards (`if`)            | `06-match.hc`                         |
| Or-patterns (`\|`)             | `06-match.hc`                         |
| Range patterns (`..=`)         | `06-match.hc`                         |
| `&&` boolean operators         | `07-logic.hc`                         |
| Nested conditionals            | `08-fizzbuzz.hc`                      |
| Unary negation (`-x`)          | `05-if-else.hc`                       |
| `repeat(n) { ... }`            | `09-repeat.hc`                        |
| String concatenation (`+`)     | `10-strings.hc`                       |
| String interpolation (`{}`)    | `10-strings.hc`                       |
| String indexing (`s[0]`)       | `10-strings.hc`                       |
| String slicing (`s[1:3]`)      | `10-strings.hc`                       |
| String utility functions       | `10-strings.hc`                       |
| Pipe operator (`\|>`)          | `11-pipe.hc`                          |
| Float literals (`3.14`)        | `12-floats.hc`                        |
| Tuples `(a, b)`                | `13-tuples.hc`                        |
| Tuple access `.0`, `.1`        | `13-tuples.hc`                        |
| Tuple destructuring            | `13-tuples.hc`                        |
| Lists `[1, 2, 3]`              | `14-lists.hc`                         |
| `for i in start..end`          | `15-for.hc`                           |
| `for x in list`                | `15-for.hc`                           |
| Recursion (self-calling fns)   | `16-recursion.hc`                     |
| Character literals `'c'`       | `17-chars.hc`                         |
| `Some(x)` / `None` (maybe)     | `18-maybe.hc`                         |
| `Ok(x)` / `Err(e)` (result)    | `19-result.hc`                        |
| Closures / capturing variables | `20-closures.hc`                      |
| Returning functions            | `20-closures.hc`                      |
| Higher-order functions (custom)| `20-closures.hc`                      |
| Struct definitions             | `21-structs.hc`                       |
| Struct construction            | `21-structs.hc`                       |
| Field access (`.field`)        | `21-structs.hc`                       |
| `get_args()`                   | `22-env.hc`                           |
| `get_env(key)`                 | `22-env.hc`                           |
| `eprintln` (stderr output)     | `22-env.hc`                           |
| `parse_int`, `parse_float`     | `23-parsing.hc`                       |
| `var` mutable variables        | `24-while.hc`                         |
| `while` loops                  | `24-while.hc`                         |
| Reassignment (`x = expr`)      | `24-while.hc`                         |
| `break`                        | `25-break-continue.hc`                |
| `continue`                     | `25-break-continue.hc`                |
| `loop { ... }`                 | `25-break-continue.hc`                |
| `read_file`, `write_file`      | `26-file-io.hc`                       |
| `unwrap`, `unwrap_or`          | `26-file-io.hc`                       |
| `read_lines`, `write_lines`    | `26-file-io.hc`                       |
| `input(prompt)`                | `27-input.hc`                         |
| `random(min, max)`             | `28-random.hc`                        |
| `show_fixed(value, decimals)`  | `29-format.hc`                        |
| `pad_left`, `pad_right`        | `29-format.hc`                        |
| `pub` visibility               | `examples/match.hc` (module prep)     |
| Type annotations (`: int`)     | `examples/type-annotations.hc`        |
| `println()`                    | `01-hello.hc`, `09-repeat.hc`         |

## Getting Started

Make sure you have the hica compiler built:

```sh
koka -O2 -ilib/klap -isrc src/main.kk -o hica
chmod +x hica
```

Then work through the lessons in order. Each one builds on the previous:

```sh
./hica run learn/01-hello.hc
```
