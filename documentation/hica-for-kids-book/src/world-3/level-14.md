# Level 14. Repeating Things

Sometimes you want to do something more than once. hica has `repeat` for that:

```hica
fun main() {
  repeat(5) {
    println("hica!")
  }
}
```

This prints `hica!` five times. The number in parentheses is how many times
the block runs.

You can use any expression for the count:

```hica
fun main() {
  let times = 3
  repeat(times) {
    println("go!")
  }
}
```

**🎯 Try it:** What happens if you use `repeat(0)`? What about `repeat(1)`?
