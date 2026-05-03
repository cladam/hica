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

fun main() {
  println(describe(1))
  println(respond("hello"))
}
