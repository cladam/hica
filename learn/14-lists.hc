// ============================================================
// Lesson 14: Lists
// ============================================================
//
// A list holds zero or more values of the same type.
//
//   [1, 2, 3]        - list of ints
//   ["hi", "there"]  - list of strings
//   []               - empty list
//
// All elements must be the same type:
//   [1, 2, 3]      // ok
//   [1, "hello"]   // type error
//
// Standard library functions for lists:
//
//   map(list, fn)        - apply fn to every element
//   filter(list, fn)     - keep elements where fn is true
//   fold(list, init, fn) - reduce to a single value
//   length(list)         - number of elements
//   reverse(list)        - reverse order
//   take(list, n)        - first n elements
//   drop(list, n)        - skip first n elements
//   zip(a, b)            - pair up two lists
//   concat(lists)        - flatten a list of lists
//   any(list, fn)        - true if any element passes
//   all(list, fn)        - true if every element passes
//   foreach(list, fn)    - run fn on each element
//   cons(x, list)        - prepend x to the front
//   enumerate(list)      - pair elements with their index
//   find(list, fn)        - first element matching fn (returns maybe)
//
// ============================================================

fun main() {
  // Create a list
  let nums = [10, 20, 30]
  println(nums)

  // Lists can hold strings too
  let greetings = ["hello", "hej", "hola"]
  println(greetings)

  // map — transform every element
  let doubled = map(nums, (x) => x * 2)
  println(doubled)

  // filter — keep only elements that pass a test
  let big = filter(nums, (x) => x > 15)
  println(big)

  // fold — combine all elements into one value
  let total = fold(nums, 0, (acc, x) => acc + x)
  println(total)

  // length — how many elements?
  println(length(nums))

  // reverse — flip the order
  println(reverse(greetings))

  // take / drop — slice from front
  println(take(nums, 2))
  println(drop(nums, 2))

  // zip — pair up two lists
  println(zip(nums, greetings))

  // concat — flatten a list of lists
  println(concat([[1, 2], [3, 4]]))

  // any / all — test elements
  println(any(nums, (x) => x > 25))
  println(all(nums, (x) => x > 5))

  // foreach — do something for each element
  foreach(greetings, (g) => println(g))

  // indexing — get a single element by position
  println(nums[0])
  println(greetings[1])

  // slicing — get a sub-list
  println(nums[0:2])
  println(nums[:2])
  println(nums[1:])

  // negative indexing — count from the end
  println(nums[-1])

  // prepend — add to the front (fast!)
  println(cons(0, nums))

  // append — add to the end
  println(nums + [40])

  // concatenation with +
  println(nums + [40, 50])

  // membership with "in"
  println(20 in nums)
  println(99 in nums)

  // enumerate — pair elements with their index
  println(enumerate(greetings))

  // find — first element matching a predicate
  println(find(nums, (x) => x > 15))
  println(find(nums, (x) => x > 100))
}

// ============================================================
// Challenge: Create a list of numbers and print it.
//
// Challenge: Use map to add 100 to every number.
//
// Challenge: Use filter to keep only even numbers from
// [1, 2, 3, 4, 5, 6]. (Hint: x % 2 == 0)
//
// Bonus: What happens if you try [1, "two", 3]?
// ============================================================
