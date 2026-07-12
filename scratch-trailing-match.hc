type Node {
  Foo(x: int),
  Bar
}

pub fun expand(nodes: list<Node>) : list<int> {
  flat_map(nodes, (node) => match node {
    Foo(x) => [x],
    Bar => []
  })
}

fun main() {
  let r = expand([Foo(1), Bar, Foo(2)])
  println(show(r))
}
