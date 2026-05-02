// ============================================================
// Lesson 09: Repeating Things — repeat
// ============================================================
//
// Sometimes you want to do something multiple times.
// Hica has `repeat(n) { ... }` which runs a block n times.
//
// This is great for:
//   - Printing something several times
//   - Running an action a fixed number of times
//
// New concept:
//   ✅ repeat(n) { body } — runs body n times
//
// Note: repeat doesn't give you a counter variable.
// For counted loops, we'll add `for` in a future lesson!
//
// ============================================================

fun main() {
  repeat(5) {
    println("hica!")
  }
}

// ============================================================
// 🎯 Challenge: Change the count to 10 — does it print 10
//    times?
//
// 🎯 Bonus: Try repeat(0) { ... } — what happens? What
//    about repeat(1)?
// ============================================================
