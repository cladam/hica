# Level 12. The Match Game

Sometimes you have many choices. Instead of nested `if` statements, Hica uses
`match`. It's like a sorting machine — drop a value in, and it lands in the
right slot!

```hica
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

```hica
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

fun main() {
  println(day_type("Sunday"))   // "weekend"
  println(classify(2))          // "low"
}
```

### Range patterns: matching a whole range

Instead of listing every number, use `..=` to match a range (both ends
included):

```hica
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

```hica
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

```hica
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

```hica
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
