// ============================================================
// Lesson 07: Boolean Logic
// ============================================================
//
// Booleans are true/false values — like a light switch.
//
// Comparison operators (ask a question):
//   ==   equal?          !=   not equal?
//   >    greater than?   <    less than?
//   >=   greater or eq?  <=   less or equal?
//
// Logic operators (combine questions):
//   &&   AND — both must be true
//   ||   OR  — at least one must be true
//
// Think of && as a bouncer: "Are you old enough AND do you
// have a ticket?" Both must be true to get in!
//
// ============================================================

fun classify(n) =>
  if n > 0 && n < 100 { "in range" }
  else { "out of range" }

fun main() {
  let result = classify(42);
  println(result)
}

// ============================================================
// 🎯 Challenge: Write a function `is_teen(age)` that returns
//    "teenager" if age is between 13 and 19 (inclusive), and
//    "not a teenager" otherwise.
//    Hint: age >= 13 && age <= 19
// ============================================================
