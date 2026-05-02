---
layout: default
title: Learn hica - hica
---

# Learn hica

A progressive set of 20 lessons that teach hica one concept at a time. Each lesson is a standalone `.hc` file you can run:

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
| 06 | [`06-match.hc`](https://github.com/cladam/hica/blob/main/learn/06-match.hc) | Pattern matching | `match` with integer patterns, wildcards `_` |
| 07 | [`07-logic.hc`](https://github.com/cladam/hica/blob/main/learn/07-logic.hc) | Boolean logic | `&&`, comparisons, combining conditions |
| 08 | [`08-fizzbuzz.hc`](https://github.com/cladam/hica/blob/main/learn/08-fizzbuzz.hc) | Putting it all together | `else if` chains, multi-step logic |
| 09 | [`09-repeat.hc`](https://github.com/cladam/hica/blob/main/learn/09-repeat.hc) | Repeating things | `repeat(n) { body }`, running code n times |
| 10 | [`10-strings.hc`](https://github.com/cladam/hica/blob/main/learn/10-strings.hc) | Strings | `+` concatenation, `"{expr}"` interpolation |
| 11 | [`11-pipe.hc`](https://github.com/cladam/hica/blob/main/learn/11-pipe.hc) | The pipe operator | `&#124;>` to chain functions left to right |
| 12 | [`12-floats.hc`](https://github.com/cladam/hica/blob/main/learn/12-floats.hc) | Floating-point numbers | Float literals (`3.14`), float arithmetic |
| 13 | [`13-tuples.hc`](https://github.com/cladam/hica/blob/main/learn/13-tuples.hc) | Tuples | `(a, b)` literals, `.0`/`.1`, destructuring |
| 14 | [`14-lists.hc`](https://github.com/cladam/hica/blob/main/learn/14-lists.hc) | Lists | `[1, 2, 3]` literals, homogeneous elements |
| 15 | [`15-for.hc`](https://github.com/cladam/hica/blob/main/learn/15-for.hc) | For loops | `for i in start..end { body }`, counted loops |
| 16 | [`16-recursion.hc`](https://github.com/cladam/hica/blob/main/learn/16-recursion.hc) | Recursion | Functions calling themselves, base cases |
| 17 | [`17-chars.hc`](https://github.com/cladam/hica/blob/main/learn/17-chars.hc) | Characters | `'c'` char literals, char lists, comparisons |
| 18 | [`18-maybe.hc`](https://github.com/cladam/hica/blob/main/learn/18-maybe.hc) | Maybe | `Some(x)`, `None`, matching on optional values |
| 19 | [`19-result.hc`](https://github.com/cladam/hica/blob/main/learn/19-result.hc) | Result | `Ok(x)`, `Err(e)`, handling success and failure |
| 20 | [`20-closures.hc`](https://github.com/cladam/hica/blob/main/learn/20-closures.hc) | Closures | Capturing variables, returning functions, HOFs |

## Feature Index

| Feature | Where to look |
|---------|---------------|
| Implicit return (last line) | `01-hello.hc`, `03-variables.hc` |
| `=>` arrow bodies | `02-arrow.hc`, `04-functions.hc` |
| `let` bindings | `03-variables.hc`, `04-functions.hc` |
| `if`/`else` expressions | `05-if-else.hc`, `07-logic.hc` |
| `else if` chains | `08-fizzbuzz.hc` |
| `match` + wildcards | `06-match.hc` |
| `&&` boolean operators | `07-logic.hc` |
| `repeat(n) { }` | `09-repeat.hc` |
| String interpolation | `10-strings.hc` |
| Pipe `&#124;>` operator | `11-pipe.hc` |
| Float arithmetic | `12-floats.hc` |
| Tuples and destructuring | `13-tuples.hc` |
| Lists and `map`/`filter` | `14-lists.hc` |
| For-range loops | `15-for.hc` |
| Recursion | `16-recursion.hc` |
| Char type | `17-chars.hc` |
| `Some`/`None` | `18-maybe.hc` |
| `Ok`/`Err` | `19-result.hc` |
| Closures and HOFs | `20-closures.hc` |

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
