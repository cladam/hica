// ============================================================
// Lesson 15: For Loops - Ranges and Collections
// ============================================================
//
// Range loop: `for i in start..end { ... }`
// Runs for each integer from start to end (inclusive).
//
// Collection loop: `for x in list { ... }`
// Runs for each element in a list.
//
// ============================================================

fun fizzbuzz(n) =>
  if n % 15 == 0 { "fizzbuzz" }
  else if n % 3 == 0 { "fizz" }
  else if n % 5 == 0 { "buzz" }
  else { "{n}" }

fun main() {
  // Range loop: for i in start..end
  for i in 1..20 {
    println(fizzbuzz(i))
  }

  // Collection loop: for x in list
  let fruits = ["apple", "banana", "cherry"]
  for fruit in fruits {
    println("I like {fruit}!")
  }
}

// ============================================================
// Challenge: Change the range to 1..100 for full fizzbuzz.
//
// Bonus: Use `for n in [10, 20, 30] { println(n * 2) }`
// to double each number and print it.
// ============================================================
