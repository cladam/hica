# Level 5. Variables: Labelled Boxes

Imagine you have a box and you stick a label on it. That's what `let` does —
it creates a named box and puts a value inside.

```hica
fun main() {
  let snack = "Apple"
  let count = 5
  println(count)
}
```

### Labelling the box (optional)

You can tell the computer what type of value the box should hold:

```hica
let age: int = 11
let name: string = "Alicia"
```

This is called a **type annotation**. It's optional: the compiler is smart
enough to figure it out. But sometimes it helps to be explicit.

### Rules for variable names

- Must start with a letter or underscore (`_`).
- Can contain letters, numbers, and underscores.
- Are **case-sensitive** — `score` and `Score` are different boxes.
- Use underscores for multi-word names: `high_score`, not `high-score`.

### The Last Line Rule

In Hica, you don't need to say "return." The computer just looks at the **very
last line** of a block `{ }` and says, "That's the answer!"

```hica
fun main() {
  let a = 10
  let b = 20
  println(b)            // The computer prints 20!
}
```

**🎯 Try it:** What happens if you put `a` on the last line instead of `b`?

### Changeable boxes with `var`

Sometimes you need a box whose contents can change, like a scoreboard during
a game. Use `var` instead of `let`:

```hica
fun main() {
  var score = 0
  score = score + 10
  score = score + 5
  println(score)          // 15
}
```

With `let`, the box is **sealed**. You can never change what's inside.
With `var`, the box has a **lid**. You can open it and swap the contents.

| Keyword | Can change? | Think of it as... |
| --- | --- | --- |
| `let` | No (immutable) | A sealed box |
| `var` | Yes (mutable) | A box with a lid |

Most of the time, `let` is all you need. Use `var` when you really need to
update a value, like counting things in a loop (you'll see this later!).
