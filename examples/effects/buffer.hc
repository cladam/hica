// hica — M5.5 stateful handler with a match-shaped op body
//
// A stateful handler that manages a bounded list buffer. 
// Expected output:
//   count = 2
//
// Run:
//   hica run examples/effects/buffer.hc

effect Buffer {
  fun push(x: int)
  fun pop() : maybe<int>
  fun count() : int
}

fun main() {
  let n = handle Buffer {
    push(x) => {
      items = items + [x]
      size = size + 1
    },
    pop() => match items {
      [] => None,
      [x, ..rest] => {
        items = rest
        size = size - 1
        Some(x)
      }
    },
    count() => size
  } with var items = [], var size = 0 in {
    push(1)
    push(2)
    push(3)
    let _ = pop()
    count()
  }
  println("count = {show(n)}")
}
