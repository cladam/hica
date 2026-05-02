// ============================================================
// Lesson 07: Boolean Logic
// ============================================================
//
// Boolean values are `true` and `false`.
//
// Comparison operators:
//   ==   equal          !=   not equal
//   >    greater than   <    less than
//   >=   greater/equal  <=   less/equal
//
// Logical operators:
//   &&   AND - both must be true
//   ||   OR  - at least one must be true
//
// ============================================================

fun classify(n) =>
  if n > 0 && n < 100 { "in range" }
  else { "out of range" }

fun main() {
  let result = classify(42);
  println(result)
}

// ============================================================
// Challenge: Write a function `is_teen(age)` that returns
// "teenager" if age is between 13 and 19 (inclusive), and
// "not a teenager" otherwise.
// Hint: age >= 13 && age <= 19
// ============================================================
