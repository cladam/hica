// Hica — list literals and operations
fun main() {
  let nums = [1, 2, 3, 4, 5];
  println(nums)

  let words = ["hello", "world"];
  println(words)

  // map — transform every element
  let doubled = map(nums, fn(x) => x * 2);
  println(doubled)

  // filter — keep elements that pass a test
  let big = filter(nums, fn(x) => x > 3);
  println(big)

  // fold — reduce a list to a single value
  let total = fold(nums, 0, fn(acc, x) => acc + x);
  println(total)
}
