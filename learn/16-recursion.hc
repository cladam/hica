// ============================================================
// Lesson 16: Recursion — Functions That Call Themselves
// ============================================================
//
// What if a function could call *itself*? That's recursion!
// It's like Russian dolls: open one, and there's a smaller
// one inside. Keep going until you find the tiniest doll.
//
// Every recursive function needs two parts:
//   1. A BASE CASE — when to stop (the tiniest doll)
//   2. A RECURSIVE CASE — break the problem into a smaller piece
//
// New concept:
//   ✅ A function calling itself
//   ✅ Base case (stopping condition)
//   ✅ Recursive case (smaller subproblem)
//
// ============================================================

// Factorial: 5! = 5 × 4 × 3 × 2 × 1 = 120
fun factorial(n) => if n <= 1 { 1 } else { n * factorial(n - 1) }

// Sum from 1 to n: sum_to(4) = 4 + 3 + 2 + 1 = 10
fun sum_to(n) => if n <= 0 { 0 } else { n + sum_to(n - 1) }

// GCD: find the biggest number that divides both evenly
// gcd(12, 8) = 4
fun my_gcd(a, b) => if b == 0 { a } else { my_gcd(b, a % b) }

fun main() {
  println(factorial(5));
  println(sum_to(100));
  println(my_gcd(12, 8))
}

// ============================================================
// 🎯 Challenge: Write a `power(base, exp)` function that
//    computes base^exp using recursion.
//    Hint: power(2, 3) = 2 * power(2, 2)
//          power(2, 0) = 1  (base case!)
//
// 🎯 Bonus: What does factorial(0) return? Why?
//
// 🎯 Think about it: What happens if you forget the base case?
//    (The program would run forever — like dolls that never end!)
// ============================================================
