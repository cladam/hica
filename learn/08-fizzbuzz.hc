// ============================================================
// Lesson 08: Putting it All Together — FizzBuzz
// ============================================================
//
// FizzBuzz is a classic programming challenge:
//   - If n is divisible by both 3 and 5, say "fizzbuzz"
//   - If n is divisible by 3, say "fizz"
//   - If n is divisible by 5, say "buzz"
//   - Otherwise, show the number
//
// This uses everything you've learned:
//   ✅ Functions with =>
//   ✅ if / else if / else chains
//   ✅ The modulo operator (%)
//   ✅ The last-line rule
//
// ============================================================

fun fizzbuzz(n) =>
  if n % 15 == 0 { "fizzbuzz" }
  else if n % 3 == 0 { "fizz" }
  else if n % 5 == 0 { "buzz" }
  else { show(n) }

fun main() {
  println(fizzbuzz(1))
  println(fizzbuzz(3))
  println(fizzbuzz(5))
  println(fizzbuzz(15))
  println(fizzbuzz(7))
}

// ============================================================
// 🎯 Challenge: Try fizzbuzz(30) — what does it print?
//    What about fizzbuzz(9)? fizzbuzz(20)?
//
// 🎯 Bonus: Write a `grade(score)` function that returns
//    "A" for > 89, "B" for > 79, "C" for > 69, and "F"
//    otherwise. Use else if chains.
// ============================================================
