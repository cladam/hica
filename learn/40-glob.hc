// ============================================================
// Lesson 40: Glob Matching & Character Classification
// ============================================================
//
// Hica has built-in character classifiers and glob matching.
//
// Character classifiers work on `char` values:
//   is_digit(c)   — true for '0'..'9'
//   is_upper(c)   — true for 'A'..'Z'
//   is_lower(c)   — true for 'a'..'z'
//   is_alpha(c)   — true for any letter
//   is_alnum(c)   — true for letters and digits
//   is_space(c)   — true for whitespace
//   is_punct(c)   — true for punctuation
//
// String-level checkers:
//   all_digits(s)  — every character is a digit
//   all_alpha(s)   — every character is a letter
//   all_upper(s)   — every character is uppercase
//   all_lower(s)   — every character is lowercase
//
// Glob matching:
//   glob_match(pattern, s)          — * and ? wildcards
//   glob_match_path(pattern, path)  — adds ** for directories
//
// ============================================================

fun main() {
  // --- Character classification ---
  let zero = chr(48)   // '0'
  let big_a = chr(65)  // 'A'
  let little_a = chr(97) // 'a'

  println("is_digit('0'): {is_digit(zero)}")       // true
  println("is_upper('A'): {is_upper(big_a)}")      // true
  println("is_lower('a'): {is_lower(little_a)}")   // true
  println("is_alpha('A'): {is_alpha(big_a)}")      // true
  println("is_alnum('0'): {is_alnum(zero)}")       // true

  // --- String-level checks ---
  println("\nall_digits(\"2026\"): {all_digits("2026")}")   // true
  println("all_digits(\"20x6\"): {all_digits("20x6")}")    // false
  println("all_upper(\"HTTP\"): {all_upper("HTTP")}")      // true
  println("all_lower(\"http\"): {all_lower("http")}")      // true

  // --- Glob matching ---
  println("\nglob_match(\"*.txt\", \"readme.txt\"): {glob_match("*.txt", "readme.txt")}")   // true
  println("glob_match(\"*.txt\", \"readme.md\"): {glob_match("*.txt", "readme.md")}")       // false
  println("glob_match(\"h?llo\", \"hello\"): {glob_match("h?llo", "hello")}")               // true
  println("glob_match(\"h*o\", \"ho\"): {glob_match("h*o", "ho")}")                         // true
  println("glob_match(\"h*o\", \"hello\"): {glob_match("h*o", "hello")}")                   // true

  // --- Path glob matching ---
  println("\nglob_match_path(\"**/*.txt\", \"a/b/c/file.txt\"): {glob_match_path("**/*.txt", "a/b/c/file.txt")}")  // true
  println("glob_match_path(\"src/**/*.hc\", \"src/lib/util.hc\"): {glob_match_path("src/**/*.hc", "src/lib/util.hc")}")  // true
  println("glob_match_path(\"src/**/*.hc\", \"test/main.hc\"): {glob_match_path("src/**/*.hc", "test/main.hc")}")        // false

  // --- Practical: validate a simple identifier ---
  let name = "myVar123"
  let valid = all_alnum(name)
  println("\n\"{name}\" is valid identifier: {valid}")  // true
}

// ============================================================
// Challenge: Write a function that takes a list of filenames
// and a glob pattern, and returns only the matching ones.
// Hint: use filter and glob_match together!
// ============================================================
