// The ? operator — early return on None
//
// Instead of nested match expressions, use ? to unwrap
// a maybe value, returning early with None if it fails.

// --- Parse two numbers and add them ---
fun add_strings(a: string, b: string) : maybe<int> {
  let x = parse_int(a)?
  let y = parse_int(b)?
  Some(x + y)
}

// --- Safe list lookup ---
fun first_positive(xs: list<int>) : maybe<int> {
  let x = find(xs, (n) => n > 0)?
  Some(x)
}

fun main() {
  // Maybe ? — success case
  println(add_strings("3", "4"))    // Some(7)

  // Maybe ? — early return on parse failure
  println(add_strings("3", "abc"))  // None

  // Maybe ? — success case
  println(first_positive([5, 2]))   // Some(5)

  // Maybe ? — None propagation
  println(first_positive([-1, -2])) // None
}
