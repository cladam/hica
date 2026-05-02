// Hica — for loops
// Range loops and collection loops.

fun fizzbuzz(n) =>
  if n % 15 == 0 { "fizzbuzz" }
  else if n % 3 == 0 { "fizz" }
  else if n % 5 == 0 { "buzz" }
  else { "{n}" }

fun main() {
  // Range loop: for i in start..end
  for i in 1..15 {
    println(fizzbuzz(i))
  }

  // Collection loop: for x in list
  let fruits = ["apple", "banana", "cherry"]
  for fruit in fruits {
    println("I like {fruit}!")
  }

  // Iterate over numbers
  let nums = [10, 20, 30]
  for n in nums {
    println(n * 2)
  }
}
