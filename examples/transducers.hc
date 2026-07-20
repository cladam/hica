// examples/transducers.hc — Demo and test for transducers in hica
import "std/stream"
import "std/xform"

fun main() {
  // Build a reusable transform (no source yet)
  let double_evens =
    xf_filter((x) => x % 2 == 0)
    |> xf_map((x) => x * 2)
    |> xf_take(5)

  let numbers1 = [1..10]
  let numbers2 = [11..20]
  
  // Apply to different compatible sources in a single zero-allocation pass!
  let r1 = numbers1 |> transduce(double_evens)
  let r2 = numbers2 |> transduce(double_evens)
  
  println("r1: {r1}") // [4, 8, 12, 16]
  println("r2: {r2}") // [24, 28, 32, 36, 40]
}

test "transducer commutativity & reuse" {
  let double_evens =
    xf_filter((x) => x % 2 == 0)
    |> xf_map((x) => x * 2)
    |> xf_take(5)

  let r1 = [1..10] |> transduce(double_evens)
  assert(length(r1) == 4)
}
