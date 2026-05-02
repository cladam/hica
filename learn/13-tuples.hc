// ============================================================
// Lesson 13: Tuples — Bundling Values Together
// ============================================================
//
// A tuple groups two or more values into one bundle.
// Wrap them in parentheses, separated by commas:
//
//   let point = (10, 20);
//   let person = ("Alice", 7);
//
// Get values out with .0, .1, .2, etc:
//
//   point.0   → 10
//   point.1   → 20
//
// Or unpack with let:
//
//   let (x, y) = point;
//
// ============================================================

fun main() {
  // Create a tuple
  let point = (10, 20);

  // Access elements
  println("{point.0}");
  println("{point.1}");

  // Destructuring
  let (x, y) = point;
  println("{x}");
  println("{y}");

  // Tuples can hold different types
  let pet = ("Rufus", 4);
  println("{pet.0}");
  println("{pet.1}")
}
