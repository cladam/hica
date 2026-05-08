// Exercise: wordcount
// Adapted from USI Systems Programming (Carzaniga, 2017)
//
// Count the words in a text file. A word is a sequence of non-whitespace
// characters separated by whitespace.
//
// Usage: hica run exercises/wordcount.hc -- <file>
//
// In C this requires a state machine tracking in-word vs whitespace.
// In hica it's a one-liner pipeline.

fun main() {
  let args = get_args()
  if length(args) != 1 {
    println("usage: wordcount <file>")
  } else {
    let text = read_file(args[0]) |> unwrap
    let count = text.words().length()
    println(count)
  }
}
