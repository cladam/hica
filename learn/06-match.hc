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
// ── Match guards ─────────────────────────────────────────────
//
// Add `if condition` after a pattern to refine when it matches:
//
//   match n {
//     x if x < 0 => "negative",
//     _           => "non-negative"
//   }
//
// The guard can use the variable bound by the pattern.
//
// ============================================================

fun describe(x) => match x {
  0 => "zero",
  1 => "one",
  _ => "many"
}

fun classify(n) => match n {
  x if x < 0   => "negative",
  0             => "zero",
  x if x > 100 => "big",
  _             => "small positive"
}

// ── Tuple patterns ──────────────────────────────────────────
//
// Destructure tuples directly in match arms:
//
//   match point {
//     (0, 0) => "origin",
//     (x, y) => "{x}, {y}"
//   }
//
// ── Or-patterns ─────────────────────────────────────────────
//
// Match several values in one arm with `|`:
//
//   match day {
//     "Saturday" | "Sunday" => "weekend",
//     _                     => "weekday"
//   }
//
// Each alternative must be a literal or wildcard (no variable
// bindings in or-patterns).
//
// ── Range patterns ──────────────────────────────────────────
//
// Match a contiguous range of integers with `..=` (inclusive):
//
//   match score {
//     0..=59   => "F",
//     60..=69  => "D",
//     90..=100 => "A",
//     _        => "other"
//   }
//
// ============================================================

fun locate(point) => match point {
  (0, 0) => "origin",
  (x, 0) => "x-axis at {x}",
  (0, y) => "y-axis at {y}",
  (_, _) => "elsewhere"
}

fun day_type(day) => match day {
  "Saturday" | "Sunday" => "weekend",
  _                     => "weekday"
}

fun bucket(n) => match n {
  1 | 2 | 3 => "low",
  4 | 5 | 6 => "mid",
  _         => "high"
}

fun grade(score: int) => match score {
  0..=59   => "F",
  60..=69  => "D",
  70..=79  => "C",
  80..=89  => "B",
  90..=100 => "A",
  _        => "invalid"
}

fun main() {
  println(describe(1))
  println(classify(-5))
  println(classify(0))
  println(classify(42))
  println(classify(200))
  println(locate((0, 0)))
  println(locate((3, 0)))
  println(locate((0, 7)))
  println(locate((1, 2)))
  println(day_type("Saturday"))
  println(day_type("Monday"))
  println(bucket(2))
  println(bucket(5))
  println(bucket(9))
  println(grade(95))
  println(grade(72))
  println(grade(55))
}

// ============================================================
// Challenge: Write a function `http_status(code: int)` that
// uses range patterns to return "info" (100..=199),
// "success" (200..=299), "redirect" (300..=399),
// "client error" (400..=499), "server error" (500..=599),
// or "unknown" for anything else.
// ============================================================
