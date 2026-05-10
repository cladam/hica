// Recursion: functions that call themselves, or each other

fun factorial(n) => if n <= 1 { 1 } else { n * factorial(n - 1) }

fun sum_to(n) => if n <= 0 { 0 } else { n + sum_to(n - 1) }

// Mutual recursion: two functions that call each other
fun check_even(n) => if n == 0 { true } else { check_odd(n - 1) }

fun check_odd(n) => if n == 0 { false } else { check_even(n - 1) }

fun main() {
  println(factorial(5))
  println(sum_to(10))
  println(check_even(10))
  println(check_odd(7))
}
