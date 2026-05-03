// ============================================================
// Lesson 12: Floats
// ============================================================
//
// Integers are whole numbers: 1, 42, 100.
// Floats have a decimal point: 3.14, 0.5, 99.9.
//
// Important: floats and ints don't mix.
//   3.14 * 5     - error: 5 is an int
//   3.14 * 5.0   - correct: both are floats
//
// ============================================================

fun circle_area(r) => 3.14159 * r * r

fun to_fahrenheit(celsius) => celsius * 1.8 + 32.0

fun main() {
  let area = circle_area(5.0)
  println("{area}")

  let temp = to_fahrenheit(100.0)
  println("{temp}")
}

// ============================================================
// Challenge: Write a function `bmi(weight, height)` that
// computes weight / (height * height).
// Try it with weight = 70.0 and height = 1.75.
// ============================================================
