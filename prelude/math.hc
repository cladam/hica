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
fun gcd(a, b) => if b == 0 { a } else { gcd(b, a % b) }

// Least Common Multiple (LCM)
fun lcm(a, b) => if a == 0 || b == 0 { 0 } else { abs(a * b) / gcd(a, b) }

// Integer exponentiation
fun pow(base, exp) => if exp <= 0 { 1 } else { base * pow(base, exp - 1) }

// Sign function: returns -1, 0, or 1
fun sign(n) => if n > 0 { 1 } else if n < 0 { -1 } else { 0 }
