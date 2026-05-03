// ============================================================
// Lesson 10: Strings
// ============================================================
//
// Strings are one of hica's most versatile types.
//
// 1. Concatenation with `+`:
//      "hello" + " " + "world"
//
// 2. Interpolation with `{expr}` inside a string:
//      "hello, {name}!"
//      Numbers and booleans are automatically converted inside {}.
//
// 3. Indexing with `s[i]` — returns a character:
//      "hello"[0]   =>  'h'
//      "hello"[-1]  =>  'o'   (negative = from end)
//
// 4. Slicing with `s[start:end]` — returns a string:
//      "hello"[1:4]  =>  "ell"
//      "hello"[:3]   =>  "hel"
//      "hello"[2:]   =>  "llo"
//
// 5. Utility functions — available everywhere:
//      str_length, trim, to_upper, to_lower, split, join,
//      contains, starts_with, ends_with, replace,
//      capitalize, capwords, removeprefix, removesuffix, ...
//
// 6. Comparison operators (lexicographic):
//      "apple" < "banana"   =>  true
//      "abc" <= "abc"       =>  true
//
// ============================================================

// Concatenation: join strings with +
fun yell(word) => word + "!"

// Interpolation: embed values directly in a string
fun greet(name) => "hello, {name}!"

fun main() {
  // --- Building strings ---
  println(yell("wow"))
  println(greet("hica"))
  let apples = 5
  println("{apples} apples")

  // --- Indexing & slicing ---
  let s = "hello"
  println(s[0])         // 'h'
  println(s[-1])        // 'o'
  println(s[1:4])       // "ell"
  println(s[:3])        // "hel"
  println(s[2:])        // "llo"

  // --- Utility functions ---
  let msg = "  Hello, World!  "
  println(trim(msg))
  println(to_upper(trim(msg)))
  println(contains(msg, "World"))
  println(split("a,b,c", ","))
  println(join(["x", "y", "z"], "-"))
  println(replace("banana", "a", "o"))

  // --- Prelude helpers (written in hica) ---
  println(capitalize("hello"))
  println(capwords("hello WORLD"))
  println(removeprefix("v1.2.3", "v"))
  println(removesuffix("file.txt", ".txt"))
  println(words("the  quick   fox"))
  println(pad_left("42", 6, "0"))
  println(center("hi", 10, "-"))

  // --- Comparison (lexicographic) ---
  println("apple" < "banana")   // true
  println("zoo" > "abc")        // true
  println("abc" <= "abc")        // true
}

// ============================================================
// Challenge 1: Write a function `initials(name)` that takes
// a full name like "Ada Lovelace" and returns "A.L."
// Hint: use words(), indexing, and concatenation.
//
// Challenge 2: Write a function `censor(s, word)` that
// replaces `word` with "***" in the string `s`.
// ============================================================
