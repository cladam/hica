// Hica — Recursive enum types (algebraic data types)

// A user-defined linked list — like OCaml's intlist
type IntList {
  Nil,
  Cons(head: int, tail: IntList)
}

fun sum(lst: IntList) : int => match lst {
  Nil        => 0,
  Cons(h, t) => h + sum(t)
}

fun len(lst: IntList) : int => match lst {
  Nil        => 0,
  Cons(_, t) => 1 + len(t)
}

fun main() {
  let xs = Cons(1, Cons(2, Cons(3, Nil)))
  println(xs)
  println("sum: {sum(xs)}")
  println("len: {len(xs)}")
}
