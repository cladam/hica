// ============================================================
// Lesson 18: Maybe - Optional Values
// ============================================================
//
// `maybe` represents a value that might or might not exist:
//
//   Some(value) - the value is present
//   None        - no value
//
// Use `match` to handle both cases.
//
// ============================================================

// A function that might not find what you want
fun find_positive(n) =>
  if n > 0 { Some(n) }
  else { None }

fun main() {
  // Create a maybe value
  let a = Some(42)
  println(a)

  // Match on a maybe — get the value out safely
  match a {
    Some(n) => println("found: {n}"),
    None    => println("nothing found")
  }

  // None — nothing here
  match find_positive(-5) {
    Some(n) => println("positive: {n}"),
    None    => println("not positive")
  }

  // Using maybe from a function
  match find_positive(10) {
    Some(n) => println("positive: {n}"),
    None    => println("not positive")
  }

  // Some wraps any value
  let name = Some("Alicia")
  match name {
    Some(n) => println("hello, {n}!"),
    None    => println("hello, stranger!")
  }
}

// ============================================================
// Challenge: Write a function `safe_head(nums)` that
// returns Some(nums[0]) if the list is not empty,
// or None if it is. Then match on the result in main.
// ============================================================
