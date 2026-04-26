// Hica — match expressions
fun describe(x) => match x {
  0 => "zero",
  1 => "one",
  _ => "many"
}

fun main() {
  let label = describe(1);
  label
}
