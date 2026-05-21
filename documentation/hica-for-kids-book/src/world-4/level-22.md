# Level 22. Maybe: Something or Nothing

Sometimes a value might exist, or it might not. Like looking for your keys —
they're either in your pocket, or they're not!

Hica has a special type called **maybe** for this. A maybe value is either:

- `Some(value)` — "yes, here it is!"
- `None` — "nope, nothing here"

### Creating maybe values

```hica
let found = Some(42)    // We found the answer!
let lost = None         // Nothing here
```

### Looking inside with match

To find out what's inside a maybe, use `match`:

```hica
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

```hica
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

```hica
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

