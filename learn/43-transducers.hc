// ============================================================
// Lesson 43: Pipeline Transducers — Reusable Stream Pipelines
// ============================================================
//
// In Lesson 42, we learned that Lazy Streams solve the intermediate allocation
// problem by performing all transformations in a single pass:
//
//   stream([1..20]).filter(is_even).map(square).take(5).collect()
//
// However, Streams must be bound to a source immediately. You cannot build
// a transformation pipeline on its own, save it as a variable, and reuse it.
//
// TRANSDUCERS (via `std/xform`) solve this. They decouple the transformation logic
// from the underlying data structure, allowing you to define reusable,
// source-independent query pipelines!
//
// ── Core Concepts ────────────────────────────────────────────
//
// 1. Transducer constructors start with `xf_`:
//    - `xf_filter(pred)` / `xf_filter_with(xform, pred)`
//    - `xf_map_start(f)` / `xf_map(xform, f)`
//    - `xf_take_start(n)` / `xf_take(xform, n)`
//    - `xf_take_while_start(pred)` / `xf_take_while(xform, pred)`
//    - `xf_drop_while_start(pred)` / `xf_drop_while(xform, pred)`
//    - `xf_flat_map_start(f)` / `xf_flat_map(xform, f)`
//
// 2. Composition: Since hica desugars `a |> f(b)` to `f(a, b)`, transducers
//    chain perfectly left-to-right into a single composed transducer:
//
//    let clean_and_double =
//      xf_filter((x) => x % 2 == 0)
//      |> xf_map((x) => x * 2)
//      |> xf_take(5)
//
// 3. Application: Use `transduce(list, xform)` to apply the transducer to any
//    compatible source. It converts the list to a stream, passes it through the
//    composed transducer, and collects it in a single, zero-allocation pass!
//
// ── Import ────────────────────────────────────────────────────
//
//   import "std/stream"
//   import "std/xform"
//
// ============================================================

import "std/stream"
import "std/xform"

fun main() {
  // 1. Build a reusable transducer (no data source yet)
  let clean_and_double =
    xf_filter((x) => x % 2 == 0)
    |> xf_map((x) => x * 2)
    |> xf_take(5)

  let numbers1 = [1..10]
  let numbers2 = [11..20]

  // 2. Apply the transducer to different sources!
  let r1 = numbers1 |> transduce(clean_and_double)
  let r2 = numbers2 |> transduce(clean_and_double)

  println("Source 1: {numbers1}")
  println("Result 1: {r1}") // [4, 8, 12, 16]

  println("Source 2: {numbers2}")
  println("Result 2: {r2}") // [24, 28, 32, 36, 40]

  // 3. Building starting with map
  let double_only =
    xf_map_start((x) => x * 2)
    |> xf_filter_with((x) => x > 10)

  let r3 = [1..10] |> transduce(double_only)
  println("Result 3: {r3}") // [12, 14, 16, 18, 20]
}

test "transducer pipeline reuse" {
  let double_evens =
    xf_filter((x) => x % 2 == 0)
    |> xf_map((x) => x * 2)
    |> xf_take(3)

  let r = [1..10] |> transduce(double_evens)
  assert(length(r) == 3)
}
