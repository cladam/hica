# Level 17. Loop, Break, and Continue

### The infinite loop

Sometimes you want a loop that runs **forever** — until you decide to stop.
That's `loop`:

```hica
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

```hica
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

```hica
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

```hica
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

