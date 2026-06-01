// Prime Numbers
//
// Checks whether numbers are prime and prints primes in a range.
// Uses trial division up to the integer square root for efficiency.
//
// Showcases: recursion, isqrt from math prelude.
//
// Usage: hica run programs/primes.hc

fun has_divisor(n: int, d: int) : bool =>
  if d > isqrt(n) { false }
  else if n % d == 0 { true }
  else { has_divisor(n, d + 1) }

fun is_prime(n: int) : bool =>
  if n < 2 { false }
  else if n == 2 { true }
  else if n % 2 == 0 { false }
  else { has_divisor(n, 3) == false }

fun primes_in_range(lo: int, hi: int) : list<int> =>
  if lo > hi { [] }
  else if is_prime(lo) { [lo] + primes_in_range(lo + 1, hi) }
  else { primes_in_range(lo + 1, hi) }

fun main() {
  let line = input("Find primes up to: ")
  let limit = parse_int(trim(line))
  match limit {
    None => println("Please enter a valid number."),
    Some(v) =>
      if v < 2 { println("No primes below 2.") }
      else {
        let ps = primes_in_range(2, v)
        let count = length(ps)
        println("Found {count} primes up to {v}:")
        println(join(map(ps, (x) => show(x)), ", "))
      }
  }
}

test "1 is not prime" {
  assert_eq(is_prime(1), false)
}

test "2 is prime" {
  assert_eq(is_prime(2), true)
}

test "3 is prime" {
  assert_eq(is_prime(3), true)
}

test "4 is not prime" {
  assert_eq(is_prime(4), false)
}

test "9 is not prime" {
  assert_eq(is_prime(9), false)
}

test "17 is prime" {
  assert_eq(is_prime(17), true)
}

test "97 is prime" {
  assert_eq(is_prime(97), true)
}

test "100 is not prime" {
  assert_eq(is_prime(100), false)
}

test "primes up to 20" {
  assert_eq(primes_in_range(2, 20), [2, 3, 5, 7, 11, 13, 17, 19])
}
