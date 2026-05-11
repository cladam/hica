// ============================================================
// Lesson 36: The ? Operator — Early Return on Failure
// ============================================================
//
// When working with maybe values, you often need to unwrap
// them and handle the None case. The ? operator does this
// automatically: it unwraps the value if present, or returns
// early with None if absent.
//
//   let x = some_maybe_expr?   // unwraps or returns None
//
// Without ?, you'd need nested match expressions:
//
//   let x = match some_maybe_expr {
//     Some(v) => v,
//     None => return None
//   }
//
// The ? operator keeps your code flat and readable.
// ============================================================

// Parse two strings as integers and add them.
// If either parse fails, the whole function returns None.
fun add_strings(a: string, b: string) : maybe<int> {
  let x = parse_int(a)?
  let y = parse_int(b)?
  Some(x + y)
}

// Find the first positive number in a list.
// If none is found, the function returns None.
fun first_positive(xs: list<int>) : maybe<int> {
  let x = find(xs, (n) => n > 0)?
  Some(x)
}

fun main() {
  println(add_strings("3", "4"))
  println(add_strings("3", "abc"))
  println(first_positive([5, -1, 2]))
  println(first_positive([-1, -2]))
}

// Expected output:
// Some(7)
// None
// Some(5)
// None
