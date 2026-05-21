# Level 11. Making Decisions (The Fork in the Road)

In Hica, an `if` expression is like a fork in the road. You go left or right
depending on a condition, and both paths must lead to a value.

```hica
fun negate(x) => if x < 0 { -x } else { x }
```

Notice the `-x`. Hica can negate numbers directly! No need to write `0 - x`.

You can even use it to set a variable:

```hica
fun main() {
  let a = if 10 > 5 { 10 } else { 5 }
  println(a)
}
```

Both sides of the fork **must** give back a value. Hica won't let you leave
one path empty. That way nothing ever gets lost!

### Chaining decisions

When you have more than two choices, use `else if`:

```hica
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

It's like a chain of doors. You check each one until you find the right room.

**🎯 Try it:** Write a function `size(n)` that returns `"small"` if `n < 10`,
`"medium"` if `n < 100`, and `"big"` otherwise.

