# Level 7. Operators: The Math Toolkit

Operators are the symbols that do things with your values.

### Arithmetic (number crunching)

| Operator | Meaning | Example | Result |
| --- | --- | --- | --- |
| `+` | Add | `3 + 4` | `7` |
| `-` | Subtract | `10 - 3` | `7` |
| `*` | Multiply | `5 * 2` | `10` |
| `/` | Divide | `10 / 3` | `3` |
| `%` | Remainder | `10 % 3` | `1` |

These operators work on both integers and floats:

```hica
fun main() {
  let price = 5
  let quantity = 3
  let total = price * quantity
  println(total)
}
```

### Comparison (asking questions)

| Operator | Meaning | Example | Result |
| --- | --- | --- | --- |
| `==` | Equal to? | `5 == 5` | `true` |
| `!=` | Not equal? | `5 != 3` | `true` |
| `>` | Greater than? | `10 > 5` | `true` |
| `<` | Less than? | `3 < 7` | `true` |
| `>=` | Greater or equal? | `5 >= 5` | `true` |
| `<=` | Less or equal? | `4 <= 3` | `false` |

### Logic (combining questions)

| Operator | Meaning | Example |
| --- | --- | --- |
| `&&` | AND — both must be true | `x > 0 && x < 100` |
| `\|\|` | OR — at least one must be true | `x == 0 \|\| x == 1` |

**🎯 Try it:** Write a `fun main()` that computes how many seconds are in an
hour (60 × 60).

---
