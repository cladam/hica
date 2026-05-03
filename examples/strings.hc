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

  let csv = "kalle,lisa,olle"
  println("split:  " + show(split(csv, ",")))
  println("join:   " + join(split(csv, ","), " & "))
  println("replace: " + replace(csv, ",", " | "))

  // --- Prelude (written in hica) ---
  println("shout           " + shout("wow"))
  println("is_empty '':    " + show(is_empty("")))
  println("is_blank '  ':  " + show(is_blank("  ")))
  println("words:          " + show(words("the  quick   fox")))
  println("lines:          " + show(lines("one\ntwo\nthree")))
  println("repeat_str:     " + repeat_str("ha", 3))
  println("pad_left:       '" + pad_left("42", 6, "0") + "'")
  println("pad_right:      '" + pad_right("hi", 6, ".") + "'")
  println("center:         '" + center("hi", 10, "-") + "'")
  println("surround:       " + surround("hello", "**"))
  println("unwords:        " + unwords(["one", "two", "three"]))
  println("unlines:        " + unlines(["a", "b", "c"]))
  println("count_substr:   " + show(count_substr("banana", "an")))

  // --- Indexing & slicing ---
  let name = "Hello"
  println("index [0]:      " + show(name[0]))
  println("slice [1:4]:    " + name[1:4])
  println("slice [:3]:     " + name[:3])
  println("slice [2:]:     " + name[2:])
  println("slice [-2:]:    " + name[-2:])

  // --- Case & prefix/suffix ---
  println("capitalize:     " + capitalize("hello"))
  println("capwords:       " + capwords("hello WORLD foo"))
  println("removeprefix:   " + removeprefix("v1.2.3", "v"))
  println("removesuffix:   " + removesuffix("file.txt", ".txt"))

  // --- Search & parse ---
  println("index_of:       " + show(index_of("hello-world", "-")))
  println("index_of none:  " + show(index_of("hello", "z")))
  println("to_int:         " + show(to_int("42")))
  println("to_int bad:     " + show(to_int("abc")))

  // --- Comparison (lexicographic) ---
  println("apple < banana: " + show("apple" < "banana"))
  println("zoo > abc:      " + show("zoo" > "abc"))
  println("abc <= abc:     " + show("abc" <= "abc"))
  println("b >= a:         " + show("b" >= "a"))
}
