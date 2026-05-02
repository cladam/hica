// ============================================================
// Lesson 19: Result - Success or Failure
// ============================================================
//
// `result` represents an operation that can succeed or fail:
//
//   Ok(value)  - success, with the computed value
//   Err(error) - failure, with an error message
//
// Like `maybe`, but the failure case carries information
// about what went wrong.
//
// ============================================================

// Safe division — no more crashes!
fun safe_divide(a, b) =>
  if b == 0 { Err("division by zero") }
  else { Ok(a / b) }

// A grading function that rejects bad scores
fun grade(score) =>
  if score < 0 { Err("score cannot be negative") }
  else if score > 100 { Err("score cannot exceed 100") }
  else if score >= 90 { Ok("A") }
  else if score >= 80 { Ok("B") }
  else if score >= 70 { Ok("C") }
  else { Ok("F") }

fun main() {
  // Ok case
  match safe_divide(10, 3) {
    Ok(n)  => println("10 / 3 = {n}"),
    Err(e) => println("error: {e}")
  };

  // Err case
  match safe_divide(10, 0) {
    Ok(n)  => println("10 / 0 = {n}"),
    Err(e) => println("error: {e}")
  };

  // Grading
  match grade(85) {
    Ok(g)  => println("grade: {g}"),
    Err(e) => println("invalid: {e}")
  };

  match grade(-5) {
    Ok(g)  => println("grade: {g}"),
    Err(e) => println("invalid: {e}")
  }
}

// ============================================================
// Challenge: Write a function `parse_bool(s)` that takes
// a string and returns Ok(true) for "true", Ok(false)
// for "false", and Err("not a boolean") for anything else.
// ============================================================
