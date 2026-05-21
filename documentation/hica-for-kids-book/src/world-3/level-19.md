# Level 19. The Pipe: Connecting Machines

Remember how functions are like machines in a factory? The **pipe operator**
`|>` is the conveyor belt that connects them!

Picture an assembly line in a factory: a value starts at one end and moves
along the conveyor belt, passing through one machine after another. Each
machine does one small job, and the result rolls on to the next machine.
That's exactly what `|>` does — it connects your little machines into one
smooth assembly line.

Instead of nesting function calls inside each other, you can pipe a value
through a chain of functions — left to right, one step at a time:

```hica
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

```hica
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

```hica
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

```hica
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
