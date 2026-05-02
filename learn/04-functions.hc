// ============================================================
// Lesson 04: Functions and Chaining
// ============================================================
//
// Functions are little machines. You put something in, they
// do some work, and something comes out.
//
// You can CHAIN machines — feed the output of one into the
// next, like an assembly line in a factory.
//
//   fun double(n) => n * 2
//   fun square(n) => n * n
//
//   let a = double(3);     // a = 6
//   let b = square(a);     // b = 36
//
// ============================================================

fun double(n) => n * 2

fun square(n) => n * n

fun main() {
  let a = double(3);
  let b = square(a);
  println(b)
}

// ============================================================
// 🎯 Challenge: Add a `half(n)` function that divides by 2.
//    Chain all three: double → square → half.
//    What do you get for double(3) → square → half?
// ============================================================
