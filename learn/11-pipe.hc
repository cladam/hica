// ============================================================
// Lesson 11: The Pipe Operator (|>)
// ============================================================
//
// The pipe operator passes a value as the first argument
// to the next function, enabling left-to-right reading:
//
// Instead of nested calls:
//   square(double(3))            // read inside-out
//
// You can pipe values through a chain:
//   3 |> double |> square        // read left-to-right
//
// The transformation:
//   a |> f       becomes  f(a)
//   a |> f |> g  becomes  g(f(a))
//
// ============================================================

fun double(n) => n * 2

fun square(n) => n * n

fun add_one(n) => n + 1

fun main() {
  // Without pipe - nested, inside-out
  let a = square(double(3))
  println(a)

  // With pipe - left-to-right
  let b = 3 |> double |> square
  println(b)

  // Chain three functions
  let c = 4 |> add_one |> double |> square
  println(c)
}

// ============================================================
// Challenge: Write a function `half(n)` that divides by 2.
// Use the pipe to compute: 10 |> double |> square |> half
// Work it out step by step.
// ============================================================
