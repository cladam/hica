// ============================================================
// Lesson 05: Conditional Expressions (if / else)
// ============================================================
//
// `if`/`else` are expressions in hica - they return values.
//
// Both branches must produce a value of the same type:
//
//   if condition { value_a } else { value_b }
//
// You can use if/else to bind a variable:
//
//   let bigger = if a > b { a } else { b }
//
// ============================================================

fun negate(x) => if x < 0 { -x } else { x }

fun main() {
  let a = if 10 > 5 { 10 } else { 5 }
  let b = negate(-3)
  println(b)
}

// ============================================================
// Challenge: Write a function `max(a, b)` that returns
// the larger of two numbers using if/else.
// ============================================================
