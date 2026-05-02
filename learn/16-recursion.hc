// ============================================================
// Lesson 16: Recursion
// ============================================================
//
// A recursive function calls itself to solve smaller
// subproblems.
//
// Every recursive function needs:
//   1. A base case - when to stop
//   2. A recursive case - break the problem down
//
// ============================================================

// Factorial: 5! = 5 * 4 * 3 * 2 * 1 = 120
fun factorial(n) => if n <= 1 { 1 } else { n * factorial(n - 1) }

// Sum from 1 to n: sum_to(4) = 4 + 3 + 2 + 1 = 10
fun sum_to(n) => if n <= 0 { 0 } else { n + sum_to(n - 1) }

// GCD using Euclid's algorithm: gcd(12, 8) = 4
fun my_gcd(a, b) => if b == 0 { a } else { my_gcd(b, a % b) }

fun main() {
  println(factorial(5));
  println(sum_to(100));
  println(my_gcd(12, 8))
}

// ============================================================
// Challenge: Write a `power(base, exp)` function that
// computes base^exp using recursion.
// Hint: power(2, 3) = 2 * power(2, 2)
//       power(2, 0) = 1  (base case)
//
// Bonus: What does factorial(0) return? Why?
// ============================================================
