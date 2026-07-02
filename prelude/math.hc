// hica – math prelude
//
// This source file is part of the hica open source project
// Copyright (C) 2026 Claes Adamsson <claes.adamsson@gmail.com>
//
// See https://github.com/cladam/hica/blob/main/LICENSE for license information

fun abs(n) => if n < 0 { -n } else { n }

fun min(a, b) => if a < b { a } else { b }

fun max(a, b) => if a > b { a } else { b }

fun clamp(v, lo, hi) => min(max(v, lo), hi)

// Greatest Common Divisor (GCD)
fun gcd(a: int, b: int) : int => if b == 0 { a } else { gcd(b, a % b) }

// Least Common Multiple (LCM)
fun lcm(a: int, b: int) : int => if a == 0 || b == 0 { 0 } else { abs(a * b) / gcd(a, b) }

// Integer exponentiation
fun pow(base: int, exp: int) : int => if exp <= 0 { 1 } else { base * pow(base, exp - 1) }

// Sign function: returns -1, 0, or 1
fun sign(n: int) : int => if n > 0 { 1 } else if n < 0 { -1 } else { 0 }

// Range [lo, hi) — lo inclusive, hi exclusive (like Python range)
// Used by the [lo..hi] list range literal
fun range(lo: int, hi: int) : list<int> =>
  if lo >= hi { [] } else { [lo] + range(lo + 1, hi) }

// Range [lo, hi] — both ends inclusive
// Used by the [lo..=hi] list range literal
fun range_inc(lo: int, hi: int) : list<int> =>
  if lo > hi { [] } else { [lo] + range_inc(lo + 1, hi) }

// Integer square root (floor) — Newton's method, no float arithmetic needed
fun isqrt(n: int) : int {
  if n <= 0 { 0 } else {
    let x0 = n
    let x1 = (x0 + 1) / 2
    let result = isqrt_loop(n, x0, x1)
    result
  }
}

fun isqrt_loop(n: int, x0: int, x1: int) : int {
  if x1 >= x0 {
    x0
  } else {
    let x2 = (x1 + n / x1) / 2
    isqrt_loop(n, x1, x2)
  }
}
