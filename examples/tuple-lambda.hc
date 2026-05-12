// Test: tuple destructuring in lambda parameters
fun main() {
  let pairs = [(1, "one"), (2, "two"), (3, "three")]

  // Tuple destructuring in lambda: ((k, v)) => ...
  let keys = pairs.map(((k, v)) => k)
  println(keys)

  let values = pairs.map(((k, v)) => v)
  println(values)

  // Also test with filter
  let big = pairs.filter(((n, s)) => n > 1)
  println(big)
}
