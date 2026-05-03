// Hica — list literals and operations
fun main() {
  let nums = [1, 2, 3, 4, 5]
  println(nums)

  let words = ["hello", "world"]
  println(words)

  // map — transform every element
  let doubled = map(nums, (x) => x * 2)
  println(doubled)

  // filter — keep elements that pass a test
  let big = filter(nums, (x) => x > 3)
  println(big)

  // fold — reduce a list to a single value
  let total = fold(nums, 0, (acc, x) => acc + x)
  println(total)

  // length — how many elements?
  println(length(nums))

  // reverse — flip the order
  println(reverse(nums))

  // take and drop — slice from front
  println(take(nums, 3))
  println(drop(nums, 3))

  // zip — pair up two lists
  let names = ["Kalle", "Lisa", "Olle"]
  let ages  = [30, 25, 35]
  println(zip(names, ages))

  // concat — flatten a list of lists
  let nested = [[1, 2], [3, 4], [5]]
  println(concat(nested))

  // any / all — test elements
  println(any(nums, (x) => x > 4))
  println(all(nums, (x) => x > 0))

  // foreach — do something for each element
  foreach(nums, (x) => println(x * 10))

  // indexing — get a single element
  println(nums[0])
  println(nums[2])

  // slicing — get a sub-list
  println(nums[1:3])
  println(nums[:2])
  println(nums[3:])

  // negative indexing — count from end
  println(nums[-1])
  println(nums[-2])

  // prepend using cons
  println(cons(0, nums))

  // list concatenation with +
  let more = nums + [6, 7, 8]
  println(more)

  // in operator — membership test
  println(3 in nums)
  println(9 in nums)

  // enumerate — pair each element with its index
  println(enumerate(words))

  // find — first element matching a predicate
  println(find(nums, (x) => x > 3))
  println(find(nums, (x) => x > 99))
}
