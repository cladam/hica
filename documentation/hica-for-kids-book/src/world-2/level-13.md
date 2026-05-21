# Level 13. Boolean Logic: True or False?

You can combine questions with `&&` (AND) to check if *both* are true:

```hica
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

