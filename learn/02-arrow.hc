// ============================================================
// Lesson 02: Arrow Syntax (=>)
// ============================================================
//
// When a function body is a single expression, you can skip
// the curly braces and use `=>` instead.
//
// These two are equivalent:
//
//   fun double(n) { n * 2 }      // block body
//   fun double(n) => n * 2        // arrow body (shorter)
//
// ============================================================

fun double(x) => x * 2

fun square(n) => n * n

fun main() {
  let result = double(21);
  println(result)
}

// ============================================================
// Challenge: Write a function `triple(n)` that multiplies
// by 3. Call it in main and print the result.
// ============================================================
