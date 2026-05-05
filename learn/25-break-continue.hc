// ============================================================
// Lesson 25: Break, Continue, and Loop
// ============================================================
//
// All hica loops support `break` and `continue`:
//   break     — exit the loop immediately
//   continue  — skip the rest of this iteration
//
// There is also `loop { ... }`, which repeats forever
// until you break out of it.
//
// These work in while, for, repeat, and loop.
//
// ============================================================

// loop + break: search until you find what you want
fun find_negative(nums: list<int>) => {
  var result = None
  var i = 0
  loop {
    if i >= length(nums) { break }
    if nums[i] < 0 {
      result = Some(nums[i])
      break
    }
    i = i + 1
  }
  result
}

// while + continue: skip unwanted items
fun sum_positives(nums: list<int>) => {
  var total = 0
  var i = 0
  while i < length(nums) {
    let n = nums[i]
    i = i + 1
    if n <= 0 { continue }
    total = total + n
  }
  total
}

// for + break: stop early
fun take_until_zero(nums: list<int>) => {
  var collected: list<int> = []
  for n in nums {
    if n == 0 { break }
    collected = collected + [n]
  }
  collected
}

// for-range + continue: skip even numbers
fun sum_odds(limit: int) => {
  var total = 0
  for i in 0..limit {
    if i % 2 == 0 { continue }
    total = total + i
  }
  total
}

fun main() {
  // loop + break
  let neg = find_negative([3, 7, -2, 10])
  println("first negative: {neg}")

  // while + continue
  println("sum of positives: {sum_positives([1, -2, 3, -4, 5])}")

  // for + break
  let taken = take_until_zero([1, 2, 3, 0, 4, 5])
  println("taken until zero: {taken}")

  // for-range + continue
  println("sum of odds 0..10: {sum_odds(10)}")
}

// ============================================================
// Expected output:
//   first negative: Just(-2)
//   sum of positives: 9
//   taken until zero: [1,2,3]
//   sum of odds 0..10: 25
//
// Challenge: Write a function that uses loop + break to find
// the first power of 2 that exceeds 1000. (Answer: 1024)
// ============================================================
