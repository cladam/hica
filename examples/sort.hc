// Sorting in hica
//
// hica provides sort_by in the prelude — a merge sort that works
// on any list type with a user-supplied comparison function.

fun main() {
  // Sort integers ascending
  let nums = [3, 1, 4, 1, 5, 9, 2, 6]
  println(sort_by(nums, (a, b) => a <= b))
  // [1, 1, 2, 3, 4, 5, 6, 9]

  // Sort strings alphabetically
  let fruits = ["banana", "apple", "cherry", "date"]
  println(sort_by(fruits, (a, b) => a <= b))
  // ["apple", "banana", "cherry", "date"]

  // Sort by string length (shortest first)
  println(sort_by(fruits, (a, b) => str_length(a) < str_length(b)))
  // ["date", "apple", "banana", "cherry"]

  // Sort descending
  println(sort_by(nums, (a, b) => a >= b))
  // [9, 6, 5, 4, 3, 2, 1, 1]
}
