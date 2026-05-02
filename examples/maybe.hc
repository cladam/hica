// Hica — maybe type: Some and None

// A function that might not find what you want
fun find_positive(n) =>
  if n > 0 { Some(n) }
  else { None }

fun main() {
  // Creating a maybe value
  let a = Some(42);
  println(a);

  // Pattern matching on maybe
  match a {
    Some(n) => println("got: {n}"),
    None    => println("nothing")
  };

  // Using maybe from a function
  match find_positive(10) {
    Some(n) => println("found positive: {n}"),
    None    => println("not positive")
  };

  match find_positive(-5) {
    Some(n) => println("found positive: {n}"),
    None    => println("not positive")
  };

  // Maybe with strings
  let name = Some("Hica");
  match name {
    Some(n) => println("language: {n}"),
    None    => println("unknown")
  }
}
