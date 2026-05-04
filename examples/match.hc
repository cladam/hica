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
  (x, 0) => "x-axis at {x.show}",
  (0, y) => "y-axis at {y.show}",
  (_, _) => "elsewhere"
}

fun main() {
  println(describe(1))
  println(respond("hello"))
  println(locate((0, 0)))
  println(locate((3, 0)))
  println(locate((0, 7)))
  println(locate((1, 2)))
}
