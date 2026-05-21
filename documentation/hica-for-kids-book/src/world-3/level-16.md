# Level 16. While Loops: Keep Going Until...

A `for` loop runs a set number of times. But sometimes you don't know *how
many* times — you just want to keep going **until** something happens. That's
what `while` is for!

```hica
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

```hica
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

```hica
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

