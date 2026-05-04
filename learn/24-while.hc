// Lesson 24: While loops and mutable variables
//
// hica has two kinds of variables:
//   let x = 10    — immutable (cannot be changed)
//   var x = 10    — mutable (can be reassigned with x = newValue)
//
// while loops repeat a block as long as a condition is true.
// Combined with var, they let you write classic counting loops.

fun countdown(n) {
  var i = n
  while i > 0 {
    println(i)
    i = i - 1
  }
  println("liftoff!")
}

// Accumulate a sum with var and while
fun sum_to(n) {
  var total = 0
  var i = 1
  while i <= n {
    total = total + i
    i = i + 1
  }
  total
}

fun main() {
  countdown(5)

  let result = sum_to(100)
  println("sum of 1..100 = {result}")
}

// Challenge: write a function that uses while to find the first
// power of 2 that exceeds 1000. (Answer: 1024)
