// String utilities: primitives + prelude functions

fun main() {
  let msg = "  Hello, World!  "

  // --- Primitives ---
  println("length:     " + show(str_length(msg)))
  println("trimmed:    '" + trim(msg) + "'")
  println("upper:      " + to_upper(trim(msg)))
  println("lower:      " + to_lower(trim(msg)))

  println("contains 'World': " + show(contains(msg, "World")))
  println("starts_with 'He': " + show(starts_with(trim(msg), "He")))
  println("ends_with '!':    " + show(ends_with(trim(msg), "!")))

  let csv = "alice,bob,charlie"
  println("split:  " + show(split(csv, ",")))
  println("join:   " + join(split(csv, ","), " & "))
  println("replace: " + replace(csv, ",", " | "))

  // --- Prelude (written in hica) ---
  println("is_empty '':    " + show(is_empty("")))
  println("is_blank '  ':  " + show(is_blank("  ")))
  println("words:          " + show(words("the  quick   fox")))
  println("lines:          " + show(lines("one\ntwo\nthree")))
  println("repeat_str:     " + repeat_str("ha", 3))
  println("pad_left:       '" + pad_left("42", 6, "0") + "'")
  println("pad_right:      '" + pad_right("hi", 6, ".") + "'")
  println("surround:       " + surround("hello", "**"))
}
