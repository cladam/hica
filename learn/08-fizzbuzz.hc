// ============================================================
// Lesson 08: Putting It Together with FizzBuzz
// ============================================================
//
// FizzBuzz is a classic programming exercise:
//   - If n is divisible by both 3 and 5, return "fizzbuzz"
//   - If n is divisible by 3, return "fizz"
//   - If n is divisible by 5, return "buzz"
//   - Otherwise, return the number as a string
//
// This combines:
//   - Functions with =>
//   - if / else if / else chains
//   - The modulo operator (%)
//   - Expression return values
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
// Challenge: Try fizzbuzz(30), fizzbuzz(9), fizzbuzz(20).
//
// Bonus: Write a `grade(score)` function that returns
// "A" for > 89, "B" for > 79, "C" for > 69, and "F"
// otherwise. Use else if chains.
// ============================================================
