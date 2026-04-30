// Recursion: functions that call themselves

fun factorial(n) => if n <= 1 { 1 } else { n * factorial(n - 1) }

fun sum_to(n) => if n <= 0 { 0 } else { n + sum_to(n - 1) }

fun main() {
  println(factorial(5));
  println(sum_to(10))
}
