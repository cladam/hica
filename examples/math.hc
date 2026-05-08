// Hica — chained function calls
fun double(n) => n * 2

fun square(n) => n * n

fun main() {
  let a = double(3)
  let b = square(a)
  b
}

test "this will fail" {
  assert_eq(double(3), 5)
}

test "test if 12 is double of 6" {
  assert_eq(double(6), 12)
}