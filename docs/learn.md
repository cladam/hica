---
layout: default
title: Learn hica - hica
---

# Learn hica

A progressive set of 42 lessons that teach hica one concept at a time. Each lesson is a standalone `.hc` file you can run:

```sh
hica run learn/01-hello.hc
hica run learn/02-arrow.hc
```

| #  | File                  | Concept                          | What you'll learn                               |
| -- | --------------------- | -------------------------------- | ----------------------------------------------- |
| 01 | [`01-hello.hc`](https://github.com/cladam/hica/blob/main/learn/01-hello.hc)         | Hello, world!                    | `fun main()`, blocks, implicit return           |
| 02 | [`02-arrow.hc`](https://github.com/cladam/hica/blob/main/learn/02-arrow.hc)         | Expression-bodied functions      | The `=>` arrow, single-expression functions     |
| 03 | [`03-variables.hc`](https://github.com/cladam/hica/blob/main/learn/03-variables.hc)     | Variables and `let`              | `let` bindings, the last-line rule              |
| 04 | [`04-functions.hc`](https://github.com/cladam/hica/blob/main/learn/04-functions.hc)     | Functions and chaining           | Multiple functions, calling one from another    |
| 05 | [`05-if-else.hc`](https://github.com/cladam/hica/blob/main/learn/05-if-else.hc)       | Conditional expressions          | `if`/`else` as expressions, setting variables   |
| 06 | [`06-match.hc`](https://github.com/cladam/hica/blob/main/learn/06-match.hc)         | Pattern matching                 | `match` with integer patterns, wildcards `_`, match guards `if`, or-patterns `\|`, range patterns `..=` |
| 07 | [`07-logic.hc`](https://github.com/cladam/hica/blob/main/learn/07-logic.hc)         | Boolean logic                    | `&&`, comparisons, combining conditions         |
| 08 | [`08-fizzbuzz.hc`](https://github.com/cladam/hica/blob/main/learn/08-fizzbuzz.hc)      | Putting it all together          | `else if` chains, multi-step logic              |
| 09 | [`09-repeat.hc`](https://github.com/cladam/hica/blob/main/learn/09-repeat.hc)        | Repeating things                 | `repeat(n) { body }`, running code n times      |
| 10 | [`10-strings.hc`](https://github.com/cladam/hica/blob/main/learn/10-strings.hc)       | Strings                          | `+` concat, `"{}"` interpolation, `\"` `\\` `\n` `\t` `\{` `\}` escapes, `s[i]` indexing, `s[1:3]` slicing, utility functions |
| 11 | [`11-pipe.hc`](https://github.com/cladam/hica/blob/main/learn/11-pipe.hc)          | The pipe operator                | `\|>` to chain functions left to right          |
| 12 | [`12-floats.hc`](https://github.com/cladam/hica/blob/main/learn/12-floats.hc)        | Floating-point numbers           | Float literals (`3.14`), float arithmetic       |
| 13 | [`13-tuples.hc`](https://github.com/cladam/hica/blob/main/learn/13-tuples.hc)        | Tuples                           | `(a, b)` literals, `.0`/`.1`, destructuring     |
| 14 | [`14-lists.hc`](https://github.com/cladam/hica/blob/main/learn/14-lists.hc)         | Lists                            | `[1, 2, 3]` literals, homogeneous elements      |
| 15 | [`15-for.hc`](https://github.com/cladam/hica/blob/main/learn/15-for.hc)           | For loops                        | `for i in start..end { body }`, counted loops   |
| 16 | [`16-recursion.hc`](https://github.com/cladam/hica/blob/main/learn/16-recursion.hc)     | Recursion                        | Functions calling themselves, base cases        |
| 17 | [`17-chars.hc`](https://github.com/cladam/hica/blob/main/learn/17-chars.hc)         | Characters                       | `'c'` char literals, char lists, comparisons    |
| 18 | [`18-maybe.hc`](https://github.com/cladam/hica/blob/main/learn/18-maybe.hc)         | Maybe                            | `Some(x)`, `None`, matching on optional values  |
| 19 | [`19-result.hc`](https://github.com/cladam/hica/blob/main/learn/19-result.hc)        | Result                           | `Ok(x)`, `Err(e)`, handling success and failure |
| 20 | [`20-closures.hc`](https://github.com/cladam/hica/blob/main/learn/20-closures.hc)      | Closures                         | Capturing variables, returning functions, HOFs  |
| 21 | [`21-structs.hc`](https://github.com/cladam/hica/blob/main/learn/21-structs.hc)       | Structs                          | `struct` definitions, construction, field access |
| 22 | [`22-env.hc`](https://github.com/cladam/hica/blob/main/learn/22-env.hc)           | Environment                      | `get_args()`, `get_env(key)`, `eprintln`         |
| 23 | [`23-parsing.hc`](https://github.com/cladam/hica/blob/main/learn/23-parsing.hc)       | Parsing                          | `parse_int`, `parse_float`, safe string-to-number |
| 24 | [`24-while.hc`](https://github.com/cladam/hica/blob/main/learn/24-while.hc)         | While loops & var                | `var` mutable variables, `while` loops, reassignment |
| 25 | [`25-break-continue.hc`](https://github.com/cladam/hica/blob/main/learn/25-break-continue.hc)| Break, continue, and loop        | `break`, `continue`, `loop`, early exit from any loop |
| 26 | [`26-file-io.hc`](https://github.com/cladam/hica/blob/main/learn/26-file-io.hc)       | File I/O                         | `read_file`, `write_file`, `unwrap`, `unwrap_or`; `read_lines`, `write_lines` (`import "std/io"`) |
| 27 | [`27-input.hc`](https://github.com/cladam/hica/blob/main/learn/27-input.hc)         | User input                       | `input(prompt)`, combining with `parse_int`, interactive programs |
| 28 | [`28-random.hc`](https://github.com/cladam/hica/blob/main/learn/28-random.hc)        | Random numbers                   | `random(min, max)`, non-determinism, dice and coin examples |
| 29 | [`29-format.hc`](https://github.com/cladam/hica/blob/main/learn/29-format.hc)        | Formatted output                 | `show_fixed`, `pad_left`, `pad_right`, aligned tables |
| 30 | [`30-maps.hc`](https://github.com/cladam/hica/blob/main/learn/30-maps.hc)          | Maps                             | `{"key": value}` literals, `{:}` empty map, `map_get`, `map_set`, `map_remove` |
| 31 | [`31-enums.hc`](https://github.com/cladam/hica/blob/main/learn/31-enums.hc)         | Enum types                       | `type` declarations, variants with data, constructors, pattern matching on enums |
| 32 | [`32-combinators.hc`](https://github.com/cladam/hica/blob/main/learn/32-combinators.hc)   | Combinators                      | `map_maybe`, `and_then`, `unwrap_maybe`, `map_result`, `and_then_result`, pipe-friendly chaining |
| 33 | [`33-imports.hc`](https://github.com/cladam/hica/blob/main/learn/33-imports.hc)       | Imports                          | `import`, `from ... import { }`, `pub import`, modules, `pub` visibility |
| 34 | [`34-struct-patterns.hc`](https://github.com/cladam/hica/blob/main/learn/34-struct-patterns.hc) | Struct patterns            | Struct destructuring in `match`, partial patterns, literal fields |
| 35 | [`35-slice-patterns.hc`](https://github.com/cladam/hica/blob/main/learn/35-slice-patterns.hc) | Slice patterns              | List destructuring `[]`, `[x]`, `[x, ..rest]`, recursive processing |
| 36 | [`36-try.hc`](https://github.com/cladam/hica/blob/main/learn/36-try.hc) | `?` operator (early return)    | When a function returns `maybe`, the `?` operator saves you from writing nested matches. |
| 37 | [`37-list-extras.hc`](https://github.com/cladam/hica/blob/main/learn/37-list-extras.hc) | List extras                | `head`, `tail`, `last`, `flat_map`, `sort_by`, `sum`, `product`, `unique`, `intersperse`, `zip_with`, `scan`, `chunks` |
| 38 | [`38-math-extras.hc`](https://github.com/cladam/hica/blob/main/learn/38-math-extras.hc) | Math & float extras        | `lcm`, `pow`, `sign`, `sqrt`, `floor`, `ceil`, `round`, `to_float`, `chars`, `from_chars` |
| 39 | [`39-datetime.hc`](https://github.com/cladam/hica/blob/main/learn/39-datetime.hc) | Dates & times              | `is_valid_date`, `datetime_kind`, `date_parts`, `time_parts`, `is_before`, `day_of_week`, `offset_to_minutes` (`import "std/datetime"`) |
| 40 | [`40-glob.hc`](https://github.com/cladam/hica/blob/main/learn/40-glob.hc)     | Glob matching & char classification | `is_digit`, `is_alpha`, `is_upper`, `is_lower`, `all_digits`, `all_upper`, `glob_match`, `glob_match_path` |
| 41 | [`41-opaque-struct.hc`](https://github.com/cladam/hica/blob/main/learn/41-opaque-struct.hc) | Opaque Structs | `opaque struct`, `pub struct ... priv`, private constructors, type-safe boundaries |
| 42 | [`42-streams.hc`](https://github.com/cladam/hica/blob/main/learn/42-streams.hc) | Lazy Streams | `stream`, lazy pipelines (`filter`, `map`, `take`), terminators (`collect`, `fold`), zero-allocation efficiency |

## Language features shown

| Feature                        | Where to look                         |
| ------------------------------ | ------------------------------------- |
| Implicit return (last line)    | [`01-hello.hc`](https://github.com/cladam/hica/blob/main/learn/01-hello.hc), [`03-variables.hc`](https://github.com/cladam/hica/blob/main/learn/03-variables.hc)      |
| `=>` arrow bodies              | [`02-arrow.hc`](https://github.com/cladam/hica/blob/main/learn/02-arrow.hc), [`04-functions.hc`](https://github.com/cladam/hica/blob/main/learn/04-functions.hc)      |
| `let` bindings                 | [`03-variables.hc`](https://github.com/cladam/hica/blob/main/learn/03-variables.hc), [`04-functions.hc`](https://github.com/cladam/hica/blob/main/learn/04-functions.hc)  |
| `if`/`else` expressions        | [`05-if-else.hc`](https://github.com/cladam/hica/blob/main/learn/05-if-else.hc), [`07-logic.hc`](https://github.com/cladam/hica/blob/main/learn/07-logic.hc)        |
| `else if` chains               | [`08-fizzbuzz.hc`](https://github.com/cladam/hica/blob/main/learn/08-fizzbuzz.hc)                      |
| `match` + wildcards            | [`06-match.hc`](https://github.com/cladam/hica/blob/main/learn/06-match.hc)                         |
| Match guards (`if`)            | [`06-match.hc`](https://github.com/cladam/hica/blob/main/learn/06-match.hc)                         |
| Or-patterns (`\|`)             | [`06-match.hc`](https://github.com/cladam/hica/blob/main/learn/06-match.hc)                         |
| Range patterns (`..=`)         | [`06-match.hc`](https://github.com/cladam/hica/blob/main/learn/06-match.hc)                         |
| `&&` boolean operators         | [`07-logic.hc`](https://github.com/cladam/hica/blob/main/learn/07-logic.hc)                         |
| Nested conditionals            | [`08-fizzbuzz.hc`](https://github.com/cladam/hica/blob/main/learn/08-fizzbuzz.hc)                      |
| Unary negation (`-x`)          | [`05-if-else.hc`](https://github.com/cladam/hica/blob/main/learn/05-if-else.hc)                       |
| `repeat(n) { ... }`            | [`09-repeat.hc`](https://github.com/cladam/hica/blob/main/learn/09-repeat.hc)                        |
| String concatenation (`+`)     | [`10-strings.hc`](https://github.com/cladam/hica/blob/main/learn/10-strings.hc)                       |
| String interpolation (`{}`)    | [`10-strings.hc`](https://github.com/cladam/hica/blob/main/learn/10-strings.hc)                       |
| String indexing (`s[0]`)       | [`10-strings.hc`](https://github.com/cladam/hica/blob/main/learn/10-strings.hc)                       |
| String slicing (`s[1:3]`)      | [`10-strings.hc`](https://github.com/cladam/hica/blob/main/learn/10-strings.hc)                       |
| String utility functions       | [`10-strings.hc`](https://github.com/cladam/hica/blob/main/learn/10-strings.hc)                       |
| Pipe operator (`\|>`)          | [`11-pipe.hc`](https://github.com/cladam/hica/blob/main/learn/11-pipe.hc)                          |
| Float literals (`3.14`)        | [`12-floats.hc`](https://github.com/cladam/hica/blob/main/learn/12-floats.hc)                        |
| Tuples `(a, b)`                | [`13-tuples.hc`](https://github.com/cladam/hica/blob/main/learn/13-tuples.hc)                        |
| Tuple access `.0`, `.1`        | [`13-tuples.hc`](https://github.com/cladam/hica/blob/main/learn/13-tuples.hc)                        |
| Tuple destructuring            | [`13-tuples.hc`](https://github.com/cladam/hica/blob/main/learn/13-tuples.hc)                        |
| Lists `[1, 2, 3]`              | [`14-lists.hc`](https://github.com/cladam/hica/blob/main/learn/14-lists.hc)                         |
| `for i in start..end`          | [`15-for.hc`](https://github.com/cladam/hica/blob/main/learn/15-for.hc)                           |
| `for x in list`                | [`15-for.hc`](https://github.com/cladam/hica/blob/main/learn/15-for.hc)                           |
| Recursion (self-calling fns)   | [`16-recursion.hc`](https://github.com/cladam/hica/blob/main/learn/16-recursion.hc)                     |
| Character literals `'c'`       | [`17-chars.hc`](https://github.com/cladam/hica/blob/main/learn/17-chars.hc)                         |
| `Some(x)` / `None` (maybe)     | [`18-maybe.hc`](https://github.com/cladam/hica/blob/main/learn/18-maybe.hc)                         |
| `Ok(x)` / `Err(e)` (result)    | [`19-result.hc`](https://github.com/cladam/hica/blob/main/learn/19-result.hc)                        |
| Closures / capturing variables | [`20-closures.hc`](https://github.com/cladam/hica/blob/main/learn/20-closures.hc)                      |
| Returning functions            | [`20-closures.hc`](https://github.com/cladam/hica/blob/main/learn/20-closures.hc)                      |
| Higher-order functions (custom)| [`20-closures.hc`](https://github.com/cladam/hica/blob/main/learn/20-closures.hc)                      |
| Struct definitions             | [`21-structs.hc`](https://github.com/cladam/hica/blob/main/learn/21-structs.hc)                       |
| Struct construction            | [`21-structs.hc`](https://github.com/cladam/hica/blob/main/learn/21-structs.hc)                       |
| Field access (`.field`)        | [`21-structs.hc`](https://github.com/cladam/hica/blob/main/learn/21-structs.hc)                       |
| `get_args()`                   | [`22-env.hc`](https://github.com/cladam/hica/blob/main/learn/22-env.hc)                           |
| `get_env(key)`                 | [`22-env.hc`](https://github.com/cladam/hica/blob/main/learn/22-env.hc)                           |
| `eprintln` (stderr output)     | [`22-env.hc`](https://github.com/cladam/hica/blob/main/learn/22-env.hc)                           |
| `parse_int`, `parse_float`     | [`23-parsing.hc`](https://github.com/cladam/hica/blob/main/learn/23-parsing.hc)                       |
| `var` mutable variables        | [`24-while.hc`](https://github.com/cladam/hica/blob/main/learn/24-while.hc)                         |
| `while` loops                  | [`24-while.hc`](https://github.com/cladam/hica/blob/main/learn/24-while.hc)                         |
| Reassignment (`x = expr`)      | [`24-while.hc`](https://github.com/cladam/hica/blob/main/learn/24-while.hc)                         |
| `break`                        | [`25-break-continue.hc`](https://github.com/cladam/hica/blob/main/learn/25-break-continue.hc)                |
| `continue`                     | [`25-break-continue.hc`](https://github.com/cladam/hica/blob/main/learn/25-break-continue.hc)                |
| `loop { ... }`                 | [`25-break-continue.hc`](https://github.com/cladam/hica/blob/main/learn/25-break-continue.hc)                |
| `read_file`, `write_file`      | [`26-file-io.hc`](https://github.com/cladam/hica/blob/main/learn/26-file-io.hc)                       |
| `unwrap`, `unwrap_or`          | [`26-file-io.hc`](https://github.com/cladam/hica/blob/main/learn/26-file-io.hc)                       |
| `read_lines`, `write_lines`    | [`26-file-io.hc`](https://github.com/cladam/hica/blob/main/learn/26-file-io.hc) (`import "std/io"`) |
| `random(min, max)`             | [`28-random.hc`](https://github.com/cladam/hica/blob/main/learn/28-random.hc)                        |
| `show_fixed`, `pad_left/right` | [`29-format.hc`](https://github.com/cladam/hica/blob/main/learn/29-format.hc)                        |
| Map literals `{"k": v}`       | [`30-maps.hc`](https://github.com/cladam/hica/blob/main/learn/30-maps.hc)                          |
| `map_get`, `map_set`, etc.     | [`30-maps.hc`](https://github.com/cladam/hica/blob/main/learn/30-maps.hc)                          |
| `type` declarations (enums)   | [`31-enums.hc`](https://github.com/cladam/hica/blob/main/learn/31-enums.hc)                         |
| Enum constructors              | [`31-enums.hc`](https://github.com/cladam/hica/blob/main/learn/31-enums.hc)                         |
| Pattern matching on enums      | [`31-enums.hc`](https://github.com/cladam/hica/blob/main/learn/31-enums.hc)                         |
| `input(prompt)`                | [`27-input.hc`](https://github.com/cladam/hica/blob/main/learn/27-input.hc)                         |
| `random(min, max)`             | [`28-random.hc`](https://github.com/cladam/hica/blob/main/learn/28-random.hc)                        |
| `show_fixed(value, decimals)`  | [`29-format.hc`](https://github.com/cladam/hica/blob/main/learn/29-format.hc)                        |
| `pad_left`, `pad_right`        | [`29-format.hc`](https://github.com/cladam/hica/blob/main/learn/29-format.hc)                        |
| Maps `{"k": v}`                | [`30-maps.hc`](https://github.com/cladam/hica/blob/main/learn/30-maps.hc)                          |
| `map_get`, `map_set`           | [`30-maps.hc`](https://github.com/cladam/hica/blob/main/learn/30-maps.hc)                          |
| `map_remove`, `map_keys`       | [`30-maps.hc`](https://github.com/cladam/hica/blob/main/learn/30-maps.hc)                          |
| `map_contains_key`, `map_size` | [`30-maps.hc`](https://github.com/cladam/hica/blob/main/learn/30-maps.hc)                          |
| `map_maybe`, `and_then`        | [`32-combinators.hc`](https://github.com/cladam/hica/blob/main/learn/32-combinators.hc)                   |
| `map_result`, `map_err`        | [`32-combinators.hc`](https://github.com/cladam/hica/blob/main/learn/32-combinators.hc)                   |
| `unwrap_maybe`, `is_some`      | [`32-combinators.hc`](https://github.com/cladam/hica/blob/main/learn/32-combinators.hc)                   |
| `pub` visibility               | [`33-imports.hc`](https://github.com/cladam/hica/blob/main/learn/33-imports.hc), [`greet.hc`](https://github.com/cladam/hica/blob/main/examples/greet.hc)  |
| `import` (all pub items)       | [`33-imports.hc`](https://github.com/cladam/hica/blob/main/learn/33-imports.hc), [`import.hc`](https://github.com/cladam/hica/blob/main/examples/import.hc) |
| `from ... import { }`          | [`33-imports.hc`](https://github.com/cladam/hica/blob/main/learn/33-imports.hc), [`import-selective.hc`](https://github.com/cladam/hica/blob/main/examples/import-selective.hc) |
| `pub import` (re-export)       | [`33-imports.hc`](https://github.com/cladam/hica/blob/main/learn/33-imports.hc)                       |
| Type annotations (`: int`)     | [`type-annotations.hc`](https://github.com/cladam/hica/blob/main/examples/type-annotations.hc)        |
| Struct destructuring patterns   | [`34-struct-patterns.hc`](https://github.com/cladam/hica/blob/main/learn/34-struct-patterns.hc), [`struct-patterns.hc`](https://github.com/cladam/hica/blob/main/examples/struct-patterns.hc) |
| List slice patterns `[x, ..rest]`| [`35-slice-patterns.hc`](https://github.com/cladam/hica/blob/main/learn/35-slice-patterns.hc), [`slice-patterns.hc`](https://github.com/cladam/hica/blob/main/examples/slice-patterns.hc) |
| `?` operator (early return)    | [`36-try.hc`](https://github.com/cladam/hica/blob/main/learn/36-try.hc) |
| `is_digit`, `is_alpha`, etc.   | [`40-glob.hc`](https://github.com/cladam/hica/blob/main/learn/40-glob.hc)                          |
| `all_digits`, `all_upper`      | [`40-glob.hc`](https://github.com/cladam/hica/blob/main/learn/40-glob.hc)                          |
| `glob_match`                   | [`40-glob.hc`](https://github.com/cladam/hica/blob/main/learn/40-glob.hc)                          |
| `glob_match_path`              | [`40-glob.hc`](https://github.com/cladam/hica/blob/main/learn/40-glob.hc)                          |
| `println()`                    | [`01-hello.hc`](https://github.com/cladam/hica/blob/main/learn/01-hello.hc), [`09-repeat.hc`](https://github.com/cladam/hica/blob/main/learn/09-repeat.hc)         |

## Getting Started

Make sure you have the hica compiler built, then work through the lessons in order. Each one builds on the previous:

```sh
./hica run learn/01-hello.hc
```
