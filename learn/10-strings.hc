// ============================================================
// Lesson 10: Strings — Concatenation & Interpolation
// ============================================================
//
// Hica has two ways to build strings from pieces:
//
// 1. Concatenation with `+`:
//      "hello" + " " + "world"   →  "hello world"
//
// 2. Interpolation with `{expr}` inside a string:
//      "hello {name}!"           →  "hello world!"
//
// Interpolation is usually easier to read. Numbers and
// booleans are automatically converted to text inside `{}`.
//
// ============================================================

// Concatenation: glue strings together with +
fun shout(word) => word + "!"

// Interpolation: embed values directly inside a string
fun greet(name) => "hello, {name}!"

fun main() {
  println(shout("wow"));
  println(greet("hica"));
  // Numbers get converted automatically
  let apples = 5;
  println("{apples} apples")
}

// ============================================================
// 🎯 Challenge: Write a function `introduce(name, age)` that
//    returns "my name is ___ and I am ___ years old" using
//    string interpolation.
// ============================================================
