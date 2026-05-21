# Level 26. Closures: Functions That Remember

You've learned that functions are like little machines. But what if a machine
could **build another machine**? And what if that new machine could
**remember** things from where it was built?

That's what a **closure** is: a function that remembers values from its
surroundings.

### Closures capture their surroundings

Look at this example:

```hica
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

Here's the really cool part: a function can **build a new function** and
hand it back to you:

```hica
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

```hica
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

```hica
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

