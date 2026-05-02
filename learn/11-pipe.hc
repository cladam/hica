// ============================================================
// Lesson 11: The Pipe Operator — Connecting Machines
// ============================================================
//
// Remember how functions are like little machines?
// The pipe operator |> is the conveyor belt between them!
//
// Instead of nesting calls inside each other:
//   square(double(3))            // read inside-out 😵
//
// You can pipe values left to right:
//   3 |> double |> square        // read like a story 😎
//
// The rule is simple:
//   a |> f       becomes  f(a)
//   a |> f |> g  becomes  g(f(a))
//
// ============================================================

fun double(n) => n * 2

fun square(n) => n * n

fun add_one(n) => n + 1

fun main() {
  // Without pipe — inside-out reading
  let a = square(double(3));
  println(a);

  // With pipe — left-to-right reading
  let b = 3 |> double |> square;
  println(b);

  // Chain three machines together
  let c = 4 |> add_one |> double |> square;
  println(c)
}

// ============================================================
// 🎯 Challenge: Write a function `half(n)` that divides by 2.
//    Use the pipe to compute: 10 |> double |> square |> half
//    What do you get? Work it out step by step!
// ============================================================
