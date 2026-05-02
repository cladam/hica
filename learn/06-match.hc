// ============================================================
// Lesson 06: Pattern Matching (match)
// ============================================================
//
// When you have many choices, use `match`. It's like a sorting
// machine — drop a value in, and it lands in the right slot!
//
//   match value {
//     0 => "zero",
//     1 => "one",
//     _ => "other"     // _ catches everything else
//   }
//
// Always include `_` (the wildcard) so nothing falls through!
//
// ============================================================

fun describe(x) => match x {
  0 => "zero",
  1 => "one",
  _ => "many"
}

fun main() {
  let label = describe(1);
  println(label)
}

// ============================================================
// 🎯 Challenge: Expand describe to label 0 through 5
//    individually ("zero", "one", "two", ..., "five") and
//    everything else as "lots".
// ============================================================
