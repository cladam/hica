// Hica — match expressions
fun describe(x) => match x {
  0 => "zero",
  1 => "one",
  _ => "many"
}

// Match on strings too!
fun respond(msg) => match msg {
  "hello" => "hi there!",
  "bye"   => "see you!",
  _       => "huh?"
}

// Match on tuples
fun locate(point) => match point {
  (0, 0) => "origin",
  (x, 0) => "x-axis at {x}",
  (0, y) => "y-axis at {y}",
  (_, _) => "elsewhere"
}

// Or-patterns: match several values in one arm
fun day_type(day) => match day {
  "Saturday" | "Sunday" => "weekend",
  _                     => "weekday"
}

fun classify(n) => match n {
  1 | 2 | 3 => "low",
  4 | 5 | 6 => "mid",
  _         => "high"
}

fun main() {
  println(describe(1))
  println(respond("hello"))
  println(locate((0, 0)))
  println(locate((3, 0)))
  println(locate((0, 7)))
  println(locate((1, 2)))
  println(day_type("Saturday"))
  println(day_type("Monday"))
  println(classify(2))
  println(classify(5))
  println(classify(9))
}
