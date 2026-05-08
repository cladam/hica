// Exercise: findstring
// Adapted from USI Systems Programming (Carzaniga, 2017)
//
// Search a file for one or more strings passed as command-line arguments.
// Prints which strings were found and which were not.
//
// Usage: hica run exercises/findstring.hc -- <file> <string1> [string2 ...]
//
// In C this requires reading a stream in chunks, handling buffer
// boundaries, and manual string matching (~80 lines).
// In hica it's read + contains for each needle.

fun main() {
  let args = get_args()
  if length(args) < 2 {
    println("usage: findstring <file> <string> [string ...]")
  } else {
    let text = read_file(args[0]) |> unwrap
    let needles = args[1:]
    let found = needles.filter((needle) => contains(text, needle))
    let missing = needles.filter((needle) => not_(contains(text, needle)))
    found.foreach((needle) => println("found: {needle}"))
    missing.foreach((needle) => println("NOT found: {needle}"))
    if length(missing) == 0 { println("all strings found") }
    else { println("some strings missing") }
  }
}
