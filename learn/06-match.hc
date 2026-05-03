// ============================================================
// Lesson 06: Pattern Matching (match)
// ============================================================
//
// `match` dispatches on a value, selecting the first arm
// whose pattern matches:
//
//   match value {
//     0 => "zero",
//     1 => "one",
//     _ => "other"     // _ is the wildcard (catch-all)
//   }
//
// Always include `_` so all cases are covered.
//
// ============================================================

fun describe(x) => match x {
  0 => "zero",
  1 => "one",
  _ => "many"
}

fun main() {
  let label = describe(1)
  println(label)
}

// ============================================================
// Challenge: Expand describe to label 0 through 5
// individually ("zero", "one", ..., "five") and
// everything else as "lots".
// ============================================================
