// break and continue in all loop types

// --- loop with break ---
fun find_first_over_10(nums: list<int>) => {
  var result = -1
  var i = 0
  loop {
    if i >= length(nums) { break }
    let n = nums[i]
    if n > 10 {
      result = n
      break
    }
    i = i + 1
  }
  result
}

// --- while with break and continue ---
fun sum_skip_negatives(nums: list<int>) => {
  var total = 0
  var i = 0
  while i < length(nums) {
    let n = nums[i]
    i = i + 1
    if n < 0 { continue }
    total = total + n
  }
  total
}

// --- for with break ---
fun contains_zero(nums: list<int>) => {
  var found = false
  for n in nums {
    if n == 0 {
      found = true
      break
    }
  }
  found
}

// --- for range with continue ---
fun sum_odds(limit: int) => {
  var total = 0
  for i in 0..limit {
    if i % 2 == 0 { continue }
    total = total + i
  }
  total
}

// --- repeat with break ---
fun count_until_3() => {
  var count = 0
  repeat(10) {
    if count == 3 { break }
    count = count + 1
  }
  count
}

fun main() => {
  println("loop+break: {find_first_over_10([3, 7, 15, 20])}")
  println("while+continue: {sum_skip_negatives([1, -2, 3, -4, 5])}")
  println("for+break: {contains_zero([1, 2, 0, 3])}")
  println("for-range+continue: {sum_odds(10)}")
  println("repeat+break: {count_until_3()}")
}
