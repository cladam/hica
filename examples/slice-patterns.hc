// List slice patterns in match
fun describe(xs: list<int>) : string => match xs {
  []           => "empty",
  [x]          => "just {x}",
  [x, y]       => "{x} and {y}",
  [x, ..rest]  => "starts with {x}, {length(rest)} more"
}

fun sum(xs: list<int>) : int => match xs {
  []          => 0,
  [x, ..rest] => x + sum(rest)
}

fun main() {
  println(describe([]))
  println(describe([42]))
  println(describe([1, 2]))
  println(describe([1, 2, 3, 4]))

  println(sum([1, 2, 3, 4, 5]))
}
