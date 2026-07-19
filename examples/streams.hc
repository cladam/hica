// hica — streams
//
// Lazy, effect-aware stream processing via `std/stream`.
//
// LIST PIPELINES allocate an intermediate list after each step:
//   filter → [list] → map → [list] → take → [list]
//
// STREAMS compose transformations into a single traversal pass.
// No intermediate lists. Early termination stops the source generator.
//
//   stream(xs).filter(f).map(g).take(n).collect()
//   ─────────────────────────── single pass ──────
//
// Import with: import "std/stream"

import "std/stream"
import "std/list"

// ---------------------------------------------------------------------------
// 1. Basic pipeline
// ---------------------------------------------------------------------------

fun basic_pipeline() {
  // Eager list pipeline: three intermediate lists allocated
  let eager = [1..20]
    .filter((x) => x % 2 == 0)
    .map((x) => x * x)
    .take(5)

  // Lazy stream pipeline: no intermediate lists, single pass
  let lazy = stream([1..20])
    .filter((x) => x % 2 == 0)
    .map((x) => x * x)
    .take(5)
    .collect()

  println("eager:  {eager}")
  println("stream: {lazy}")
  // Both: [4, 16, 36, 64, 100]
}

// ---------------------------------------------------------------------------
// 2. Early termination — the key win over list pipelines
// ---------------------------------------------------------------------------

fun early_stop() {
  // With a list pipeline: all 1000 elements pass through filter.
  // With a stream: the generator stops after yielding 3 matches.
  let result = stream([1..1000])
    .filter((x) => x % 7 == 0)
    .take(3)
    .collect()

  println("first 3 multiples of 7: {result}")   // [7, 14, 21]
}

// ---------------------------------------------------------------------------
// 3. Fold without materialising
// ---------------------------------------------------------------------------

fun aggregate() {
  // Sum the first 10 even squares — no intermediate list ever built
  let total = stream([1..1000])
    .filter((x) => x % 2 == 0)
    .map((x) => x * x)
    .take(10)
    .fold(0, (acc, x) => acc + x)

  println("sum of first 10 even squares: {total}")  // 1540
}

// ---------------------------------------------------------------------------
// 4. take_while and drop_while
// ---------------------------------------------------------------------------

fun slice_demo() {
  let prefix = stream([1..10])
    .take_while((x) => x <= 5)
    .collect()

  let suffix = stream([1..10])
    .drop_while((x) => x <= 5)
    .collect()

  println("prefix: {prefix}")   // [1, 2, 3, 4, 5]
  println("suffix: {suffix}")   // [6, 7, 8, 9, 10]
}

// ---------------------------------------------------------------------------
// 5. flat_map — expand each element into a sub-stream
// ---------------------------------------------------------------------------

fun flatten_demo() {
  let words = ["hi", "hica"]

  // Each word becomes a stream of its characters; all are merged
  let all_chars = stream(words)
    .flat_map((w) => stream(chars(w)))
    .collect()

  println(all_chars)   // ['h', 'i', 'h', 'i', 'c', 'a']
}

// ---------------------------------------------------------------------------
// 6. zip — pair two streams element-by-element
// ---------------------------------------------------------------------------

fun zip_demo() {
  let names  = stream(["kalle", "olle", "lisa"])
  let scores = stream([95, 87, 92])

  let pairs = names.zip(scores).collect()
  println(pairs)   // [("kalle", 95), ("olle", 87), ("lisa", 92)]
}

// ---------------------------------------------------------------------------
// 7. enumerate — index each element
// ---------------------------------------------------------------------------

fun enumerate_demo() {
  let indexed = stream(["alpha", "beta", "gamma"])
    .enumerate()
    .collect()

  println(indexed)   // [(0, "alpha"), (1, "beta"), (2, "gamma")]
}

// ---------------------------------------------------------------------------
// 8. foreach — effectful iteration (no collect needed)
// ---------------------------------------------------------------------------

fun foreach_demo() {
  // Effect inference: this lambda has `io` because of println.
  // The stream's foreach therefore also carries `io`.
  stream([1..5])
    .map((x) => x * x)
    .foreach((x) => println("square: {show(x)}"))
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

fun main() {
  println("=== 1. basic pipeline ===")
  basic_pipeline()

  println("=== 2. early stop ===")
  early_stop()

  println("=== 3. aggregate (fold) ===")
  aggregate()

  println("=== 4. take_while / drop_while ===")
  slice_demo()

  println("=== 5. flat_map ===")
  flatten_demo()

  println("=== 6. zip ===")
  zip_demo()

  println("=== 7. enumerate ===")
  enumerate_demo()

  println("=== 8. foreach (io effect) ===")
  foreach_demo()
}
