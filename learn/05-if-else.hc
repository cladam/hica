// ============================================================
// Lesson 05: Conditional Expressions (if / else)
// ============================================================
//
// An `if` in Hica is like a fork in the road. You check a
// condition, and go left or right.
//
// IMPORTANT: both sides must give back a value! Hica won't
// let you leave one path empty.
//
//   if condition { value_a } else { value_b }
//
// You can even use if/else to SET a variable:
//
//   let bigger = if a > b { a } else { b };
//
// ============================================================

// A function that makes negative numbers positive
fun negate(x) => if x < 0 { -x } else { x }

fun main() {
  let a = if 10 > 5 { 10 } else { 5 };
  let b = negate(-3);
  println(b)
}

// ============================================================
// 🎯 Challenge: Write a function `max(a, b)` that returns
//    the larger of two numbers using if/else.
// ============================================================
