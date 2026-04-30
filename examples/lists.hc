// Hica — list literals and operations
fun main() {
  let nums = [1, 2, 3, 4, 5];
  println(nums)

  let words = ["hello", "world"];
  println(words)

  // map — transform every element
  let doubled = map(nums, (x) => x * 2);
  println(doubled)

  // filter — keep elements that pass a test
  let big = filter(nums, (x) => x > 3);
  println(big)

  // fold — reduce a list to a single value
  let total = fold(nums, 0, (acc, x) => acc + x);
  println(total)

  // length — how many elements?
  println(length(nums))

  // reverse — flip the order
  println(reverse(nums))

  // take and drop — slice from front
  println(take(nums, 3))
  println(drop(nums, 3))

  // zip — pair up two lists
  let names = ["alice", "bob", "carol"];
  let ages  = [30, 25, 35];
  println(zip(names, ages))

  // concat — flatten a list of lists
  let nested = [[1, 2], [3, 4], [5]];
  println(concat(nested))

  // any / all — test elements
  println(any(nums, (x) => x > 4))
  println(all(nums, (x) => x > 0))

  // foreach — do something for each element
  foreach(nums, (x) => println(x * 10))
}
