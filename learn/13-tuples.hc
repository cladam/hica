// ============================================================
// Lesson 13: Tuples
// ============================================================
//
// A tuple groups two or more values into a single unit.
//
//   let point = (10, 20)
//   let entry = ("Alicia", 14)
//
// Access elements with .0, .1, .2, etc:
//
//   point.0   // 10
//   point.1   // 20
//
// Or destructure with let:
//
//   let (x, y) = point
//
// ============================================================

fun main() {
  let point = (10, 20)

  // Access elements
  println("{point.0}")
  println("{point.1}")

  // Destructuring
  let (x, y) = point
  println("{x}")
  println("{y}")

  // Tuples can hold different types
  let entry = ("Alicia", 14)
  println("{entry.0}")
  println("{entry.1}")
}
