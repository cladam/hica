// Hica — Maybe and Result combinators
//
// Combinators let you chain operations on Maybe and Result
// without nesting match expressions.

fun parse_positive(s) =>
  match parse_int(s) {
    Some(n) => if n > 0 { Some(n) } else { None },
    None    => None
  }

fun safe_divide(a, b) =>
  if b == 0 { Err("division by zero") }
  else { Ok(a / b) }

fun validate(n) =>
  if n > 100 { Err("too large") }
  else { Ok(n) }

fun main() {
  // Maybe: map_maybe transforms the value inside
  let x = Some(21) |> map_maybe((n) => n * 2)
  println(x)                          // Some(42)

  // Maybe: and_then chains Maybe-returning functions
  let y = Some("42")
    |> and_then((s) => parse_int(s))
    |> map_maybe((n) => n + 1)
  println(y)                          // Some(43)

  // Maybe: short-circuit on None
  let z = Some("nope")
    |> and_then((s) => parse_int(s))
    |> map_maybe((n) => n + 1)
  println(z)                          // None

  // Unwrap helpers
  println(unwrap_maybe_or(Some(5), 0))  // 5
  println(unwrap_maybe_or(None, 0))     // 0

  // Predicates
  println(is_some(Some(1)))             // true
  println(is_none(None))                // true

  // Result: map_result transforms Ok
  let r1 = safe_divide(100, 4) |> map_result((n) => n * 10)
  println(r1)                           // Ok(250)

  // Result: and_then_result chains fallible steps
  let r2 = safe_divide(100, 4)
    |> and_then_result((n) => validate(n))
  println(r2)                           // Ok(25)

  // Error propagation
  let r3 = safe_divide(100, 0)
    |> and_then_result((n) => validate(n))
  println(r3)                           // Err("division by zero")

  // map_err transforms the error message
  let r4 = safe_divide(1, 0) |> map_err((e) => "ERROR: " + e)
  println(r4)                           // Err("ERROR: division by zero")
}
