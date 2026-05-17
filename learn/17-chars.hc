// ============================================================
// Lesson 17: Characters
// ============================================================
//
// A `char` is a single character: a letter, digit, or symbol.
// Characters use single quotes: 'a', 'Z', '!', '7'
// Strings use double quotes:    "hello", "world"
//
//   'a' is a char   - a single character
//   "a" is a string - a string containing one character
//
// ============================================================

fun spell() => ['h', 'i', 'c', 'a']

fun main() {
  let grade = 'A'
  println(grade)

  println("your grade is {grade}")

  let letters = spell()
  println(letters)

  // Comparing characters
  println('x' == 'x')
  println('x' == 'y')

  // Membership
  let vowels = ['a', 'e', 'i', 'o', 'u']
  println('e' in vowels)
  println('z' in vowels)
}

// ============================================================
// Challenge: `is_digit(c)` is now built into the prelude!
// Try it: println(is_digit(chr(48)))  — prints true
//
// Can you write `is_vowel(c)` that returns true for
// 'a', 'e', 'i', 'o', 'u' (and their uppercase forms)?
// Hint: use is_lower, to_lower, or a list check.
// ============================================================
