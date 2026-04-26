// Hica — nested let bindings
fun triple(n) => n * 3

fun main() {
  let a = triple(4);
  let b = triple(a);
  b
}
