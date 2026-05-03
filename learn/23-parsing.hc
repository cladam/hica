// ============================================================
// Lesson 23: Parsing — Safe String-to-Number Conversion
// ============================================================
//
// `parse_int` and `parse_float` safely convert strings to
// numbers, returning a `maybe` instead of crashing:
//
//   parse_int("42")    → Some(42)
//   parse_int("abc")   → None
//
//   parse_float("3.14") → Some(3.14)
//   parse_float("xyz")  → None
//
// Compare with `to_int`, which returns -1 on failure:
//
//   to_int("42")  → 42
//   to_int("abc") → -1
//
// Use `parse_int`/`parse_float` when you need to know
// whether the conversion actually succeeded.
//
// ============================================================

fun main() {
  // 1. parse_int — returns maybe<int>
  println(parse_int("123"));
  println(parse_int("-45"));
  println(parse_int("abc"));

  // 2. parse_float — returns maybe<float>
  println(parse_float("3.14"));
  println(parse_float("-0.5"));
  println(parse_float("xyz"));

  // 3. Match on the result for safe handling
  match parse_int("100") {
    Some(n) => println("Got number: {n}"),
    None    => println("Not a valid integer!")
  };

  match parse_float("2.718") {
    Some(f) => println("Got float: {f}"),
    None    => println("Not a valid float!")
  };

  // 4. Handling bad input gracefully
  match parse_int("hello") {
    Some(n) => println("Parsed: {n}"),
    None    => println("Could not parse 'hello' as int")
  };

  // 5. Compare with to_int (returns -1 on failure)
  println(to_int("42"));
  println(to_int("abc"))
}

// ============================================================
// Expected output:
//   Some(123)
//   Some(-45)
//   None
//   Some(3.14)
//   Some(-0.5)
//   None
//   Got number: 100
//   Got float: 2.718
//   Could not parse 'hello' as int
//   42
//   -1
// ============================================================
