// ============================================================
// Lesson 35: Slice Patterns — Destructuring Lists in Match
// ============================================================
//
// Lists can be destructured in match just like tuples and
// structs. Use brackets to match on list shape:
//
//   []           — matches an empty list
//   [x]          — matches a list with exactly one element
//   [x, y]       — matches exactly two elements
//   [x, ..rest]  — matches one or more: head + tail
//   [x, y, ..]   — matches two or more, ignore the rest
//
// This makes recursive list processing very readable.
//
// ============================================================

// --- Describe a list by its shape ---
fun describe(xs: list<int>) : string => match xs {
  []           => "empty",
  [x]          => "just {x}",
  [x, y]       => "{x} and {y}",
  [x, ..rest]  => "starts with {x}, {length(rest)} more"
}

// --- Recursive sum using slice patterns ---
fun sum(xs: list<int>) : int => match xs {
  []          => 0,
  [x, ..rest] => x + sum(rest)
}

// --- Check if a list is sorted (ascending) ---
fun sorted(xs: list<int>) : bool => match xs {
  []              => true,
  [_]             => true,
  [a, b, ..rest]  => if a <= b { sorted([b] + rest) } else { false }
}

fun main() {
  // Shape matching
  println(describe([]))            // empty
  println(describe([42]))          // just 42
  println(describe([1, 2]))        // 1 and 2
  println(describe([1, 2, 3, 4]))  // starts with 1, 3 more

  // Recursive sum
  println(sum([1, 2, 3, 4, 5]))   // 15

  // Sorted check
  println(sorted([1, 2, 3, 4]))   // true
  println(sorted([1, 3, 2, 4]))   // false
}
