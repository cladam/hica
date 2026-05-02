// ============================================================
// Lesson 03: Variables and Let
// ============================================================
//
// A variable is like a labelled box. You use `let` to create
// one and put a value inside.
//
//   let age = 11;          // a box called "age" holding 11
//   let name = "Alex";     // a box called "name" holding "Alex"
//
// Rules for names:
//   ✅ start with a letter or _
//   ✅ can contain letters, numbers, _
//   ❌ no spaces, no hyphens
//   ⚠️  case-sensitive: score ≠ Score
//
// THE LAST LINE RULE:
// The computer looks at the very last line of a { } block
// and says "That's the answer!" No need to write "return."
//
// ============================================================

fun main() {
  let a = 10;
  let b = 20;
  let c = a + b;
  println(c)              // Prints 30
}

// ============================================================
// 🎯 Challenge: Create variables for your age, a lucky number,
//    and compute their sum. Make the sum the last line.
// ============================================================
