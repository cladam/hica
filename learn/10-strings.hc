// ============================================================
// Lesson 10: Strings - Concatenation & Interpolation
// ============================================================
//
// Two ways to build strings from pieces:
//
// 1. Concatenation with `+`:
//      "hello" + " " + "world"
//
// 2. Interpolation with `{expr}` inside a string:
//      "hello, {name}!"
//
// Numbers and booleans are automatically converted inside {}.
//
// ============================================================

// Concatenation: join strings with +
fun shout(word) => word + "!"

// Interpolation: embed values directly in a string
fun greet(name) => "hello, {name}!"

fun main() {
  println(shout("wow"));
  println(greet("hica"));
  let apples = 5;
  println("{apples} apples")
}

// ============================================================
// Challenge: Write a function `introduce(name, age)` that
// returns "my name is ___ and I am ___ years old" using
// string interpolation.
// ============================================================
