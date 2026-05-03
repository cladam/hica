fun main() {
  println("--- parse_int ---");
  println(parse_int("123"));
  println(parse_int("-45"));
  println(parse_int("abc"));
  println(parse_int("1.5"));

  println("");
  println("--- parse_float ---");
  println(parse_float("3.14"));
  println(parse_float("-0.5"));
  println(parse_float("xyz"));
  println(parse_float("2"));

  println("");
  println("--- safe usage ---");
  match parse_int("100") {
    Some(n) => println("Got number: {n}"),
    None    => println("Not a number!")
  }

  match parse_float("not-a-float") {
    Some(f) => println("Got float: {f}"),
    None    => println("Not a float!")
  }
}
