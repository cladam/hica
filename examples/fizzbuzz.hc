// Hica — fizzbuzz
fun fizzbuzz(n) =>
  if n % 15 == 0 { "fizzbuzz" }
  else if n % 3 == 0 { "fizz" }
  else if n % 5 == 0 { "buzz" }
  else { show(n) }

fun main() {
  println(fizzbuzz(1))
  println(fizzbuzz(3))
  println(fizzbuzz(5))
  println(fizzbuzz(15))
  println(fizzbuzz(7))
}
