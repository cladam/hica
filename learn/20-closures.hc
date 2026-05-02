// ============================================================
// Lesson 20: Closures — Functions That Remember
// ============================================================
//
// A closure is a function that "remembers" values from the
// place where it was created.
//
// You've already seen anonymous functions:
//
//   let double = (x) => x * 2
//
// But closures can capture variables from their surroundings:
//
//   let factor = 10
//   let scale = (x) => x * factor   // captures "factor"
//
// You can even write functions that RETURN new functions:
//
//   fun make_adder(n) => (x) => x + n
//
// And you can write your own higher-order functions —
// functions that take other functions as arguments:
//
//   fun apply(f, x) => f(x)
//
// ============================================================

// A function that builds a new function
fun make_adder(n) => (x) => x + n

// A higher-order function: takes a function and a value
fun apply(f, x) => f(x)

// Apply a function twice
fun twice(f, x) => f(f(x))

fun main() {
  // 1. Closures stored in variables
  let double = (x) => x * 2
  println(double(5))

  // 2. Closures capture their surroundings
  let factor = 10
  let scale = (x) => x * factor
  println(scale(7))

  // 3. Functions that return functions
  let add5 = make_adder(5)
  println(add5(10))
  println(make_adder(100)(1))

  // 4. Passing functions to higher-order functions
  println(apply(double, 21))
  println(apply(add5, 7))

  // 5. Applying a function twice
  println(twice(double, 3))

  // 6. Closures work great with pipes too
  let result = 4 |> double |> scale
  println(result)
}

// ============================================================
// 🎯 Challenge: Write a `make_multiplier(n)` function that
//    returns a closure multiplying its argument by n.
//    Then use it: make_multiplier(3)(7) should give 21.
//
// 🎯 Bonus: Write a `compose(f, g)` function that returns
//    a new function: (x) => g(f(x)).
//    Use it to combine double and add5 into one function.
// ============================================================
