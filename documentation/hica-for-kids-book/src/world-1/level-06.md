# Level 6. Data Types: What Goes in the Box?

Different boxes hold different things. Hica has five main types right now:

### Integers (`int`)

Whole numbers, no decimals. Like counting your toys.

```hica
fun main() {
  let age = 11
  let score = 100
  println(score)
}
```

### Floats (`float`)

Numbers with a decimal point. Like measuring your height or weighing
ingredients for a recipe.

```hica
fun main() {
  let pi = 3.14159
  let temp = 36.6
  println("{temp}")
}
```

Floats and integers are different types. If a function uses `3.14 * r`,
then `r` must also be a float (like `5.0`, not `5`).

### Strings (`string`)

Text: words, sentences, emoji. Always wrapped in double quotes `" "`.

```hica
fun main() {
  let name = "Alex"
  let greeting = "Hello!"
  println(greeting)
}
```

### Booleans (true / false)

Like a light switch: on or off. Used for yes/no questions.

```hica
fun main() {
  let is_raining = 10 > 5     // true!
  println(is_raining)
}
```

### Characters (`char`)

A single letter, digit, or symbol. Always wrapped in single quotes `' '`.

```hica
fun main() {
  let grade = 'A'
  let star = '*'
  println(grade)
}
```

Characters are different from strings:
- `'a'` is a **character**: one single letter
- `"a"` is a **string**. Text that happens to be one letter long

Think of it like LEGO: a character is one brick, a string is a whole row of bricks.

**🎯 Try it:** Create variables for your name, your age, and whether you like
pizza. What types are they?
