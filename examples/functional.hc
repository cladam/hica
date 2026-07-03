fun make_multiplier(factor) => (x) => x * factor

fun main() {
  let triple = make_multiplier(3)
  let nums = [1..5]
  println(map(nums, triple))   // [3, 6, 9, 12, 15]
}