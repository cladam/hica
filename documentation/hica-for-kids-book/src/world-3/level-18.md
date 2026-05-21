# Level 18. Building Strings

Sometimes you want to build a message from pieces. Hica gives you two ways.

### Gluing strings with `+`

The `+` operator works on strings too — it stitches them together:

```hica
fun shout(word) => word + "!"

fun main() {
  println(shout("wow"))
}
```

### String interpolation with `{}`

Even easier: put `{expr}` right inside a string, and Hica fills in the value:

```hica
fun greet(name) => "hello, {name}!"

fun main() {
  println(greet("world"))
}
```

Numbers and booleans are converted automatically:

```hica
fun main() {
  let apples = 5
  println("{apples} apples")
}
```

You can even put expressions inside the braces:

```hica
fun main() {
  let a = 3
  let b = 4
  println("{a} + {b} = {a + b}")
}
```

Think of `{}` as little windows into your code — whatever you put inside gets
turned into text and dropped into the string.

**🎯 Try it:** Write a function `introduce(name, age)` that returns
`"my name is ___ and I am ___ years old"`.

### String tools

Hica comes with built-in tools for working with strings — no imports needed:

```hica
fun main() {
  let msg = "  Hello, World!  "

  // Trimming — remove extra spaces
  println(trim(msg))           // "Hello, World!"

  // Searching
  println(contains(msg, "World"))    // true
  println(starts_with(trim(msg), "Hello"))  // true

  // Changing case
  println(to_upper("hello"))  // "HELLO"
  println(to_lower("HELLO"))  // "hello"

  // Splitting and joining
  println(split("a,b,c", ","))        // ["a", "b", "c"]
  println(join(["a", "b", "c"], "-")) // "a-b-c"

  // How long is it?
  println(str_length("hello"))  // 5
}
```

Think of these like tools in a toolbox:

| Tool | What it does | Example |
| --- | --- | --- |
| `str_length(s)` | Count the characters | `str_length("hi")` → `2` |
| `trim(s)` | Remove spaces from the edges | `trim("  hi  ")` → `"hi"` |
| `contains(s, sub)` | Is `sub` inside `s`? | `contains("hello", "ell")` → `true` |
| `to_upper(s)` | ALL CAPS | `to_upper("hi")` → `"HI"` |
| `to_lower(s)` | all lowercase | `to_lower("HI")` → `"hi"` |
| `split(s, sep)` | Break into a list | `split("a-b", "-")` → `["a", "b"]` |
| `join(xs, sep)` | Glue a list together | `join(["a", "b"], "-")` → `"a-b"` |
| `replace(s, old, new)` | Swap parts | `replace("hi", "i", "ey")` → `"hey"` |

**🎯 Try it:** Use `split` to break `"red,green,blue"` into a list, then
`join` it back with `" and "`.

### Special characters (escape sequences)

What if you want to put a double-quote *inside* a string? You can't just
write `"She said "hi""` — Hica would think the string ends at the second `"`.

The trick: put a backslash `\` before the special character. The backslash
says "the next character is literal, not magic":

```hica
fun main() {
  println("She said \"hi\"")   // She said "hi"
  println("one\\two")          // one\two  (literal backslash)
}
```

There are also shortcuts for invisible characters:

| Escape | What it does | |
| --- | --- | --- |
| `\"` | A literal `"` inside a string | `"say \"hi\""` |
| `\\` | A literal backslash | `"C:\\folder"` |
| `\n` | Start a new line | `"line1\nline2"` |
| `\t` | A tab (big space) | `"col1\tcol2"` |

```hica
fun main() {
  println("line one\nline two")  // prints on two lines!
  println("name\tage")
  println("Ada\t12")
}
```

Escapes work inside interpolated strings too:

```hica
fun main() {
  let name = "world"
  println("hello, {name}!\ngoodbye!")
}
```

**🎯 Try it:** Print a tiny two-line poem using `\n` to separate the lines.

### Peeking inside strings (indexing and slicing)

You can grab individual characters or pieces of a string using square brackets
— just like picking cards out of a deck:

```hica
fun main() {
  let s = "hello"
  println(s[0])      // 'h' — the first character
  println(s[1])      // 'e' — the second character
  println(s[-1])     // 'o' — the last character!
}
```

Negative numbers count from the end: `-1` is the last character, `-2` is
the second-to-last, and so on.

You can also grab a **slice** — a piece of the string:

```hica
fun main() {
  let s = "hello"
  println(s[1:4])    // "ell" — from position 1 up to (not including) 4
  println(s[:3])     // "hel" — the first 3 characters
  println(s[3:])     // "lo"  — from position 3 to the end
}
```

| Syntax | What you get | Example with `"hello"` |
| --- | --- | --- |
| `s[i]` | One character | `s[0]` → `'h'` |
| `s[i:j]` | Substring from i to j | `s[1:4]` → `"ell"` |
| `s[:j]` | First j characters | `s[:3]` → `"hel"` |
| `s[i:]` | From i to the end | `s[3:]` → `"lo"` |
| `s[-1]` | Last character | `s[-1]` → `'o'` |

Think of it like a ruler laid along the string — the numbers mark the gaps
*between* characters, and you pick the piece between two marks.

**🎯 Try it:** Given `let word = "abcdef"`, what is `word[2:5]`?
What about `word[-2]`?

