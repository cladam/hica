// Exercise: flipstream
// Adapted from USI Systems Programming (Carzaniga, 2017)
//
// Read lines from a file and output them in reverse order.
//
// Usage: hica run exercises/flipstream.hc -- <file>
//
// In C this requires a linked list or dynamically resized array,
// malloc/free, and careful memory management (~50 lines).
// In hica it's read + reverse + print.

fun main() {
  let args = get_args()
  if length(args) != 1 {
    println("usage: flipstream <file>")
  } else {
    let reversed = read_lines(args[0]).reverse()
    reversed.foreach((line) => println(line))
  }
}
