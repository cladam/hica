// Hica — boolean logic and comparisons
fun classify(n) =>
  if n > 0 && n < 100 { "in range" }
  else { "out of range" }

fun main() {
  let result = classify(42)
  result
}
