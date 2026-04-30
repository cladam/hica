fun abs(n) => if n < 0 { -n } else { n }

fun min(a, b) => if a < b { a } else { b }

fun max(a, b) => if a > b { a } else { b }

fun clamp(v, lo, hi) => min(max(v, lo), hi)

// Greatest Common Divisor (GCD)
fun gcd(a, b) => if b == 0 { a } else { gcd(b, a % b) }
