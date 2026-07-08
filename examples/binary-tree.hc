// hica — Binary tree (recursive enum)

type Tree {
  Leaf,
  Node(value: int, left: Tree, right: Tree)
}

fun size(t: Tree) : int => match t {
  Leaf           => 0,
  Node(_, l, r)  => 1 + size(l) + size(r)
}

fun depth(t: Tree) : int => match t {
  Leaf           => 0,
  Node(_, l, r)  => 1 + max(depth(l), depth(r))
}

fun tree_sum(t: Tree) : int => match t {
  Leaf           => 0,
  Node(v, l, r)  => v + tree_sum(l) + tree_sum(r)
}

fun has_value(t: Tree, x: int) : bool => match t {
  Leaf           => false,
  Node(v, l, r)  => v == x || has_value(l, x) || has_value(r, x)
}

fun main() {
  //       4
  //      / \
  //     2   6
  //    / \
  //   1   3
  let tree = Node(4,
    Node(2, Node(1, Leaf, Leaf), Node(3, Leaf, Leaf)),
    Node(6, Leaf, Leaf)
  )

  println(tree)
  println("size: {size(tree)}")
  println("depth: {depth(tree)}")
  println("sum: {tree_sum(tree)}")
  println("contains 3: {has_value(tree, 3)}")
  println("contains 7: {has_value(tree, 7)}")
}
