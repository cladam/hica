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

fun count_words(text: string) : int => text.words().length()

fun main() {
  let args = get_args()
  if length(args) != 1 {
    println("usage: wordcount <file>")
  } else {
    let text = read_file(args[0]) |> unwrap
    println(count_words(text))
  }
}

test "counts words in a sentence" {
  assert_eq(count_words("hello world"), 2)
}

test "empty string has zero words" {
  assert_eq(count_words(""), 0)
}

test "extra whitespace is ignored" {
  assert_eq(count_words("  one   two  three  "), 3)
}
