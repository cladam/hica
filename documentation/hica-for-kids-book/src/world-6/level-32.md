# Level 32. Projects

Ready for something bigger? Try these!

### Project 1: The Calculator

Build functions for basic math operations:

```hica
fun add(a, b) => a + b
fun multiply(a, b) => a * b

fun main() {
  let sum = add(15, 27)
  let product = multiply(6, 7)
  println(product)
}
```

**Challenge:** Add a `power` function that computes `a * a` (squaring). Can
you do `a * a * a` (cubing)?

### Project 2: The Grade Machine

```hica
fun grade(score) =>
  if score > 89 { "A" }
  else if score > 79 { "B" }
  else if score > 69 { "C" }
  else { "Try harder!" }

fun main() {
  let my_grade = grade(85)
  println(my_grade)
}
```

**Challenge:** Add a grade for "D" (60–69).

### Project 3: The Number Describer

```hica
fun describe(x) => match x {
  0 => "zero",
  1 => "one",
  _ => "many"
}

fun sign(n) =>
  if n > 0 { "positive" }
  else if n == 0 { "zero" }
  else { "negative" }

fun main() {
  let a = describe(0)
  let b = sign(-5)
  println(b)
}
```

**Challenge:** Combine `describe` and `sign`. Call one function from another!

### Project 4: The Banner Maker

Make a function that centers text inside a fancy banner:

```hica
fun main() {
  let title = "HICA"
  let banner = center(title, 20, "=")
  println(banner)
  println(center("cool stuff", 20, "-"))
  println(center(title, 20, "="))
}
```

Output:

```
========HICA========
-----cool stuff-----
========HICA========
```

**Challenge 1:** Use `surround` to add a border on the sides too, like
`| ========HICA======== |`.

**Challenge 2:** Can you make a box? Try printing a top line, a centered
title, and a bottom line:

```
********************
*       HICA       *
********************
```

Hint: use `repeat_str("*", 20)` for the top and bottom, and
`"*" + center("HICA", 18, " ") + "*"` for the middle.

