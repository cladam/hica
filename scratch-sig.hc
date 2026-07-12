type Node {
  Foo(x: int),
  Bar
}

pub fun expand(nodes: list<Node>) : list<int> {
  [1]
}

fun main() {
  println(show(expand([Foo(1)])))
}
