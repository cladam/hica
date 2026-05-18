---
layout: default
title: REPL Playbook - hica
---

# REPL Playbook

A hands-on guide to mastering the hica REPL. From first expressions to
building programs interactively. Work through it top-to-bottom or jump to
any level.

---

## Level 1: Calculator Mode

Launch the REPL and use it as a calculator.

```sh
rlwrap hica repl
```

```
hica=> 2 + 3
5
hica=> 100 / 7
14
hica=> 2 * 2 * 2 * 2
16
hica=> 17 % 5
2
```

**Try these:**
- What's `999 * 999`?
- What's `2` to the power of 10? (hint: `pow(2, 10)`)
- What's `100 - 1 - 2 - 3 - 4 - 5`?

---

## Level 2: The Underscore Trick

`_` always holds the last result. Chain calculations without retyping.

```
hica=> 6 * 7
42
hica=> _ + 8
50
hica=> _ * 2
100
```

**Try this chain:**
1. Start with `12345`
2. Multiply `_` by `2`
3. Add `111` to `_`
4. What do you get?

---

## Level 3: Naming Things with `let`

Give values a name so you can reuse them.

```
hica=> let age = 12
12
hica=> let next_year = age + 1
13
hica=> "I am " + age.show + " years old"
I am 12 years old
```

Names stick around for the whole session — use them as much as you want.

---

## Level 4: Your First Function

Define a function and call it multiple times.

```
hica=> fun double(n: int): int { n * 2 }
  defined: double
hica=> double(5)
10
hica=> double(double(3))
12
```

**Challenge:** Write `triple` that multiplies by 3, then compute `triple(double(7))`.

---

## Level 5: Multiline Input

When you type an opening `{`, `(`, or `[` without closing it, the REPL
waits for more lines (shown by `...>`). Close all braces to submit.

```
hica=> fun greet(name: string): string {
...>   "Hello " + name + "!"
...> }
  defined: greet
hica=> greet("World")
Hello World!
```

**Tip:** If you get stuck in `...>` mode, just close all braces with `}` and
press Enter.

---

## Level 6: If-Else Decisions

```
hica=> fun abs(n: int): int {
...>   if n < 0 { 0 - n } else { n }
...> }
  defined: abs
hica=> abs(-42)
42
hica=> abs(7)
7
```

**Challenge:** Write `max(a: int, b: int): int` that returns the bigger number.

---

## Level 7: Recursion

Functions can call themselves. Classic: Fibonacci.

```
hica=> fun fib(n: int): int {
...>   if n <= 1 { n } else {
...>     fib(n - 1) + fib(n - 2)
...>   }
...> }
  defined: fib
hica=> fib(10)
55
hica=> fib(20)
6765
```

**Challenge:** Write `factorial(n: int): int` — multiply all numbers from 1 to n.

---

## Level 8: Strings and Pipes

The pipe `|>` sends a value into the next function.

```
hica=> "hello world" |> length
11
hica=> "LOUD" |> to_lower
loud
hica=> "  spaces  " |> trim
spaces
```

**Pipe chains:**
```
hica=> "Hello, World!" |> to_lower |> length
13
```

---

## Level 9: Lists

```
hica=> let nums = [1, 2, 3, 4, 5]
[1, 2, 3, 4, 5]
hica=> nums |> length
5
hica=> nums |> map(fn(x) { x * x })
[1, 4, 9, 16, 25]
hica=> nums |> filter(fn(x) { x > 2 })
[3, 4, 5]
```

**Challenge:** Start with `[10, 20, 30, 40, 50]`, filter those > 25, then map
each to `x / 10`.

---

## Level 10: Pattern Matching

```
hica=> fun describe(n: int): string {
...>   match n {
...>     0 => "zero",
...>     1 => "one",
...>     _ => "many"
...>   }
...> }
  defined: describe
hica=> describe(0)
zero
hica=> describe(42)
many
```

---

## Level 11: Structs

Build your own types with named fields.

```
hica=> struct Point { x: int, y: int }
  defined: Point
hica=> let p = Point(3, 4)
Point(3, 4)
hica=> p.x + p.y
7
```

---

## Level 12: Loading Files

Save functions in a `.hc` file and load them into the REPL.

```
hica=> :load examples/fizzbuzz.hc
  loaded: examples/fizzbuzz.hc
hica=> :defs
```

Or start the REPL with a file preloaded:

```sh
rlwrap hica repl lib/mylib.hc
```

---

## Level 13: The Startup File

Create `~/.hicarc` with functions you always want available:

```hc
fun square(n: int): int { n * n }
fun cube(n: int): int { n * n * n }
fun is_even(n: int): bool { n % 2 == 0 }
```

These load automatically every time you start the REPL.

---

## REPL Commands Cheat Sheet

| Command      | What it does                          |
|--------------|---------------------------------------|
| `:help`      | Show this list                        |
| `:defs`      | Show all functions you've defined     |
| `:reset`     | Clear everything and start fresh      |
| `:history`   | Show what you've typed                |
| `:load FILE` | Load a `.hc` file into the session    |
| `:quit`      | Exit (or press Ctrl-D)                |

---

## Pro Tips

1. **Use `rlwrap`** — gives you arrow-key history and editing:
   ```sh
   rlwrap hica repl
   ```

2. **`_` is your clipboard** — every expression result goes there automatically.

3. **Build up incrementally** — define small functions, test immediately, combine.

4. **`:reset` is your friend** — if things get confusing, start fresh.

5. **Multiline = open brace** — the REPL knows you're not done when braces
   are unbalanced.

6. **Empty Enter is safe** — it just gives you a new prompt (won't exit).

7. **Type errors don't crash** — you get an error message and can try again.

---

## Exercises: The Gauntlet

Work through these in order. Each builds on the last.

1. **Warm-up:** Compute `(1 + 2 + 3 + 4 + 5) * 10` using `_`.
2. **Naming:** `let pi = 314` then compute the area of a circle with radius 5
   (hint: `pi * r * r / 100`).
3. **Function:** Write `is_teen(age: int): bool` that returns `true` for 13–19.
4. **Recursion:** Write `sum_to(n: int): int` that adds all numbers from 1 to n.
5. **Lists:** Create a list `[1..10]`, filter even numbers, then sum them.
6. **Struct:** Make a `Rectangle { width: int, height: int }` and write
   `area(r: Rectangle): int`.
7. **Boss fight:** Write `fizzbuzz(n: int): string` that returns "Fizz" for
   multiples of 3, "Buzz" for 5, "FizzBuzz" for both, or the number as a string.
