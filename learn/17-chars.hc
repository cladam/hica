// ============================================================
// Lesson 17: Characters — Single Letters & Symbols
// ============================================================
//
// A character (`char`) is a single letter, digit, or symbol.
// Characters use single quotes: 'a', 'Z', '!', '7'
// Strings use double quotes:    "hello", "world"
//
// Think of it this way:
//   'a' is one character — like a single LEGO brick
//   "a" is a string      — like a box containing one brick
//
// Characters are useful for:
//   - Working with individual letters
//   - Building lists of characters
//   - Checking what a letter is
//
// ============================================================

// You can put characters in a list
fun spell() => ['h', 'i', 'c', 'a']

fun main() {
  // A single character
  let grade = 'A';
  println(grade);

  // Characters in string interpolation
  println("your grade is {grade}");

  // A list of characters
  let letters = spell();
  println(letters);

  // Comparing characters
  println('x' == 'x');
  println('x' == 'y');

  // Check if a character is in a list
  let vowels = ['a', 'e', 'i', 'o', 'u'];
  println('e' in vowels);
  println('z' in vowels)
}

// ============================================================
// 🎯 Challenge: Write a function `is_digit(c)` that takes a
//    character and returns true if it's in
//    ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'].
// ============================================================
