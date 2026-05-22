// Test: prelude extensions — lists, math, float math, char/string conversions
import "std/list"

fun main() {
  // --- List functions ---
  let xs = [3, 1, 4, 1, 5, 9, 2, 6]

  // head / tail / last
  println(head(xs))               // Some(3)
  println(head(tail(xs)))         // Some(1)
  println(tail(xs))               // [1, 4, 1, 5, 9, 2, 6]
  println(last(xs))               // Some(6)

  // sort_by
  println(sort_by([3, 1, 4, 1, 5], (a, b) => a <= b))  // [1, 1, 3, 4, 5]
  let words = ["banana", "apple", "cherry"]
  println(sort_by(words, (a, b) => a <= b))  // ["apple", "banana", "cherry"]
  let by_len = sort_by(words, (a, b) => str_length(a) < str_length(b))
  println(by_len)                 // ["apple", "banana", "cherry"]

  // flat_map
  let nested = flat_map([1, 2, 3], (x) => [x, x * 10])
  println(nested)                 // [1, 10, 2, 20, 3, 30]

  // intersperse
  println(intersperse([1, 2, 3], 0))  // [1, 0, 2, 0, 3]

  // sum / product
  println(sum([1, 2, 3, 4, 5]))      // 15
  println(product([1, 2, 3, 4]))     // 24

  // scan
  println(scan([1, 2, 3, 4], 0, (a, b) => a + b))  // [0, 1, 3, 6, 10]

  // zip_with
  let added = zip_with([1, 2, 3], [10, 20, 30], (a, b) => a + b)
  println(added)                 // [11, 22, 33]

  // unique
  println(unique([1, 2, 3, 2, 1, 4]))  // [1, 2, 3, 4]

  // chunks
  println(chunks([1, 2, 3, 4, 5], 2))  // [[1, 2], [3, 4], [5]]

  // --- Math functions ---
  println(lcm(12, 18))           // 36
  println(pow(2, 10))            // 1024
  println(sign(-42))             // -1
  println(sign(0))               // 0
  println(sign(7))               // 1

  // --- Float math ---
  println(sqrt(16.0))            // 4.0
  println(floor(3.7))            // 3
  println(ceil(3.2))             // 4
  println(round(3.5))            // 4
  println(to_float(42))          // 42.0

  // --- Char/string conversions ---
  let cs = chars("hello")
  println(cs)                    // ['h', 'e', 'l', 'l', 'o']
  println(from_chars(cs))        // "hello"
}
