// ============================================================
// Lesson 02: The Magic Arrow (=>)
// ============================================================
//
// When a function does just ONE thing, you can skip the curly
// braces and use the arrow => instead.
//
// Think of it as a machine:
//   Input goes in on the left → Output comes out on the right
//
// These two are identical:
//
//   fun double(n) { n * 2 }      // block body
//   fun double(n) => n * 2        // arrow body (shorter!)
//
// ============================================================

// The "double" machine: put in x, get out x times 2
fun double(x) => x * 2

// The "square" machine: put in n, get out n times n
fun square(n) => n * n

fun main() {
  let result = double(21);
  println(result)
}

// ============================================================
// 🎯 Challenge: Write a function `triple(n)` that multiplies
//    by 3. Call it in main and see the result!
// ============================================================
