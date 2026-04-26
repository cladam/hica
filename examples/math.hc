// Hica — chained function calls
fun double(n) => n * 2

fun square(n) => n * n

fun main() {
  let a = double(3);
  let b = square(a);
  b
}
