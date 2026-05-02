// ============================================================
// Lesson 04: Functions and Chaining
// ============================================================
//
// Functions take inputs and produce outputs. You can chain
// them by passing the result of one as input to the next.
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
// Challenge: Add a `half(n)` function that divides by 2.
// Chain all three: double -> square -> half.
// What do you get for double(3) -> square -> half?
// ============================================================
