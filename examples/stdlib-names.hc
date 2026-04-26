// Hica — names that clash with Koka stdlib (abs, max, min)
// These would fail without name marshalling (hc_ prefix)
fun abs(x) => if x < 0 { 0 - x } else { x }

fun main() {
  let result = abs(0 - 42);
  result
}
