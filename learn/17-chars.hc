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
  let grade = 'A';
  println(grade);

  println("your grade is {grade}");

  let letters = spell();
  println(letters);

  // Comparing characters
  println('x' == 'x');
  println('x' == 'y');

  // Membership
  let vowels = ['a', 'e', 'i', 'o', 'u'];
  println('e' in vowels);
  println('z' in vowels)
}

// ============================================================
// Challenge: Write a function `is_digit(c)` that returns
// true if c is in ['0','1','2','3','4','5','6','7','8','9'].
// ============================================================
