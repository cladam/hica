# 🚀 Hica for Kids: The Language with the Magic Arrow

Welcome to **Hica**! Hica is a programming language designed to be fast like a
racing car but easy to read like a story. It's built using **Koka** and turns
your code into **C** — the same language used to build the world's most powerful
software.

---

## Table of Contents

1. [What is Hica?](#1-what-is-hica)
2. [Why Hica for Kids?](#2-why-hica-for-kids)
3. [Getting Started](#3-getting-started)
4. [Your First Program — Hello, World!](#4-your-first-program--hello-world)
5. [Variables: Labelled Boxes](#5-variables-labelled-boxes)
6. [Data Types: What Goes in the Box?](#6-data-types-what-goes-in-the-box)
7. [Operators: The Math Toolkit](#7-operators-the-math-toolkit)
8. [Functions: Little Machines](#8-functions-little-machines)
9. [The Magic Arrow (`=>`)](#9-the-magic-arrow-)
10. [Testing: Did It Work?](#10-testing-did-it-work)
11. [Making Decisions (The Fork in the Road)](#11-making-decisions-the-fork-in-the-road)
12. [The Match Game](#12-the-match-game)
13. [Boolean Logic: True or False?](#13-boolean-logic-true-or-false)
14. [Repeating Things](#14-repeating-things)
15. [Counting Loops](#15-counting-loops)
16. [While Loops: Keep Going Until...](#16-while-loops-keep-going-until)
17. [Loop, Break, and Continue](#17-loop-break-and-continue)
18. [Building Strings](#18-building-strings)
19. [The Pipe: Connecting Machines](#19-the-pipe-connecting-machines)
20. [Tuples: Bundling Values Together](#20-tuples-bundling-values-together)
21. [Lists: Collections of Things](#21-lists-collections-of-things)
22. [Maybe: Something or Nothing](#22-maybe-something-or-nothing)
23. [Result: It Worked or It Didn't](#23-result-it-worked-or-it-didnt)
24. [Recursion: The Russian Doll Trick](#24-recursion-the-russian-doll-trick)
25. [Closures: Functions That Remember](#25-closures-functions-that-remember)
26. [Structs: Build Your Own Types](#26-structs-build-your-own-types)
27. [Maps: The Lookup Book](#27-maps-the-lookup-book)
28. [Enums: Choose Your Adventure](#28-enums-choose-your-adventure)
29. [Asking for Input](#29-asking-for-input)
30. [Random Numbers: Roll the Dice!](#30-random-numbers-roll-the-dice)
31. [Under the Hood: The Translator](#31-under-the-hood-the-translator)
32. [Projects](#32-projects)
33. [Sharing Code Between Files](#33-sharing-code-between-files)
34. [Dates & Times: What Day Is It?](#34-dates--times-what-day-is-it)
35. [Glossary](#35-glossary)

---

## 1. What is Hica?

Hica is a programming language — a way of giving instructions to a computer.
You write your instructions in a `.hc` file, and Hica turns them into a
program your computer can run.

What makes Hica special?

- It reads almost like English.
- Everything you write gives back a **value** — there are no "void" surprises.
- Your code gets translated into **C**, one of the fastest languages in the
  world, so your programs run really fast.

Think of it this way: **you** write the easy version, and Hica's translator
turns it into the hardcore version for the computer.

---

## 2. Why Hica for Kids?

| Reason | What it means |
| --- | --- |
| **Easy to read** | Hica code looks almost like plain English |
| **No boilerplate** | No more `public static void main(String[] args)` — just `fun main()` |
| **Fast programs** | Your code becomes a real executable, not just a script |
| **Smart memory** | Hica uses a trick called **Perceus** to clean up after itself — no garbage collector slowdowns |
| **Everything is an expression** | `if`, `match`, and blocks all give back values |
| **Learn real concepts** | The ideas you learn (functions, expressions, pattern matching) work in every language |

---

## 3. Getting Started

### What you need

1. Install [Koka](https://koka-lang.github.io/koka/doc/book.html#install)
   (version 3.2 or newer).
2. Get the Hica source code.

### Build the compiler

```sh
koka -ilib/klap -isrc src/main.kk -o hica
chmod +x hica
```

### Run a program

```sh
# Compile and run
./hica run examples/hello.hc

# Just compile (outputs to target/main.kk)
./hica build examples/hello.hc

# Check for errors without compiling
./hica check examples/hello.hc
```

---

## 4. Your First Program — Hello, World!

The classic first program. In Hica, it's just two lines:

```rust
fun main() {
  println("Hello, world!")
}
```

That's it! No imports, no class, no semicolons. Just a function called `main`
that prints a greeting.

**🎯 Try it:** Save that line in a file called `hello.hc` and run it:
```sh
./hica run hello.hc
```

There are actually several ways to write the same thing in Hica:

```rust
// Block body with println
fun main() {
  println("Hello, world!")
}

// Arrow body (shortest)
fun main() => println("Hello, world!")

// Let binding + println
fun main() {
  let msg = "Hello, world!"
  println(msg)
}

// Helper function
fun greet() => "Hello, world!"
fun main() {
  println(greet())
}
```

Pick whichever style you like — they all do the same thing!

---

## 5. Variables: Labelled Boxes

Imagine you have a box and you stick a label on it. That's what `let` does —
it creates a named box and puts a value inside.

```rust
fun main() {
  let snack = "Apple"
  let count = 5
  println(count)
}
```

### Labelling the box (optional)

You can tell the computer what type of value the box should hold:

```rust
let age: int = 11
let name: string = "Alicia"
```

This is called a **type annotation**. It's optional — the compiler is smart
enough to figure it out — but sometimes it helps to be explicit.

### Rules for variable names

- Must start with a letter or underscore (`_`).
- Can contain letters, numbers, and underscores.
- Are **case-sensitive** — `score` and `Score` are different boxes.
- Use underscores for multi-word names: `high_score`, not `high-score`.

### The Last Line Rule

In Hica, you don't need to say "return." The computer just looks at the **very
last line** of a block `{ }` and says, "That's the answer!"

```rust
fun main() {
  let a = 10
  let b = 20
  println(b)            // The computer prints 20!
}
```

**🎯 Try it:** What happens if you put `a` on the last line instead of `b`?

### Changeable boxes with `var`

Sometimes you need a box whose contents can change — like a scoreboard during
a game. Use `var` instead of `let`:

```rust
fun main() {
  var score = 0
  score = score + 10
  score = score + 5
  println(score)          // 15
}
```

With `let`, the box is **sealed** — you can never change what's inside.
With `var`, the box has a **lid** — you can open it and swap the contents.

| Keyword | Can change? | Think of it as... |
| --- | --- | --- |
| `let` | No (immutable) | A sealed box |
| `var` | Yes (mutable) | A box with a lid |

Most of the time, `let` is all you need. Use `var` when you really need to
update a value — like counting things in a loop (you'll see this later!).

---

## 6. Data Types: What Goes in the Box?

Different boxes hold different things. Hica has five main types right now:

### Integers (`int`)

Whole numbers, no decimals. Like counting your toys.

```rust
fun main() {
  let age = 11
  let score = 100
  println(score)
}
```

### Floats (`float`)

Numbers with a decimal point. Like measuring your height or weighing
ingredients for a recipe.

```rust
fun main() {
  let pi = 3.14159
  let temp = 36.6
  println("{temp}")
}
```

Floats and integers are different types — if a function uses `3.14 * r`,
then `r` must also be a float (like `5.0`, not `5`).

### Strings (`string`)

Text — words, sentences, emoji. Always wrapped in double quotes `" "`.

```rust
fun main() {
  let name = "Alex"
  let greeting = "Hello!"
  println(greeting)
}
```

### Booleans (true / false)

Like a light switch — on or off. Used for yes/no questions.

```rust
fun main() {
  let is_raining = 10 > 5     // true!
  println(is_raining)
}
```

### Characters (`char`)

A single letter, digit, or symbol. Always wrapped in single quotes `' '`.

```rust
fun main() {
  let grade = 'A'
  let star = '*'
  println(grade)
}
```

Characters are different from strings:
- `'a'` is a **character** — one single letter
- `"a"` is a **string** — text that happens to be one letter long

Think of it like LEGO: a character is one brick, a string is a whole row of bricks.

**🎯 Try it:** Create variables for your name, your age, and whether you like
pizza. What types are they?

---

## 7. Operators: The Math Toolkit

Operators are the symbols that do things with your values.

### Arithmetic (number crunching)

| Operator | Meaning | Example | Result |
| --- | --- | --- | --- |
| `+` | Add | `3 + 4` | `7` |
| `-` | Subtract | `10 - 3` | `7` |
| `*` | Multiply | `5 * 2` | `10` |
| `/` | Divide | `10 / 3` | `3` |
| `%` | Remainder | `10 % 3` | `1` |

These operators work on both integers and floats:

```rust
fun main() {
  let price = 5
  let quantity = 3
  let total = price * quantity
  println(total)
}
```

### Comparison (asking questions)

| Operator | Meaning | Example | Result |
| --- | --- | --- | --- |
| `==` | Equal to? | `5 == 5` | `true` |
| `!=` | Not equal? | `5 != 3` | `true` |
| `>` | Greater than? | `10 > 5` | `true` |
| `<` | Less than? | `3 < 7` | `true` |
| `>=` | Greater or equal? | `5 >= 5` | `true` |
| `<=` | Less or equal? | `4 <= 3` | `false` |

### Logic (combining questions)

| Operator | Meaning | Example |
| --- | --- | --- |
| `&&` | AND — both must be true | `x > 0 && x < 100` |
| `\|\|` | OR — at least one must be true | `x == 0 \|\| x == 1` |

**🎯 Try it:** Write a `fun main()` that computes how many seconds are in an
hour (60 × 60).

---

## 8. Functions: Little Machines

A function is like a machine in a factory. You put something in, it does some
work, and something comes out.

Imagine a pizza-making process:

1. `prepare_dough()` — makes the base
2. `add_toppings()` — puts cheese on top
3. `bake()` — cooks it in the oven

Each step is its own little machine. In Hica, you build machines with `fun`:

```rust
fun double(n) => n * 2
fun square(n) => n * n

fun main() {
  let a = double(3)    // a = 6
  let b = square(a)    // b = 36
  println(b)
}
```

You can chain machines — feed the output of one into the next, like an
assembly line!

**🎯 Try it:** Write a function `triple(n)` that multiplies by 3. Then call
it twice:

```rust
fun triple(n) => n * 3

fun main() {
  let a = triple(4)     // What is a?
  let b = triple(a)     // What is b?
  println(b)
}
```

---

## 9. The Magic Arrow (`=>`)

When a function does just one thing, you can use the **Hica Arrow** instead of
writing curly braces. Think of it as: *"this goes in, that comes out."*

```rust
// With curly braces (block body)
fun double(n) {
  n * 2
}

// With the arrow (same thing, shorter!)
fun double(n) => n * 2
```

The arrow is like a shortcut — one line, no braces, no fuss. Professional
programmers love shortcuts like this.

**🎯 Try it:** Rewrite this block-body function using the arrow:
```rust
fun add_ten(n) {
  n + 10
}
```

---

## 10. Testing: Did It Work?

You've built a little machine (a function). But how do you **know** it works?
You test it! In Hica, you write `test` blocks right next to your functions.

### Your first test

```rust
fun double(n) => n * 2

test "double works" {
  assert(double(3) == 6)
  assert(double(0) == 0)
}
```

Run it:

```sh
./hica test my_file.hc
```

```
running 1 test(s)...

  ✓ double works

1 test(s) passed
```

The green ✓ means your function works! 🎉

### What happens when a test fails?

Try changing the test to something wrong on purpose:

```rust
test "this will fail" {
  assert_eq(double(3), 5)
}
```

```
  ✗ this will fail
    expected 6 but got 5
```

The red ✗ shows you exactly what went wrong. That's the magic of testing: you
find bugs **before** they surprise you.

### Testing tools

Think of these as your detective kit:

| Tool | What it checks | Example |
| --- | --- | --- |
| `assert(cond)` | Is this true? | `assert(1 + 1 == 2)` |
| `assert_eq(a, b)` | Are these equal? | `assert_eq(double(5), 10)` |
| `assert_ne(a, b)` | Are these different? | `assert_ne("cat", "dog")` |
| `assert_true(cond)` | Is this true? (clearer message) | `assert_true(10 > 5)` |
| `assert_false(cond)` | Is this false? | `assert_false(1 > 100)` |
| `assert_contains(list, x)` | Is `x` in the list? | `assert_contains([1, 2, 3], 2)` |
| `assert_empty(list)` | Is the list empty? | `assert_empty([])` |
| `assert_not_empty(list)` | Does the list have items? | `assert_not_empty([1, 2])` |

### Why test early?

Imagine building a Lego spaceship. Would you rather find a missing piece now,
or when the whole thing falls apart at launch? Tests let you check each piece
as you build.

**Golden rule:** Write a function, write a test. Always.

**🎯 Try it:** Write a function `triple(n)` that multiplies by 3, then write a
test for it:

```rust
fun triple(n) => n * 3

test "triple works" {
  assert_eq(triple(4), 12)
  assert_eq(triple(0), 0)
}
```

---

## 11. Making Decisions (The Fork in the Road)

In Hica, an `if` expression is like a fork in the road. You go left or right
depending on a condition — and both paths must lead to a value.

```rust
fun negate(x) => if x < 0 { -x } else { x }
```

Notice the `-x` — Hica can negate numbers directly! No need to write `0 - x`.

You can even use it to set a variable:

```rust
fun main() {
  let a = if 10 > 5 { 10 } else { 5 }
  println(a)
}
```

Both sides of the fork **must** give back a value — Hica won't let you leave
one path empty. That way nothing ever gets lost!

### Chaining decisions

When you have more than two choices, use `else if`:

```rust
fun fizzbuzz(n) =>
  if n == 15 { "fizzbuzz" }
  else if n == 3 { "fizz" }
  else if n == 5 { "buzz" }
  else { "other" }

fun main() {
  let result = fizzbuzz(15)
  println(result)
}
```

It's like a chain of doors — you check each one until you find the right room.

**🎯 Try it:** Write a function `size(n)` that returns `"small"` if `n < 10`,
`"medium"` if `n < 100`, and `"big"` otherwise.

---

## 12. The Match Game

Sometimes you have many choices. Instead of nested `if` statements, Hica uses
`match`. It's like a sorting machine — drop a value in, and it lands in the
right slot!

```rust
fun describe(x) => match x {
  0 => "zero",
  1 => "one",
  _ => "many"       // The '_' means "anything else"
}

fun main() {
  let label = describe(1)
  println(label)
}
```

The `_` is like a big bucket that catches everything that didn't match the
other slots. You should always include it so nothing falls through!

### Match with conditions (guards)

Sometimes a simple value isn't enough — you want to check a *condition* too.
Add `if` after the pattern to create a **guard**:

```rust
fun classify(n) => match n {
  x if x < 0   => "negative",
  0             => "zero",
  x if x > 100 => "big",
  _             => "small positive"
}

fun main() {
  println(classify(-5))    // "negative"
  println(classify(0))     // "zero"
  println(classify(200))   // "big"
  println(classify(42))    // "small positive"
}
```

The variable `x` captures the value, and `if x < 0` is the guard — like a
bouncer who checks your ticket before letting you through the door.

### Or-patterns: matching several values at once

Use `|` to match multiple values in one arm — like saying "this *or* that":

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

fun main() {
  println(day_type("Sunday"))   // "weekend"
  println(classify(2))          // "low"
}
```

### Range patterns: matching a whole range

Instead of listing every number, use `..=` to match a range (both ends
included):

```rust
fun grade(score: int) => match score {
  0..=59   => "F",
  60..=69  => "D",
  70..=79  => "C",
  80..=89  => "B",
  90..=100 => "A",
  _        => "invalid"
}

fun main() {
  println(grade(85))    // "B"
  println(grade(92))    // "A"
  println(grade(45))    // "F"
}
```

Think of `0..=59` as "any number from 0 to 59, including both." Much shorter
than writing `0 | 1 | 2 | ... | 59`!

### Matching tuples

You can take apart a tuple right inside a match — this is called
**tuple destructuring**:

```rust
fun describe(point) => match point {
  (0, 0) => "origin",
  (x, 0) => "on x-axis at {x}",
  (0, y) => "on y-axis at {y}",
  (x, y) => "({x}, {y})"
}

fun main() {
  println(describe((0, 0)))    // "origin"
  println(describe((3, 0)))    // "on x-axis at 3"
  println(describe((2, 5)))    // "(2, 5)"
}
```

Each arm peeks inside the tuple and names the pieces. It's like opening a
lunchbox and checking what's in each compartment!

**list slice patterns**:

You can also peek inside lists! Use brackets to check what's in the list:

```rust
fun describe(xs: list<int>) : string => match xs {
  []           => "empty bag",
  [x]          => "just {x}",
  [x, ..rest]  => "first is {x}, {length(rest)} more inside"
}

fun main() {
  println(describe([]))           // empty bag
  println(describe([42]))         // just 42
  println(describe([1, 2, 3]))    // first is 1, 2 more inside
}
```

Think of it like looking into a bag: `[]` means the bag is empty, `[x]`
means there's exactly one thing, and `[x, ..rest]` means "grab the first
thing and keep the rest in the bag."

This is perfect for processing a list one item at a time:

```rust
fun sum(xs: list<int>) : int => match xs {
  []          => 0,
  [x, ..rest] => x + sum(rest)
}
```

**🎯 Try it:** Write a `match` that labels 0 as `"none"`, 1 as `"solo"`,
2 as `"pair"`, and everything else as `"group"`.

**🎯 Try it:** Write a function `season(month: int)` using range patterns:
months 3..=5 are `"spring"`, 6..=8 are `"summer"`, 9..=11 are `"autumn"`,
and everything else is `"winter"`.

---

## 13. Boolean Logic: True or False?

You can combine questions with `&&` (AND) to check if *both* are true:

```rust
fun classify(n) =>
  if n > 0 && n < 100 { "in range" }
  else { "out of range" }

fun main() {
  let result = classify(42)
  println(result)
}
```

Think of `&&` as a bouncer at a door: "Are you old enough **AND** do you have
a ticket?" Both must be true to get in.

**🎯 Try it:** Write a function that checks if a number is between 1 and 10
(inclusive). Hint: `n >= 1 && n <= 10`.

---

## 14. Repeating Things

Sometimes you want to do something more than once. Hica has `repeat` for that:

```rust
fun main() {
  repeat(5) {
    println("hica!")
  }
}
```

This prints `hica!` five times. The number in parentheses is how many times
the block runs.

You can use any expression for the count:

```rust
fun main() {
  let times = 3
  repeat(times) {
    println("go!")
  }
}
```

**🎯 Try it:** What happens if you use `repeat(0)`? What about `repeat(1)`?

---

## 15. Counting Loops

What if you want to do something *and* know which round you're on?
That's what `for` is for!

```rust
fun main() {
  for i in 1..5 {
    println(i)
  }
}
```

This prints:
```
1
2
3
4
5
```

The variable `i` counts from the first number to the last number (both
included). Think of it as: *"for every number i from 1 to 5, do this."*

### The range `..`

The two dots `..` mean "from here to there":

| Range | Numbers you get |
| --- | --- |
| `0..4` | 0, 1, 2, 3, 4 |
| `1..3` | 1, 2, 3 |
| `1..100` | 1, 2, 3, ..., 100 |

### FizzBuzz with a for loop

Remember FizzBuzz? Now we can do the *real* version — loop through all the
numbers!

```rust
fun fizzbuzz(n) =>
  if n % 15 == 0 { "fizzbuzz" }
  else if n % 3 == 0 { "fizz" }
  else if n % 5 == 0 { "buzz" }
  else { show(n) }

fun main() {
  for i in 1..100 {
    println(fizzbuzz(i))
  }
}
```

Notice `show(n)` in the last branch — it turns a number into a string
(so `show(7)` gives `"7"`). We need it because every branch must return the
same type, and the other branches already return strings.

That's only 10 lines of code and it prints all 100 fizzbuzz results!

### Using the loop variable

The loop variable is a regular integer — you can do math with it:

```rust
fun main() {
  for i in 1..5 {
    println(i * i)
  }
}
```

This prints the squares: 1, 4, 9, 16, 25.

**🎯 Try it:** Use a `for` loop to print the first 10 multiples of 7
(7, 14, 21, ...).

**🎯 Try it:** Print a countdown: `for i in 1..5 { println(6 - i) }`.
What numbers do you get?

---

## 16. While Loops: Keep Going Until...

A `for` loop runs a set number of times. But sometimes you don't know *how
many* times — you just want to keep going **until** something happens. That's
what `while` is for!

```rust
fun main() {
  var x = 5
  while x > 0 {
    println(x)
    x = x - 1
  }
  println("liftoff!")
}
```

This prints `5, 4, 3, 2, 1, liftoff!` — it keeps running **while** `x > 0`,
and each time around, `x` gets smaller by 1.

Notice the `var` — we need a changeable box because the loop updates `x` each
time around. A `let` box can't change, so it wouldn't work here.

### How while works

1. Check the condition (`x > 0`).
2. If **true**, run the block `{ ... }`.
3. Go back to step 1.
4. If **false**, skip the block and continue after the loop.

It's like a guard at a gate: *"Are you still above zero? Yes? Go again.
No? You're done."*

### Summing numbers with while

```rust
fun sum_to(n) {
  var total = 0
  var i = 1
  while i <= n {
    total = total + i
    i = i + 1
  }
  total
}

fun main() {
  println(sum_to(100))    // 5050
}
```

### Be careful!

If the condition never becomes `false`, the loop runs forever! Make sure
something in the body moves you toward the exit:

```rust
// ❌ BAD — x never changes, so x > 0 is always true!
// var x = 5
// while x > 0 { println(x) }

// ✅ GOOD — x decreases each time
var x = 5
while x > 0 {
  println(x)
  x = x - 1
}
```

**🎯 Try it:** Write a while loop that finds the first power of 2 bigger
than 1000. Start with `var n = 1` and keep doubling: `n = n * 2`.

---

## 17. Loop, Break, and Continue

### The infinite loop

Sometimes you want a loop that runs **forever** — until you decide to stop.
That's `loop`:

```rust
fun main() {
  var count = 0
  loop {
    count = count + 1
    if count > 3 { break }
    println(count)
  }
  println("done!")
}
```

This prints `1, 2, 3, done!` — the `break` is like an **emergency exit**.
When the program hits `break`, it jumps out of the loop immediately.

### Break: the emergency exit

`break` works in *all* loop types — `while`, `for`, `repeat`, and `loop`:

```rust
fun main() {
  for i in 1..100 {
    if i > 5 { break }
    println(i)
  }
}
```

This only prints 1 through 5, even though the range goes to 100.

### Continue: skip this round

`continue` is like saying "skip the rest of this round and go to the next
one." It works in all loops too:

```rust
fun main() {
  for i in 1..10 {
    if i % 2 == 0 { continue }
    println(i)
  }
}
```

This prints only the odd numbers: 1, 3, 5, 7, 9. When `i` is even, `continue`
skips the `println` and jumps straight to the next number.

### Combining break and continue

You can use both in the same loop:

```rust
fun main() {
  for i in 1..100 {
    if i % 2 == 0 { continue }   // skip even numbers
    if i > 10 { break }           // stop after 10
    println(i)
  }
}
```

This prints: 1, 3, 5, 7, 9.

Think of a conveyor belt: `continue` means "throw this one away and grab the
next item," while `break` means "turn off the conveyor belt."

**🎯 Try it:** Use a `loop` with `break` to print numbers 1, 2, 3, 4, 5.
Hint: use `var i = 0`, increment it each time, and break when `i > 5`.

---

## 18. Building Strings

Sometimes you want to build a message from pieces. Hica gives you two ways.

### Gluing strings with `+`

The `+` operator works on strings too — it stitches them together:

```rust
fun shout(word) => word + "!"

fun main() {
  println(shout("wow"))
}
```

### String interpolation with `{}`

Even easier: put `{expr}` right inside a string, and Hica fills in the value:

```rust
fun greet(name) => "hello, {name}!"

fun main() {
  println(greet("world"))
}
```

Numbers and booleans are converted automatically:

```rust
fun main() {
  let apples = 5
  println("{apples} apples")
}
```

You can even put expressions inside the braces:

```rust
fun main() {
  let a = 3
  let b = 4
  println("{a} + {b} = {a + b}")
}
```

Think of `{}` as little windows into your code — whatever you put inside gets
turned into text and dropped into the string.

**🎯 Try it:** Write a function `introduce(name, age)` that returns
`"my name is ___ and I am ___ years old"`.

### String tools

Hica comes with built-in tools for working with strings — no imports needed:

```rust
fun main() {
  let msg = "  Hello, World!  "

  // Trimming — remove extra spaces
  println(trim(msg))           // "Hello, World!"

  // Searching
  println(contains(msg, "World"))    // true
  println(starts_with(trim(msg), "Hello"))  // true

  // Changing case
  println(to_upper("hello"))  // "HELLO"
  println(to_lower("HELLO"))  // "hello"

  // Splitting and joining
  println(split("a,b,c", ","))        // ["a", "b", "c"]
  println(join(["a", "b", "c"], "-")) // "a-b-c"

  // How long is it?
  println(str_length("hello"))  // 5
}
```

Think of these like tools in a toolbox:

| Tool | What it does | Example |
| --- | --- | --- |
| `str_length(s)` | Count the characters | `str_length("hi")` → `2` |
| `trim(s)` | Remove spaces from the edges | `trim("  hi  ")` → `"hi"` |
| `contains(s, sub)` | Is `sub` inside `s`? | `contains("hello", "ell")` → `true` |
| `to_upper(s)` | ALL CAPS | `to_upper("hi")` → `"HI"` |
| `to_lower(s)` | all lowercase | `to_lower("HI")` → `"hi"` |
| `split(s, sep)` | Break into a list | `split("a-b", "-")` → `["a", "b"]` |
| `join(xs, sep)` | Glue a list together | `join(["a", "b"], "-")` → `"a-b"` |
| `replace(s, old, new)` | Swap parts | `replace("hi", "i", "ey")` → `"hey"` |

**🎯 Try it:** Use `split` to break `"red,green,blue"` into a list, then
`join` it back with `" and "`.

### Special characters (escape sequences)

What if you want to put a double-quote *inside* a string? You can't just
write `"She said "hi""` — Hica would think the string ends at the second `"`.

The trick: put a backslash `\` before the special character. The backslash
says "the next character is literal, not magic":

```rust
fun main() {
  println("She said \"hi\"")   // She said "hi"
  println("one\\two")          // one\two  (literal backslash)
}
```

There are also shortcuts for invisible characters:

| Escape | What it does | |
| --- | --- | --- |
| `\"` | A literal `"` inside a string | `"say \"hi\""` |
| `\\` | A literal backslash | `"C:\\folder"` |
| `\n` | Start a new line | `"line1\nline2"` |
| `\t` | A tab (big space) | `"col1\tcol2"` |

```rust
fun main() {
  println("line one\nline two")  // prints on two lines!
  println("name\tage")
  println("Ada\t12")
}
```

Escapes work inside interpolated strings too:

```rust
fun main() {
  let name = "world"
  println("hello, {name}!\ngoodbye!")
}
```

**🎯 Try it:** Print a tiny two-line poem using `\n` to separate the lines.

### Peeking inside strings (indexing and slicing)

You can grab individual characters or pieces of a string using square brackets
— just like picking cards out of a deck:

```rust
fun main() {
  let s = "hello"
  println(s[0])      // 'h' — the first character
  println(s[1])      // 'e' — the second character
  println(s[-1])     // 'o' — the last character!
}
```

Negative numbers count from the end: `-1` is the last character, `-2` is
the second-to-last, and so on.

You can also grab a **slice** — a piece of the string:

```rust
fun main() {
  let s = "hello"
  println(s[1:4])    // "ell" — from position 1 up to (not including) 4
  println(s[:3])     // "hel" — the first 3 characters
  println(s[3:])     // "lo"  — from position 3 to the end
}
```

| Syntax | What you get | Example with `"hello"` |
| --- | --- | --- |
| `s[i]` | One character | `s[0]` → `'h'` |
| `s[i:j]` | Substring from i to j | `s[1:4]` → `"ell"` |
| `s[:j]` | First j characters | `s[:3]` → `"hel"` |
| `s[i:]` | From i to the end | `s[3:]` → `"lo"` |
| `s[-1]` | Last character | `s[-1]` → `'o'` |

Think of it like a ruler laid along the string — the numbers mark the gaps
*between* characters, and you pick the piece between two marks.

**🎯 Try it:** Given `let word = "abcdef"`, what is `word[2:5]`?
What about `word[-2]`?

---

## 19. The Pipe: Connecting Machines

Remember how functions are like machines in a factory? The **pipe operator**
`|>` is the conveyor belt that connects them!

Picture an assembly line in a factory: a value starts at one end and moves
along the conveyor belt, passing through one machine after another. Each
machine does one small job, and the result rolls on to the next machine.
That's exactly what `|>` does — it connects your little machines into one
smooth assembly line.

Instead of nesting function calls inside each other, you can pipe a value
through a chain of functions — left to right, one step at a time:

```rust
fun double(n) => n * 2
fun square(n) => n * n

fun main() {
  // Without pipe — you read inside-out:
  let a = square(double(3))

  // With pipe — you read left to right:
  let b = 3 |> double |> square

  println(b)
}
```

Both give the same answer (`36`), but the pipe version reads like a recipe:

> Take 3, *then* double it, *then* square it.

### How it works

The pipe `|>` takes the value on the left and passes it as the argument to the
function on the right:

```
a |> f      becomes      f(a)
a |> f |> g becomes      g(f(a))
```

It's just a nicer way to write function calls — nothing new to learn, just
a shortcut that makes chains easier to read.

### When to use it

Pipes shine when you have a series of transformations:

```rust
fun add_one(n) => n + 1
fun double(n) => n * 2
fun square(n) => n * n

fun main() {
  // Read it like a story: start with 4, add one, double, square
  let result = 4 |> add_one |> double |> square
  println(result)
}
```

**🎯 Try it:** What does `4 |> add_one |> double |> square` give you?
Work it out step by step: 4 → ? → ? → ?

### Dot notation: another way to connect machines

There's a second way to write the same assembly line. Instead of the pipe
symbol, you can use a **dot** followed by the function name with parentheses:

```rust
fun add_one(n) => n + 1
fun double(n) => n * 2
fun square(n) => n * n

fun main() {
  // Pipe style:
  let a = 4 |> add_one |> double |> square

  // Dot style (same thing!):
  let b = 4.add_one().double().square()

  println(a == b)  // true — they're identical
}
```

`a.f()` means exactly the same as `a |> f` — it passes `a` into the function
`f`. The dot style looks like you're calling a "method" on the value, even
though `add_one` is just a regular function.

**When is dot style handy?** When a function takes extra arguments:

```rust
fun main() {
  let nums = [1, 2, 3, 4, 5]

  // Dot style reads nicely with extra arguments
  let big = nums.filter((x) => x > 2).map((x) => x * 10)
  println(big)
}
```

**Rule of thumb:**
- Use `|>` when each step is a simple one-argument function
- Use `.f()` when you're also passing extra arguments (like the lambda above)
- Both are fine — pick whichever feels clearest to *you*!

---

## 20. Tuples: Bundling Values Together

Sometimes you want to keep two (or more) values together — like an **x** and
**y** position, or a name and an age. A **tuple** is a tiny bundle that holds
several values side by side.

### Making a tuple

Wrap values in parentheses, separated by commas:

```rust
let point = (10, 20)
let person = ("Alicia", 15)
```

### Getting values out

Use `.0` for the first item and `.1` for the second:

```rust
let point = (10, 20)
println("{point.0}")  // 10
println("{point.1}")   // 20
```

Think of `.0` as "the first pocket" and `.1` as "the second pocket".

### Destructuring: opening the bundle

You can unpack a tuple into separate variables with `let`:

```rust
let point = (10, 20)
let (x, y) = point
println("{x}")  // 10
println("{y}")  // 20
```

This is called **destructuring** — you "take apart" the tuple and give each
piece its own name.

### When are tuples handy?

* Returning two things from a function
* Grouping coordinates: `(x, y)`
* Keeping a pair of related data together without inventing a new type

**🎯 Try it:** Make a tuple `("Hica", 2026)` and print both parts using `.0`
and `.1`.

---

## 21. Lists: Collections of Things

What if you have a whole bunch of values — not just two or three, but five,
ten, or even a hundred? That's what **lists** are for.

A list is like a row of boxes, all holding the same kind of thing.

### Making a list

Wrap values in square brackets, separated by commas:

```rust
let nums = [1, 2, 3, 4, 5]
let words = ["hello", "hej", "hola"]
```

### The empty list

A list with nothing in it:

```rust
let nothing = []
```

### The golden rule: same type!

Every item in a list must be the same type. You can't mix numbers and strings:

```rust
[1, 2, 3]          // ✅ all ints
["a", "b", "c"]    // ✅ all strings
[1, "hello"]        // ❌ type error!
```

This is different from tuples, which *can* hold different types.

### Lists vs Tuples — what's the difference?

| | Tuple | List |
| --- | --- | --- |
| Syntax | `(1, "hi")` | `[1, 2, 3]` |
| Types | Can mix types | All same type |
| Size | Fixed (you know how many) | Any length |
| Use | Bundle a few related values | Collect many values |

### Doing things with lists

Hica gives you three super-powers for working with lists:

**`map` — transform every element**

```rust
let nums = [1, 2, 3]
let doubled = map(nums, (x) => x * 2)
println(doubled)   // [2, 4, 6]
```

Think of `map` like a machine: each item goes in one side, gets changed, and
comes out the other side.

**`filter` — keep only the ones you want**

```rust
let nums = [1, 2, 3, 4, 5]
let big = filter(nums, (x) => x > 3)
println(big)   // [4, 5]
```

`filter` checks each item: "Does this pass the test?" If yes, it stays.
If no, it's gone.

**`fold` — combine everything into one value**

```rust
let nums = [1, 2, 3, 4]
let total = fold(nums, 0, (acc, x) => acc + x)
println(total)   // 10
```

`fold` is like a snowball rolling downhill. It starts with an initial value
(here `0`), and adds each element one at a time: `0 + 1 = 1`, `1 + 2 = 3`,
`3 + 3 = 6`, `6 + 4 = 10`.

**🎯 Try it:** Use `map` to add 100 to every number in `[1, 2, 3]`.

**🎯 Try it:** Use `filter` to keep only even numbers from `[1, 2, 3, 4, 5, 6]`.
(Hint: `x % 2 == 0` tests if a number is even.)

### More list tools

Hica has a few more handy tools for lists:

**`length` — how many items?**

```rust
let nums = [10, 20, 30]
println(length(nums))   // 3
```

Like counting the boxes in a row.

**`reverse` — flip the order**

```rust
let nums = [1, 2, 3]
println(reverse(nums))   // [3, 2, 1]
```

Like reading a list backwards!

**`cons` — add something to the front**

```rust
let nums = [2, 3, 4]
println(cons(1, nums))   // [1, 2, 3, 4]
```

`cons` is super fast — like putting a new box at the start of the row.
If you want to add to the *end* instead, use `+`:

```rust
let nums = [1, 2, 3]
println(nums + [4])   // [1, 2, 3, 4]
```

Adding to the end is slower because the computer has to walk the whole row
first. For most programs it doesn't matter, but if speed is important,
`cons` is the way to go!

**`for x in list` — do something with each item**

The nicest way to walk through a list is with a `for` loop:

```rust
let names = ["Alice", "Bob", "Carol"]
for name in names {
  println("Hi, {name}!")
}
```

This prints:
```
Hi, Alice!
Hi, Bob!
Hi, Carol!
```

You can also use the function form: `foreach(names, (name) => println(name))`

`for x in list` is like walking down the row of boxes and doing something at each
one. It's similar to `map`, but you use it when you want to *do* something
(like print) rather than *transform* the values.

**🎯 Try it:** Use `reverse` on `["a", "b", "c"]` — what do you get?

**🎯 Try it:** Use `for` to print each number in `[10, 20, 30]`
multiplied by 5.

### Even more list tools

Here are a few more useful list functions:

**`head` and `last` — peek at the ends**

```rust
fun main() {
  let nums = [10, 20, 30]
  println(head(nums))   // Some(10)
  println(last(nums))   // Some(30)
  println(head([]))     // None — nothing there!
}
```

`head` gives you the first item, `last` gives you the last. They return
`Some(...)` or `None` because the list might be empty.

**`tail` — everything except the first**

```rust
println(tail([1, 2, 3]))   // [2, 3]
```

**`sum` — add them all up**

```rust
println(sum([1, 2, 3, 4, 5]))   // 15
```

No need to write `fold` for the most common case!

**`sort_by` — put things in order**

```rust
let messy = [3, 1, 4, 1, 5, 9]
let tidy = sort_by(messy, (a, b) => a <= b)
println(tidy)   // [1, 1, 3, 4, 5, 9]
```

You give `sort_by` a comparison function. It returns `true` when the first
value should come before the second. Flip it to sort the other way:

```rust
let biggest_first = sort_by(messy, (a, b) => a >= b)
println(biggest_first)   // [9, 5, 4, 3, 1, 1]
```

**`unique` — remove repeats**

```rust
println(unique([1, 2, 3, 2, 1]))   // [1, 2, 3]
```

**🎯 Try it:** Sort `[5, 2, 8, 1, 9]` from smallest to biggest, then
print just the first element using `head`.

---

## 22. Maybe: Something or Nothing

Sometimes a value might exist, or it might not. Like looking for your keys —
they're either in your pocket, or they're not!

Hica has a special type called **maybe** for this. A maybe value is either:

- `Some(value)` — "yes, here it is!"
- `None` — "nope, nothing here"

### Creating maybe values

```rust
let found = Some(42)    // We found the answer!
let lost = None         // Nothing here
```

### Looking inside with match

To find out what's inside a maybe, use `match`:

```rust
fun describe(x) => match x {
  Some(n) => "found: {n}",
  None    => "nothing"
}

fun main() {
  println(describe(Some(42)))  // "found: 42"
  println(describe(None))      // "nothing"
}
```

Think of `Some` like an envelope with a letter inside, and `None` like an
empty envelope. The `match` opens the envelope to check.

### When is maybe useful?

Maybe is great when something might not have an answer:

- Looking up a word in a dictionary — maybe it's there, maybe it's not
- Finding the first even number in a list — maybe there is one, maybe not
- Getting input from a user — maybe they typed something, maybe they didn't

```rust
fun first_positive(nums) => match nums {
  [] => None,
  _  => Some(nums[0])
}

fun main() {
  println(first_positive([10, 20]))
  println(first_positive([]))
}
```

**🎯 Try it:** Write a function that takes a number and returns
`Some("even")` if it's even, or `None` if it's odd.

### Helpers: working with maybe without match

Sometimes you don't want to write a whole `match` just to peek inside. Hica
has helper functions (called **combinators**) that work like little machines
you can pipe through:

```rust
// Transform what's inside (if anything)
let doubled = Some(5) |> map_maybe((x) => x * 2)
println(doubled)   // Some(10)

// Get the value or use a backup
let value = None |> unwrap_maybe_or(0)
println(value)     // 0

// Ask yes/no questions
println(is_some(Some(1)))   // true
println(is_none(None))      // true
```

Think of `map_maybe` like putting a letter through a stamping machine — if
the envelope is empty (`None`), the machine does nothing. If there's a letter
inside (`Some`), it stamps it and puts it back.

---

## 23. Result: It Worked or It Didn't

Sometimes things can go wrong. You try to divide by zero, open a file that
doesn't exist, or parse a number from text that isn't a number.

Without `Result`, errors would crash your program — like a car hitting a wall
at full speed. But `Result` is like a **"Caution!" sign** on the road. When
something goes wrong, the program slows down safely, reads the sign, and
decides what to do next instead of crashing.

Hica has a **result** type for this. A result is either:

- `Ok(value)` — "it worked! Here's the answer"
- `Err(error)` — "something went wrong, here's what happened"

### Safe division

Dividing by zero normally crashes. With `result`, we can handle it:

```rust
fun safe_divide(a, b) =>
  if b == 0 { Err("cannot divide by zero!") }
  else { Ok(a / b) }

fun main() {
  match safe_divide(10, 2) {
    Ok(n)  => println("answer: {n}"),
    Err(e) => println("error: {e}")
  }
  match safe_divide(10, 0) {
    Ok(n)  => println("answer: {n}"),
    Err(e) => println("error: {e}")
  }
}
```

This prints:
```
answer: 5
error: cannot divide by zero!
```

No crash! The program handles the problem gracefully.

### Maybe vs Result — what's the difference?

| | Maybe | Result |
| --- | --- | --- |
| Success | `Some(value)` | `Ok(value)` |
| Failure | `None` (no info) | `Err(reason)` (tells you what went wrong) |
| Use when | Something might be missing | Something might fail, and you want to know why |

Think of it this way:
- **Maybe** is like a yes/no question: "Is there an answer?" (`Some` = yes, `None` = no)
- **Result** is like a report card: "Did it work?" (`Ok` = passed, `Err` = failed and here's why)

**🎯 Try it:** Write a `safe_head(nums)` function that returns `Ok(nums[0])`
if the list is not empty, or `Err("empty list")` if it is.

### Helpers: working with results without match

Just like Maybe, Result has helper functions to avoid writing `match`
everywhere:

```rust
fun safe_divide(a, b) =>
  if b == 0 { Err("division by zero") }
  else { Ok(a / b) }

fun main() {
  // Transform the Ok value
  let big = safe_divide(10, 2) |> map_result((n) => n * 100)
  println(big)   // Ok(500)

  // Chain operations that might fail
  let chained = safe_divide(10, 2)
    |> and_then_result((n) => safe_divide(n, 1))
  println(chained)   // Ok(5)

  // Quick checks
  println(is_ok(safe_divide(1, 1)))    // true
  println(is_err(safe_divide(1, 0)))   // true
}
```

Think of `and_then_result` like a relay race — each runner passes the baton
to the next, but if someone trips (`Err`), the race stops right there.

### The `?` shortcut

When you're writing a function that returns `maybe`, and you need to unwrap
several maybe values in a row, all those `match` blocks pile up fast — like
stacking boxes inside boxes inside boxes. 📦📦📦

The `?` operator is a shortcut. Put `?` after a maybe value and it does two
things:

- If it's `Some(v)`, you get `v` — the value inside.
- If it's `None`, the whole function returns `None` right away.

```rust
fun add_strings(a: string, b: string) : maybe<int> {
  let x = parse_int(a)?   // None → stop here, return None
  let y = parse_int(b)?   // None → stop here, return None
  Some(x + y)
}

fun main() {
  println(add_strings("3", "4"))    // Some(7)
  println(add_strings("3", "abc"))  // None
}
```

Without `?`, you'd need:

```rust
fun add_strings(a: string, b: string) : maybe<int> {
  match parse_int(a) {
    None => None,
    Some(x) => match parse_int(b) {
      None => None,
      Some(y) => Some(x + y)
    }
  }
}
```

See how `?` keeps everything flat? Think of it as asking "did this work?" —
if not, bail out.

**🎯 Try it:** Write a function `safe_first(xs: list<int>) : maybe<int>`
that uses `find(xs, (n) => n > 0)?` to find the first positive number.

---

## 24. Recursion: The Russian Doll Trick

Imagine a Russian doll (matryoshka). You open it, and there's a smaller
identical doll inside. Open that one, and there's an even smaller one. You keep
going until you find the tiniest doll that doesn't open.

**Recursion** is when a function calls *itself* — like those nested dolls.

### How it works

Every recursive function needs exactly two things:

1. **A base case** — when to STOP (the tiniest doll that doesn't open)
2. **A recursive case** — how to make the problem SMALLER (opening the next doll)

### Factorial: the classic example

"5 factorial" means `5 × 4 × 3 × 2 × 1 = 120`. In code:

```rust
fun factorial(n) => if n <= 1 { 1 } else { n * factorial(n - 1) }

fun main() {
  println(factorial(5))   // 120
}
```

Let's trace it like dolls:

```
factorial(5) = 5 × factorial(4)
             = 5 × 4 × factorial(3)
             = 5 × 4 × 3 × factorial(2)
             = 5 × 4 × 3 × 2 × factorial(1)
             = 5 × 4 × 3 × 2 × 1   ← base case! Stop here.
             = 120
```

- **Base case:** `n <= 1` → return `1` (the tiniest doll)
- **Recursive case:** `n * factorial(n - 1)` (open the next doll)

### Adding up: sum from 1 to n

```rust
fun sum_to(n) => if n <= 0 { 0 } else { n + sum_to(n - 1) }

fun main() {
  println(sum_to(10))   // 55
}
```

Think of it like stacking blocks: 10 + 9 + 8 + ... + 1 = 55.

### GCD: a clever recursion

The **Greatest Common Divisor** is the biggest number that divides two numbers
evenly. Euclid figured this out over 2000 years ago:

```rust
fun main() {
  println(gcd(12, 8))   // 4
}
```

Hica has `gcd` built in! It works by repeatedly asking: "What's the remainder?"
until there's nothing left. That "nothing left" is the base case.

### The golden rule: always have a base case!

Without a base case, a recursive function would call itself forever — like
dolls that never end, or two mirrors facing each other. The program would
never finish!

```rust
// ❌ BAD — no base case!
// fun forever(n) => forever(n + 1)   // never stops!

// ✅ GOOD — has a base case
fun countdown(n) => if n <= 0 { 0 } else { countdown(n - 1) }
```

### When to use recursion?

Use recursion when a problem can be broken into **smaller copies of itself**:

- "Sum 1 to 100" = 100 + "Sum 1 to 99"
- "Factorial of 5" = 5 × "Factorial of 4"
- "GCD of 12 and 8" = "GCD of 8 and 4"

**🎯 Try it:** Write a `power(base, exp)` function:
- `power(2, 0)` → 1 (base case: anything to the power of 0 is 1)
- `power(2, 3)` → 8 (recursive: `2 * power(2, 2)`)

**🎯 Think:** What's `factorial(0)`? What about `sum_to(0)`?

### Mutual recursion: two functions that take turns

Sometimes two functions call **each other** instead of themselves. Imagine
two friends playing catch — each one throws the ball to the other until
someone decides to stop.

```rust
fun check_even(n) => if n == 0 { true } else { check_odd(n - 1) }

fun check_odd(n) => if n == 0 { false } else { check_even(n - 1) }
```

- `check_even(4)` calls `check_odd(3)`, which calls `check_even(2)`,
  which calls `check_odd(1)`, which calls `check_even(0)` → `true`!
- They keep bouncing back and forth, making the number smaller each time.

Hica figures out that these functions call each other — you don't need to
do anything special.

**🎯 Try it:** Trace `check_odd(3)` on paper. What does each call look like?

---

## 25. Closures: Functions That Remember

You've learned that functions are like little machines. But what if a machine
could **build another machine**? And what if that new machine could
**remember** things from where it was built?

That's what a **closure** is — a function that remembers values from its
surroundings.

### Closures capture their surroundings

Look at this example:

```rust
fun main() {
  let factor = 10
  let scale = (x) => x * factor
  println(scale(7))
}
```

The anonymous function `(x) => x * factor` captures the variable `factor`
from the outside. Even though `factor` isn't a parameter of `scale`, the
closure remembers it. The answer is `70`.

### Functions that return functions

Here's the really cool part — a function can **build a new function** and
hand it back to you:

```rust
fun make_adder(n) => (x) => x + n

fun main() {
  let add5 = make_adder(5)
  println(add5(10))
  println(add5(100))
}
```

`make_adder(5)` gives you a **new function** that adds 5 to whatever you
give it. It's like a machine that builds custom adding machines!

- `add5(10)` → `15`
- `add5(100)` → `105`

### Higher-order functions

A **higher-order function** is a function that takes another function as an
argument. You've already used some — `map`, `filter`, and `fold` are all
higher-order functions! But you can write your own:

```rust
fun apply(f, x) => f(x)
fun twice(f, x) => f(f(x))

fun double(n) => n * 2

fun main() {
  println(apply(double, 21))
  println(twice(double, 3))
}
```

- `apply(double, 21)` → `42` (just calls `double(21)`)
- `twice(double, 3)` → `12` (calls `double(double(3))`: 3 → 6 → 12)

### Putting it all together

Closures, higher-order functions, and pipes combine beautifully:

```rust
fun make_adder(n) => (x) => x + n

fun main() {
  let add10 = make_adder(10)
  let double = (x) => x * 2

  let result = 5 |> double |> add10
  println(result)
}
```

> Take 5, *then* double it (10), *then* add 10 (20).

**🎯 Try it:** Write a `make_multiplier(n)` function that returns a closure.
`make_multiplier(3)(7)` should give `21`.

**🎯 Bonus:** Write `twice(f, x)` that applies `f` to `x` two times.
What does `twice(double, 5)` give you?

---

## 26. Structs: Build Your Own Types

Tuples are great for bundling a few values together, but what if you have three,
four, or more fields? And what if you can't remember whether `.0` is the name or
the age? That's where **structs** come in.

A struct is like designing your own **custom box** with labelled compartments.

### Defining a struct

Use the `struct` keyword to create a new type:

```rust
struct Pet { name: string, species: string, age: int }
```

This creates a new type called `Pet` with three named fields.

### Making a struct value

Fill in the fields by name:

```rust
struct Pet { name: string, species: string, age: int }

fun main() {
  let buddy = Pet { name: "Daisy", species: "cat", age: 3 }
  println(buddy)
}
```

Output: `Pet(name: Daisy, species: cat, age: 3)`

### Reading fields

Use a dot and the field name, this is much clearer than `.0` and `.1`!

```rust
struct Pet { name: string, species: string, age: int }

fun main() {
  let buddy = Pet { name: "Daisy", species: "cat", age: 3 }
  println(buddy.name)     // Daisy
  println(buddy.species)  // cat
  println(buddy.age)      // 3
}
```

### Structs as function parameters

You can pass structs to functions just like any other value:

```rust
struct Pet { name: string, species: string, age: int }

fun introduce(p: Pet) : string =>
  "{p.name} is a {p.age}-year-old {p.species}"

fun main() {
  let daisy = Pet { name: "Daisy", species: "cat", age: 3 }
  println(introduce(daisy))
}
```

Output: `Daisy is a 3-year-old cat`

### Tuples vs Structs

| Tuples | Structs |
|--------|--------|
| `("Daisy", "cat", 3)` | `Pet { name: "Daisy", species: "cat", age: 3 }` |
| Access with `.0`, `.1`, `.2` | Access with `.name`, `.species`, `.age` |
| Good for 2–3 values | Good for any number of fields |
| Quick and anonymous | Named and self-documenting |

Use tuples when it's obvious what the values mean (like `(x, y)` coordinates).
Use structs when you want names that explain the data.

**🎯 Try it:** Create a `Player` struct with `name: string` and `score: int`.
Write a function `level_up(p: Player) : string` that prints
`"{p.name} reached score {p.score}!"`.

### Updating a struct

Structs can't change (they're immutable), but you can make a copy with some
fields changed using `...`:

```rust
struct Pet { name: string, species: string, age: int }

fun main() {
  let daisy = Pet { name: "Daisy", species: "cat", age: 3 }
  let older = Pet { ...daisy, age: 4 }   // everything else stays the same!
  println(older)
}
```

Think of it like photocopying a form and writing over just one field.

### Taking structs apart in match

Remember `match`? You can use it to look inside a struct — like opening a
box and checking what's in each compartment:

```rust
struct Point { x: int, y: int }

fun describe(p: Point) : string => match p {
  Point { x: 0, y: 0 } => "origin",
  Point { x, y: 0 }    => "on x-axis",
  Point { x, y }       => "({x}, {y})"
}
```

- `Point { x, y }` — opens the box and names each field
- `Point { x: 0, y: 0 }` — only matches when both fields are zero
- `Point { x }` — you can skip fields you don't care about

**🎯 Try it:** Create a `Pet` struct with `name`, `species`, and `age`.
Write a `describe` function that uses match to print different messages
for kittens (age 0) vs older pets!

---

## 27. Maps: The Lookup Book

Imagine a **dictionary**, you look up a word and find its meaning. Or a **phone book**, you look up a name and find a number. 
In Hica, this is called a **map**.

### Making a map

Use curly braces with `"key": value` pairs:

```rust
let ages = {"kalle": 30, "olle": 25, "lisa": 35}
println(ages)
```

Output: `[("kalle",30),("olle",25),("lisa",35)]`

Think of it like a table with two columns:

| Key       | Value |
| --------- | ----- |
| `"kalle"` | `30`  |
| `"olle"`  | `25`  |
| `"lisa"`  | `35`  |

### Looking things up

Use `map_get` to find a value by its key. It returns a **maybe** — because
the key might not exist!

```rust
let ages = {"kalle": 30, "olle": 25}
println(ages.map_get("kalle"))    // Just(30) — found it!
println(ages.map_get("nobody"))   // Nothing — not there
```

### Adding and changing entries

Use `map_set` to add a new key or change an existing one:

```rust
let ages = {"kalle": 30, "olle": 25}
let ages2 = ages.map_set("lisa", 35)    // adds lisa
let ages3 = ages2.map_set("olle", 26)   // updates olle
println(ages3.map_keys())               // ["kalle", "olle", "lisa"]
```

Maps don't change, `map_set` gives you a **new** map with the change.
The original stays the same.

### Removing entries

```rust
let ages = {"kalle": 30, "olle": 25, "lisa": 35}
let ages2 = ages.map_remove("olle")
println(ages2.map_keys())   // ["kalle", "lisa"]
```

### Empty maps

Use `{:}` to create an empty map, then build it up with `map_set`:

```rust
let m = {:}
let m2 = m.map_set("x", 1).map_set("y", 2)
println(m2)   // [("x",1),("y",2)]
```

### Map tools

| Tool | What it does | Example |
| --- | --- | --- |
| `map_get(m, key)` | Look up a key | `m.map_get("kalle")` → `Just(30)` |
| `map_set(m, key, val)` | Add or change | `m.map_set("lisa", 35)` |
| `map_remove(m, key)` | Remove a key | `m.map_remove("olle")` |
| `map_keys(m)` | All the keys | `m.map_keys()` → `["kalle", "olle"]` |
| `map_values(m)` | All the values | `m.map_values()` → `[30, 25]` |
| `map_contains_key(m, key)` | Is the key there? | `m.map_contains_key("kalle")` → `true` |
| `map_size(m)` | How many entries? | `m.map_size()` → `2` |

### The secret: maps are lists!

Under the hood, a map is just a **list of tuples** — pairs of (key, value).
That means you can use all the list tools on maps too:

```rust
let scores = {"kalle": 95, "olle": 60, "lisa": 88}
let high = scores.filter((entry) => entry.1 >= 80)
println(high)   // [("kalle",95),("lisa",88)]
```

**🎯 Try it:** Create a map of your favourite animals and their sounds
(like `{"cat": "meow", "dog": "woof"}`). Look up one that exists and one
that doesn't.

**🎯 Try it:** Start with an empty map `{:}` and use `map_set` to add three
friends and their ages. Then print `map_keys()` and `map_size()`.

---

## 28. Enums: Choose Your Adventure

Remember structs? A struct says "every value has the same fields." But what if
a value could be **one of several different things**? That's an **enum** — short
for "enumeration."

Think of it like a "choose your adventure" book — at each point, the story can
take one of several different paths. An enum says: "this value is one of these
options."

### A simple enum

The simplest enum is just a list of named options, like picking a colour
from a fixed set:

```rust
type Color {
  Red,
  Green,
  Blue
}

fun main() {
  let c = Red
  println(c)        // Red
}
```

`type` creates a new type. `Red`, `Green`, and `Blue` are the **variants** —
the possible values. No numbers, no strings — just names. Clear and
impossible to misspell (the compiler catches typos!).

### Enums with data

Here's where enums get really powerful. Each variant can carry **different
data**:

```rust
type Shape {
  Circle(radius: float),
  Rect(width: float, height: float),
  Point
}
```

- `Circle` carries one float (the radius)
- `Rect` carries two floats (width and height)
- `Point` carries nothing at all

Think of it like different kinds of packages: a round tube for circles,
a flat box for rectangles, and just a dot for points.

### Making enum values

Construct them like function calls:

```rust
fun main() {
  let s1 = Circle(5.0)
  let s2 = Rect(3.0, 4.0)
  let s3 = Point

  println(s1)   // Circle(5)
  println(s2)   // Rect(3, 4)
  println(s3)   // Point
}
```

### Using match with enums

Here's the best part — `match` lets you handle each variant separately,
and it **unpacks the data** for you:

```rust
type Shape {
  Circle(radius: float),
  Rect(width: float, height: float),
  Point
}

fun describe(s: Shape) : string => match s {
  Circle(r)  => "a circle with radius {r}",
  Rect(w, h) => "a {w} by {h} rectangle",
  Point      => "just a point"
}

fun main() {
  println(describe(Circle(5.0)))
  println(describe(Rect(3.0, 4.0)))
  println(describe(Point))
}
```

Output:
```
a circle with radius 5
a 3 by 4 rectangle
just a point
```

The variables `r`, `w`, and `h` are bound by the pattern — they hold whatever
data was packed into the variant. It's like opening the package and seeing
what's inside!

### The compiler has your back

If you forget a variant in your `match`, the compiler warns you:

```
warning: non-exhaustive match: missing Point
```

This is like a checklist — the compiler makes sure you've handled every
possible case. No surprises at runtime!

### Enums vs Structs

| | Struct | Enum |
| --- | --- | --- |
| Every value looks... | The same (same fields) | Different (one of several variants) |
| Think of it as... | AND — has field A **and** field B | OR — is variant A **or** variant B |
| Example | `struct Pet { name: string, age: int }` | `type Shape { Circle(r: float), Point }` |

Use a struct when all values have the same shape. Use an enum when a value
can be one of several different things.

### A pet shelter example

```rust
type Animal {
  Dog(name: string, age: int),
  Cat(name: string),
  Fish
}

fun greet(a: Animal) : string => match a {
  Dog(name, age) => "{name} the dog, {age} years old",
  Cat(name)      => "{name} the cat",
  Fish           => "just a fish"
}

fun is_pet(a: Animal) : bool => match a {
  Fish => false,
  _    => true
}

fun main() {
  let animals = [Dog("Buddy", 3), Cat("Whiskers"), Fish]
  let pets = animals |> filter(is_pet)
  println("Pets: {pets}")
}
```

Output: `Pets: [Dog(Buddy, 3),Cat(Whiskers)]`

**🎯 Try it:** Create a `type Vehicle` with variants `Car(seats: int)`,
`Bike`, and `Bus(seats: int)`. Write a function `capacity(v: Vehicle) : int`
that returns the number of seats (bikes have 1).

**🎯 Challenge:** Create a `type Coin` with `Heads` and `Tails`. Use
`random(0, 1)` to pick one and `match` to print the result!

---

## 29. Asking for Input

So far, your programs have been one-way conversations — the computer talks,
but you can't talk back. Let's change that! The `input` function prints a
question and waits for the user to type an answer.

```rust
fun main() {
  let name = input("What is your name? ")
  println("Hello, " + name + "!")
}
```

When you run this, the computer prints the prompt, then **waits**. You type
your answer, press Enter, and the program continues with whatever you typed.

### Reading numbers

`input` always gives you a **string**. If you want a number, use `parse_int`
or `parse_float` to convert it — and `match` to handle the case where the
user types something that isn't a number:

```rust
fun main() {
  let age_str = input("How old are you? ")
  match parse_int(age_str) {
    Some(age) => println("In 10 years you'll be {age + 10}"),
    None      => println("That's not a number!")
  }
}
```

### A guessing game!

Combine `input`, `parse_int`, and match guards for a mini game:

```rust
fun main() {
  let secret = 7
  println("I'm thinking of a number between 1 and 10...")
  let guess_str = input("Your guess: ")
  match parse_int(guess_str) {
    Some(n) if n == secret => println("Correct!"),
    Some(_)               => println("Wrong! It was {secret}"),
    None                  => println("Please enter a number!")
  }
}
```

Notice how we use a **match guard** (`if n == secret`) — that's the pattern
matching trick from chapter 11!

**🎯 Try it:** Write a program that asks for your name and your favourite
colour, then prints `"Hi ___, your favourite colour is ___!"`.

**🎯 Challenge:** Make a simple calculator: ask for two numbers and an
operator (`+`, `-`, `*`, `/`), then print the result. Use `match` on the
operator string!

---

## 30. Random Numbers: Roll the Dice!

What if your program could surprise you? With `random`, it can! The `random`
function picks a number for you — a different one each time you run the
program.

### Rolling a die

`random(min, max)` gives you a random integer. Both numbers are included —
so `random(1, 6)` can give you 1, 2, 3, 4, 5, or 6. To roll a six-sided die:

```rust
fun main() {
  let die = random(1, 6)
  println("You rolled a {die}!")
}
```

This works just like `for i in 1..6` — both ends are included. Simple!

| Call | Possible results |
| --- | --- |
| `random(1, 6)` | 1, 2, 3, 4, 5, or 6 |
| `random(0, 1)` | 0 or 1 (coin flip!) |
| `random(1, 100)` | 1 through 100 |

**🎯 Try it:** Run the die program several times — you'll get a different
number each time!

### Coin flip

A coin has two sides. Use `random(0, 1)` to pick between them:

```rust
fun main() {
  let flip = random(0, 1)
  if flip == 0 { println("Heads!") }
  else { println("Tails!") }
}
```

### Rolling many dice

Combine `random` with a loop to roll several dice:

```rust
fun main() {
  var total = 0
  for i in 1..3 {
    let roll = random(1, 6)
    println("Die {i}: {roll}")
    total = total + roll
  }
  println("Total: {total}")
}
```

This rolls 3 dice, prints each one, and adds them up — just like a board
game!

### A real guessing game!

Remember the guessing game in chapter 29? The secret number was hard-coded.
Now we can make it truly random:

```rust
fun main() {
  let secret = random(1, 10)
  println("I picked a number between 1 and 10...")
  let guess_str = input("Your guess: ")
  match parse_int(guess_str) {
    Some(n) if n == secret => println("You got it!"),
    Some(n) if n < secret  => println("Too low! It was {secret}"),
    Some(n)                => println("Too high! It was {secret}"),
    None                   => println("That's not a number!")
  }
}
```

Every time you play, the answer is different. Now it's a *real* game!

### Random choices

You can use `random` to pick a random item from a list by generating a
random index:

```rust
fun main() {
  let snacks = ["apple", "banana", "cookie", "donut"]
  let pick = random(0, length(snacks) - 1)
  println("Today's snack: {snacks[pick]}")
}
```

**🎯 Try it:** Make a list of 5 activities ("read", "draw", "code", etc.)
and have the computer pick one at random. Run it a few times!

**🎯 Challenge:** Write a rock-paper-scissors game. The computer picks
randomly (0 = rock, 1 = paper, 2 = scissors), and the player types their
choice. Use `match` to decide who wins!

---

## 31. Under the Hood: The Translator

This is the coolest part of Hica. When you run your program, three things
happen behind the scenes:

```
Your code (.hc)  →  Koka (.kk)  →  C  →  Your computer runs it!
```

| Layer | What it is |
| --- | --- |
| **Hica** (`.hc`) | The "Human Language" — easy for you to read and write |
| **Koka** (`.kk`) | The "Translator" — converts your code into something lower-level |
| **C** | The "Robot Language" — super fast, used to build operating systems |

So when you write `fun double(n) => n * 2`, your simple one-liner becomes
serious, optimised C code. You get the **easy** writing experience and the
**fast** running speed.

### Perceus: The Memory Cleaner

When your program creates values (boxes), it uses memory. Some languages need a
"garbage collector" that pauses your program to clean up — like stopping a race
car to pick up litter. Hica uses **Perceus** instead: it counts exactly how
many times each box is used and cleans it up the instant nobody needs it
anymore. No pauses, no slowdowns.

---

## 32. Projects

Ready for something bigger? Try these!

### Project 1: The Calculator

Build functions for basic math operations:

```rust
fun add(a, b) => a + b
fun multiply(a, b) => a * b

fun main() {
  let sum = add(15, 27)
  let product = multiply(6, 7)
  println(product)
}
```

**Challenge:** Add a `power` function that computes `a * a` (squaring). Can
you do `a * a * a` (cubing)?

### Project 2: The Grade Machine

```rust
fun grade(score) =>
  if score > 89 { "A" }
  else if score > 79 { "B" }
  else if score > 69 { "C" }
  else { "Try harder!" }

fun main() {
  let my_grade = grade(85)
  println(my_grade)
}
```

**Challenge:** Add a grade for "D" (60–69).

### Project 3: The Number Describer

```rust
fun describe(x) => match x {
  0 => "zero",
  1 => "one",
  _ => "many"
}

fun sign(n) =>
  if n > 0 { "positive" }
  else if n == 0 { "zero" }
  else { "negative" }

fun main() {
  let a = describe(0)
  let b = sign(-5)
  println(b)
}
```

**Challenge:** Combine `describe` and `sign` — call one function from another!

### Project 4: The Banner Maker

Make a function that centers text inside a fancy banner:

```rust
fun main() {
  let title = "HICA"
  let banner = center(title, 20, "=")
  println(banner)
  println(center("cool stuff", 20, "-"))
  println(center(title, 20, "="))
}
```

Output:

```
========HICA========
-----cool stuff-----
========HICA========
```

**Challenge 1:** Use `surround` to add a border on the sides too — like
`| ========HICA======== |`.

**Challenge 2:** Can you make a box? Try printing a top line, a centered
title, and a bottom line:

```
********************
*       HICA       *
********************
```

Hint: use `repeat_str("*", 20)` for the top and bottom, and
`"*" + center("HICA", 18, " ") + "*"` for the middle.

---

## 33. Sharing Code Between Files

When your programs get bigger, you might want to put some functions in a
separate file. That's what **imports** are for!

### Making things shareable

To share a function from a file, add `pub` in front of it:

```rust
// helpers.hc
pub fun double(x) => x * 2
pub fun triple(x) => x * 3
fun secret() => 42   // no pub — stays hidden!
```

`pub` is short for "public". It means: "other files are allowed to use this."

### Importing

In another file, use `import` to bring those shared functions in:

```rust
// main.hc
import "helpers"

fun main() {
  println(double(5))   // 10
  println(triple(5))   // 15
  // secret() would fail — it's not pub!
}
```

The name in quotes is the file name **without** `.hc`. If `helpers.hc` is in
the same folder as your main file, just write `"helpers"`.

### Picking what you want

Sometimes a file has lots of functions but you only need one. Use
`from ... import { }` to pick:

```rust
from "helpers" import { double }

fun main() {
  println(double(5))   // works!
  // triple(5)         // nope — we didn't import it
}
```

Think of it like ordering from a menu: you don't have to take everything,
just pick the dishes you want.

### Passing things along

If you want to share someone else's functions through your file, use
`pub import`:

```rust
// everything.hc
pub import "helpers"
pub import "math_tools"
```

Now anyone who imports `everything` gets all the pub functions from both
`helpers` and `math_tools`. It's like being a librarian: you collect books
from different shelves and put them on one table.

**🎯 Challenge:** Create two files — `animals.hc` with `pub fun cat()` and
`pub fun dog()`, and a main file that imports them and prints each animal's
sound!

---

## 34. Dates & Times: What Day Is It?

Hica has built-in functions for working with dates and times. They use
**strings** that look like this:

- A **date**: `"2026-05-15"` — year, month, day, separated by dashes
- A **time**: `"07:32:00"` — hours, minutes, seconds, separated by colons
- A **datetime**: `"2026-05-15T07:32:00"` — a date and time joined by `T`

Think of it like writing a date on a letter — you write it in a standard
format so everyone can read it.

### Is this date real?

```rust
fun main() {
  println(is_valid_date("2024-05-15"))   // true
  println(is_valid_date("2024-02-30"))   // false — February doesn't have 30 days!
  println(is_valid_date("2024-13-01"))   // false — there's no month 13
}
```

Hica knows about **leap years** too:

```rust
fun main() {
  println(is_valid_date("2024-02-29"))   // true  — 2024 is a leap year
  println(is_valid_date("2023-02-29"))   // false — 2023 is not
}
```

### What kind of date is this?

The `datetime_kind` function tells you what you're looking at:

```rust
fun main() {
  println(datetime_kind("2024-05-15"))                // "local-date"
  println(datetime_kind("07:32:00"))                   // "local-time"
  println(datetime_kind("2024-05-15T07:32:00"))        // "local-datetime"
  println(datetime_kind("2024-05-15T07:32:00Z"))       // "offset-datetime"
  println(datetime_kind("banana"))                     // "invalid"
}
```

### Breaking a date apart

You can split a date into its pieces — year, month, and day:

```rust
fun main() {
  match date_parts("2026-05-15") {
    Ok(d) => println("Year: {d.0}, Month: {d.1}, Day: {d.2}"),
    Err(e) => println(e)
  }
}
```

### Which comes first?

```rust
fun main() {
  println(is_before("2024-01-01", "2024-12-31"))   // true
  println(is_before("2024-12-31", "2024-01-01"))   // false
}
```

### What day of the week?

```rust
fun main() {
  match day_of_week("2026-05-15") {
    Ok(d) => println("Today is " + d),   // "Today is friday"
    Err(e) => println(e)
  }
}
```

**🎯 Challenge:** Write a program that asks the user for their birthday
(as `YYYY-MM-DD`) and tells them what day of the week they were born!

---

## 35. Glossary

| Word | What it means |
| --- | --- |
| `fun` | Declares a new function (a little machine) |
| `3.14` | A float literal — a number with a decimal point |
| `let` | Creates a named value (an immutable labelled box) |
| `var` | Creates a changeable value (a box with a lid) |
| `=>` | The magic arrow — shortcut for simple functions |
| `test "name"` | Declares a test block — checks that your code works |
| `assert(cond)` | Test tool — fails if condition is false |
| `assert_eq(a, b)` | Test tool — fails if a and b are different |
| `match` | A sorting machine that picks a path based on a value |
| `_` | The wildcard — matches anything |
| `x if cond` | A match guard — adds a condition to a pattern |
| `a \| b` | Or-pattern — match this *or* that in a match arm |
| `0..=59` | Range pattern — match any integer in a range (inclusive) |
| `[x, ..rest]` | Slice pattern — grab the first item, keep the rest |
| `if / else` | A fork in the road — pick one path |
| `else if` | Chain multiple conditions without nesting |
| `repeat(n)` | Do something n times |
| `for i in a..b` | Counted loop — run with i going from a to b (inclusive) |
| `while cond` | Loop while a condition is true |
| `loop` | Infinite loop — runs until `break` |
| `break` | Emergency exit — jump out of any loop |
| `continue` | Skip the rest of this round and go to the next one |
| `Some(x)` | A maybe that has a value inside |
| `None` | A maybe with nothing inside |
| `Ok(x)` | A result that succeeded |
| `Err(x)` | A result that failed, with a reason |
| `..` | Range operator — used in for loops: `1..10` |
| `+` on strings | Glue two strings together (concatenation) |
| `"{expr}"` | String interpolation — embed a value inside a string |
| `s[i]` | String indexing — get the character at position i |
| `s[i:j]` | String slicing — get a substring from i to j |
| `\|>` | The pipe — passes a value into a function: `a \|> f` means `f(a)` |
| `(a, b)` | A tuple — bundles two (or more) values together |
| `.0`, `.1` | Tuple access — get the first or second item from a tuple |
| `let (x, y)` | Tuple destructuring — unpack a tuple into separate variables |
| `struct` | Declares a new type with named fields — like designing a custom box |
| `Name { f: v }` | Create a struct value — fill in the labelled compartments |\n| `{\"k\": v}` | A map literal — a lookup table of key-value pairs |\n| `{:}` | An empty map |\n| `map_get(m, k)` | Look up a key in a map — returns `Some(v)` or `None` |\n| `map_set(m, k, v)` | Add or update a key in a map |
| `.field` | Struct field access — read a named compartment |
| `type` | Declares an enum type — a value that can be one of several variants |
| `Red`, `Circle(r)` | Enum variants — the possible shapes a value can take |
| `input(prompt)` | Ask the user for text input — prints prompt, waits for answer |
| `random(min, max)` | Pick a random number from min to max (both included) |
| `show_fixed(v, n)` | Format a float with exactly n decimal places — `show_fixed(3.14159, 2)` gives `"3.14"` |
| `parse_int(s)` | Try to turn a string into an integer — returns `Some(n)` or `None` |
| `parse_float(s)` | Try to turn a string into a float — returns `Some(n)` or `None` |
| `is_valid_date(s)` | Check if a string is a real date like `"2024-05-15"` |
| `is_valid_time(s)` | Check if a string is a real time like `"07:32:00"` |
| `datetime_kind(s)` | Tell you what kind of datetime a string is |
| `date_parts(s)` | Break a date into year, month, day |
| `time_parts(s)` | Break a time into hour, minute, second |
| `is_before(d1, d2)` | True if the first date/time comes before the second |
| `day_of_week(s)` | What day of the week is this date? Returns `"monday"` etc. |
| `offset_to_minutes(s)` | Convert a timezone offset to minutes — `"+02:00"` gives `120` |
| `-x` | Negate a number (flip positive/negative) |
| `!x` | Negate a boolean (flip true/false) |
| `&&` | AND — both sides must be true |
| `==` | Equals — asks "are these the same?" |
| `println()` | Print a value to the screen |
| `show()` | Turn a value into a string — `show(42)` gives `"42"` |
| `str_length()` | Count the characters in a string |
| `trim()` | Remove spaces from the edges of a string |
| `contains()` | Check if a string contains another string |
| `to_upper()` | Convert a string to UPPERCASE |
| `to_lower()` | Convert a string to lowercase |
| `split()` | Break a string into a list — `split("a,b", ",")` gives `["a", "b"]` |
| `join()` | Glue a list into a string — `join(["a", "b"], "-")` gives `"a-b"` |
| `center()` | Center a string inside padding — `center("hi", 10, "-")` gives `"----hi----"` |
| `replace()` | Swap parts of a string |
| `length()` | Count how many items are in a list |
| `reverse()` | Flip a list backwards |
| `head()` | First element of a list — returns `Some(x)` or `None` |
| `tail()` | Everything after the first element |
| `last()` | Last element of a list — returns `Some(x)` or `None` |
| `sum()` | Add up all numbers in a list |
| `sort_by()` | Sort a list using a comparison function |
| `unique()` | Remove duplicates from a list |
| `for x in list` | Walk through each item in a list |
| `foreach()` | Function form of for-each — `foreach(list, fn)` |
| `pow(base, exp)` | Exponentiation — `pow(2, 10)` gives `1024` |
| `sqrt(x)` | Square root — `sqrt(25.0)` gives `5.0` |
| `floor(x)` | Round a float down — `floor(3.7)` gives `3` |
| `ceil(x)` | Round a float up — `ceil(3.2)` gives `4` |
| `round(x)` | Round to nearest integer |
| `to_float(n)` | Turn an integer into a float |
| `chars(s)` | Break a string into a list of characters |
| `from_chars(cs)` | Turn a list of characters back into a string |
| closure | A function that remembers values from where it was created |
| higher-order function | A function that takes or returns other functions |
| `import` | Bring functions from another file into yours |
| `pub` | Mark a function as public — other files can use it |
| `from ... import` | Pick specific functions from another file |
| `pub import` | Import and re-share — pass functions along to your importers |
| `: int` | A type annotation — labels a variable or parameter with its type |
| block `{ }` | A group of steps; the last line is the answer |
| `.hc` | The file extension for Hica source code |
| Koka | The language Hica is built in and translates to |
| Perceus | The smart memory cleaner — no garbage collector needed |

---

*Happy coding! 🎮*
