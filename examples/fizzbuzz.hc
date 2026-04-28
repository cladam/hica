// Hica — fizzbuzz
fun fizzbuzz(n) =>
  if n == 15 { "fizzbuzz" }
  else if n == 3 { "fizz" }
  else if n == 5 { "buzz" }
  else { "other" }

fun main() {
  let result = fizzbuzz(15);
  result
}
