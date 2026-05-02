# Learn Hica

A progressive set of lessons that teach Hica one concept at a time.

Each lesson is a standalone `.hc` file you can run:

```sh
./hica run learn/01-hello.hc
./hica run learn/02-arrow.hc
# ... etc
```

## Lessons

| #  | File                  | Concept                          | What you'll learn                               |
| -- | --------------------- | -------------------------------- | ----------------------------------------------- |
| 01 | `01-hello.hc`         | Hello, world!                    | `fun main()`, blocks, implicit return           |
| 02 | `02-arrow.hc`         | Expression-bodied functions      | The `=>` arrow, single-expression functions     |
| 03 | `03-variables.hc`     | Variables and `let`              | `let` bindings, the last-line rule              |
| 04 | `04-functions.hc`     | Functions and chaining           | Multiple functions, calling one from another    |
| 05 | `05-if-else.hc`       | Conditional expressions          | `if`/`else` as expressions, setting variables   |
| 06 | `06-match.hc`         | Pattern matching                 | `match` with integer patterns, wildcards `_`    |
| 07 | `07-logic.hc`         | Boolean logic                    | `&&`, comparisons, combining conditions         |
| 08 | `08-fizzbuzz.hc`      | Putting it all together          | `else if` chains, multi-step logic              |
| 09 | `09-repeat.hc`        | Repeating things                 | `repeat(n) { body }`, running code n times      |
| 10 | `10-strings.hc`       | Strings                          | `+` concatenation, `"{expr}"` interpolation     |
| 11 | `11-pipe.hc`          | The pipe operator                | `\|>` to chain functions left to right          |
| 12 | `12-floats.hc`        | Floating-point numbers           | Float literals (`3.14`), float arithmetic       |
| 13 | `13-tuples.hc`        | Tuples                           | `(a, b)` literals, `.0`/`.1`, destructuring     |
| 14 | `14-lists.hc`         | Lists                            | `[1, 2, 3]` literals, homogeneous elements      |
| 15 | `15-for.hc`           | For loops                        | `for i in start..end { body }`, counted loops   |
| 16 | `16-recursion.hc`     | Recursion                        | Functions calling themselves, base cases        |
| 17 | `17-chars.hc`         | Characters                       | `'c'` char literals, char lists, comparisons    |
| 18 | `18-maybe.hc`         | Maybe                            | `Some(x)`, `None`, matching on optional values  |
| 19 | `19-result.hc`        | Result                           | `Ok(x)`, `Err(e)`, handling success and failure |
| 20 | `20-closures.hc`      | Closures                         | Capturing variables, returning functions, HOFs  |

## Language features shown

| Feature                        | Where to look                         |
| ------------------------------ | ------------------------------------- |
| Implicit return (last line)    | `01-hello.hc`, `03-variables.hc`      |
| `=>` arrow bodies              | `02-arrow.hc`, `04-functions.hc`      |
| `let` bindings                 | `03-variables.hc`, `04-functions.hc`  |
| `if`/`else` expressions        | `05-if-else.hc`, `07-logic.hc`        |
| `else if` chains               | `08-fizzbuzz.hc`                      |
| `match` + wildcards            | `06-match.hc`                         |
| `&&` boolean operators         | `07-logic.hc`                         |
| Nested conditionals            | `08-fizzbuzz.hc`                      |
| Unary negation (`-x`)          | `05-if-else.hc`                       |
| `repeat(n) { ... }`            | `09-repeat.hc`                        |
| String concatenation (`+`)     | `10-strings.hc`                       |
| String interpolation (`{}`)    | `10-strings.hc`                       |
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
| Type annotations (`: int`)     | `examples/type-annotations.hc`        |
| `println()`                    | `01-hello.hc`, `09-repeat.hc`         |

## How each lesson works

Every file has:
1. A **comment header** explaining the concept
2. A **working example** you can run immediately
3. A **challenge** at the bottom (commented out) for you to try

## Next steps

Once you finish all 20 lessons, try these challenges:

- Modify `06-match.hc` to label 0–5 individually and group everything else
- Write a `max(a, b)` function that returns the larger of two numbers
- Combine `double` and `square` from lesson 4 into a `quad(n)` function
  that doubles *then* squares

## Running a lesson

```sh
# Build the Hica compiler (one time)
koka -O2 -ilib/klap -isrc src/main.kk -o hica
chmod +x hica

# Run any lesson
./hica run learn/01-hello.hc
```
