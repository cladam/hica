// Hica — if/else expressions
fun negate(x) => if x < 0 { 0 - x } else { x }

fun main() {
  let a = if 10 > 5 { 10 } else { 5 };
  let b = negate(0 - 3);
  b
}
