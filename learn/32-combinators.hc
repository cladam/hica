// ============================================================
// Lesson 32: Combinators — Chaining Maybe and Result
// ============================================================
//
// Pattern matching on Maybe and Result is powerful, but
// chaining operations with `match` gets deeply nested.
//
// Combinators let you transform and chain values without
// unwrapping them manually:
//
//   map_maybe(m, fn)       — transform the value inside a Maybe
//   and_then(m, fn)        — chain Maybe-returning functions
//   unwrap_maybe(m)        — extract value or throw on None
//   unwrap_maybe_or(m, d)  — extract value or use a default
//   is_some(m) / is_none(m)
//
//   map_result(r, fn)      — transform the Ok value
//   map_err(r, fn)         — transform the Err value
//   and_then_result(r, fn) — chain Result-returning functions
//   is_ok(r) / is_err(r)
//
// All combinators are pipe-friendly: the value comes first.
//
// ============================================================

fun parse_positive(s) =>
  match parse_int(s) {
    Some(n) => if n > 0 { Some(n) } else { None },
    None    => None
  }

fun safe_divide(a, b) =>
  if b == 0 { Err("division by zero") }
  else { Ok(a / b) }

fun main() {
  // --- Maybe combinators ---

  // map_maybe: transform the inner value
  let doubled = Some(5) |> map_maybe((x) => x * 2)
  println(doubled)               // Some(10)

  // map_maybe on None does nothing
  let nothing = None |> map_maybe((x) => x * 2)
  println(nothing)               // None

  // and_then: chain functions that return Maybe
  let result = Some("42") |> and_then((s) => parse_int(s))
  println(result)                // Some(42)

  let bad = Some("abc") |> and_then((s) => parse_int(s))
  println(bad)                   // None

  // unwrap_maybe / unwrap_maybe_or
  println(unwrap_maybe(Some(99)))        // 99
  println(unwrap_maybe_or(None, 0))      // 0

  // is_some / is_none
  println(is_some(Some(1)))      // true
  println(is_none(None))         // true

  // --- Result combinators ---

  // map_result: transform the Ok value
  let ten = safe_divide(10, 2) |> map_result((x) => x * 2)
  println(ten)                   // Ok(10)

  // map_result on Err passes through
  let err = safe_divide(1, 0) |> map_result((x) => x * 2)
  println(err)                   // Err("division by zero")

  // map_err: transform the error
  let wrapped = safe_divide(1, 0) |> map_err((e) => "wrapped: " + e)
  println(wrapped)               // Err("wrapped: division by zero")

  // and_then_result: chain fallible operations
  let chained = safe_divide(10, 2)
    |> and_then_result((n) => safe_divide(n, 1))
  println(chained)               // Ok(5)

  let failed = safe_divide(10, 0)
    |> and_then_result((n) => safe_divide(n, 1))
  println(failed)                // Err("division by zero")

  // is_ok / is_err
  println(is_ok(safe_divide(1, 1)))      // true
  println(is_err(safe_divide(1, 0)))     // true
}

// ============================================================
// Challenge: Write a pipeline that parses a string to int,
// checks it's positive, and doubles it — all with combinators:
//
//   Some("7") |> and_then(...) |> map_maybe(...)
//
// ============================================================
