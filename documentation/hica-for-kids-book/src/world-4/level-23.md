# Level 23. Result: It Worked or It Didn't

Sometimes things can go wrong. You try to divide by zero, open a file that
doesn't exist, or parse a number from text that isn't a number.

Without `Result`, errors would crash your program — like a car hitting a wall
at full speed. But `Result` is like a **"Caution!" sign** on the road. When
something goes wrong, the program slows down safely, reads the sign, and
decides what to do next instead of crashing.

Hica has a **result** type for this. A result is either:

- `Ok(value)` — "it worked! Here's the answer"
- `Err(error)` — "something went wrong, here's what happened"

### Safe division

Dividing by zero normally crashes. With `result`, we can handle it:

```hica
fun safe_divide(a, b) =>
  if b == 0 { Err("cannot divide by zero!") }
  else { Ok(a / b) }

fun main() {
  match safe_divide(10, 2) {
    Ok(n)  => println("answer: {n}"),
    Err(e) => println("error: {e}")
  }
  match safe_divide(10, 0) {
    Ok(n)  => println("answer: {n}"),
    Err(e) => println("error: {e}")
  }
}
```

This prints:
```
answer: 5
error: cannot divide by zero!
```

No crash! The program handles the problem gracefully.

### Maybe vs Result — what's the difference?

| | Maybe | Result |
| --- | --- | --- |
| Success | `Some(value)` | `Ok(value)` |
| Failure | `None` (no info) | `Err(reason)` (tells you what went wrong) |
| Use when | Something might be missing | Something might fail, and you want to know why |

Think of it this way:
- **Maybe** is like a yes/no question: "Is there an answer?" (`Some` = yes, `None` = no)
- **Result** is like a report card: "Did it work?" (`Ok` = passed, `Err` = failed and here's why)

**🎯 Try it:** Write a `safe_head(nums)` function that returns `Ok(nums[0])`
if the list is not empty, or `Err("empty list")` if it is.

### Helpers: working with results without match

Just like Maybe, Result has helper functions to avoid writing `match`
everywhere:

```hica
fun safe_divide(a, b) =>
  if b == 0 { Err("division by zero") }
  else { Ok(a / b) }

fun main() {
  // Transform the Ok value
  let big = safe_divide(10, 2) |> map_result((n) => n * 100)
  println(big)   // Ok(500)

  // Chain operations that might fail
  let chained = safe_divide(10, 2)
    |> and_then_result((n) => safe_divide(n, 1))
  println(chained)   // Ok(5)

  // Quick checks
  println(is_ok(safe_divide(1, 1)))    // true
  println(is_err(safe_divide(1, 0)))   // true
}
```

Think of `and_then_result` like a relay race — each runner passes the baton
to the next, but if someone trips (`Err`), the race stops right there.

### The `?` shortcut

When you're writing a function that returns `maybe`, and you need to unwrap
several maybe values in a row, all those `match` blocks pile up fast — like
stacking boxes inside boxes inside boxes. 📦📦📦

The `?` operator is a shortcut. Put `?` after a maybe value and it does two
things:

- If it's `Some(v)`, you get `v` — the value inside.
- If it's `None`, the whole function returns `None` right away.

```hica
fun add_strings(a: string, b: string) : maybe<int> {
  let x = parse_int(a)?   // None → stop here, return None
  let y = parse_int(b)?   // None → stop here, return None
  Some(x + y)
}

fun main() {
  println(add_strings("3", "4"))    // Some(7)
  println(add_strings("3", "abc"))  // None
}
```

Without `?`, you'd need:

```hica
fun add_strings(a: string, b: string) : maybe<int> {
  match parse_int(a) {
    None => None,
    Some(x) => match parse_int(b) {
      None => None,
      Some(y) => Some(x + y)
    }
  }
}
```

See how `?` keeps everything flat? Think of it as asking "did this work?" —
if not, bail out.

**🎯 Try it:** Write a function `safe_first(xs: list<int>) : maybe<int>`
that uses `find(xs, (n) => n > 0)?` to find the first positive number.

