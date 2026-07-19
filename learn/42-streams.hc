// ============================================================
// Lesson 42: Lazy Streams — Efficient Data Processing
// ============================================================
//
// When we chain list transformations, each step allocates a whole new list:
//
//   [1..20].filter(is_even).map(square).take(5)
//           |                |           |
//           v                v           v
//       Allocates        Allocates   Allocates
//       [2,4,..20]      [4,16,..400]  [4,16,36,64,100]
//
// STREAMS solve this by combining all operations into a single traversal.
// Elements flow through the pipeline one by one. No intermediate lists are built,
// and the generator stops as soon as the condition of the stream is satisfied!
//
// ── Core Concepts ────────────────────────────────────────────
//
// 1. Entry point: `stream(list)` converts a standard list to a lazy stream.
// 2. Transformations: `map`, `filter`, `take`, `zip`, etc. are lazy. They return
//    a new stream immediately without traversing or evaluating anything.
// 3. Terminators: `collect`, `fold`, or `foreach` force evaluation of the stream
//    to produce a final list, single value, or execute side effects.
//
// ── Import ────────────────────────────────────────────────────
//
//   import "std/stream"
//
// ============================================================

import "std/stream"
import "std/list"

fun main() {
  // 1. Zero-Allocation Pipelines
  // Chaining map, filter, and take. Since this is a stream, elements are
  // processed on-demand, and the final collect materialises the list in one pass.
  let result = stream([1..20])
    .filter((x) => x % 2 == 0)
    .map((x) => x * x)
    .take(5)
    .collect()

  println("Result pipeline: {result}") // [4, 16, 36, 64, 100]

  // 2. Early Termination
  // In a normal list pipeline, filtering [1..1000] would run the predicate 1000 times.
  // With a stream, the generator halts immediately once `take(3)` is satisfied!
  let elements = stream([1..1000])
    .filter((x) => x % 7 == 0)
    .take(3)
    .collect()

  println("First 3 multiples of 7: {elements}") // [7, 14, 21]

  // 3. Folding Streams directly (Aggregations)
  // We can reduce a stream to a single value using `fold`. This also avoids
  // allocating any intermediate lists.
  let sum_of_squares = stream([1..1000])
    .filter((x) => x % 2 == 0)
    .map((x) => x * x)
    .take(10)
    .fold(0, (acc, x) => acc + x)

  println("Sum of first 10 even squares: {sum_of_squares}") // 1540

  // 4. Zip and Enumerate
  // We can zip streams together or index elements lazily:
  let indexed = stream(["a", "b", "c"])
    .enumerate()
    .collect()

  println("Enumerate: {indexed}") // [(0, "a"), (1, "b"), (2, "c")]
}
