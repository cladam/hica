// ============================================================
// Lesson 28: Random Numbers
// ============================================================
//
// `random(min, max)` returns a random integer in the range
// [min, max) — min is included, max is excluded.
//
//   let die = random(1, 7)    // 1, 2, 3, 4, 5, or 6
//   let coin = random(0, 2)   // 0 or 1
//
// Each call produces a different value (the effect is `ndet`,
// non-determinism). No seeding needed — hica uses a strong
// random source automatically.
//
// ============================================================

fun roll_die() {
  let roll = random(1, 7)
  println("You rolled a {roll}")
}

fun coin_flip() {
  let side = random(0, 2)
  if side == 0 { println("Heads!") }
  else { println("Tails!") }
}

fun random_list() {
  // Generate 5 random numbers between 1 and 100
  let nums = [1, 2, 3, 4, 5].map((_) => random(1, 101))
  println("Random numbers: {nums}")
}

fun main() {
  roll_die()
  coin_flip()
  random_list()
}

// ============================================================
// Expected output (example — yours will differ):
//   You rolled a 4
//   Tails!
//   Random numbers: [73, 12, 95, 41, 58]
//
// Challenge: Write a number guessing game. Pick a random number
// between 1 and 10, then use `input()` to let the user guess.
// Tell them if they're right or wrong.
// ============================================================
