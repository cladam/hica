// Exercise: pwords (palindrome words)
// Adapted from USI Systems Programming (Carzaniga, 2017)
//
// Count the number of palindrome words in a text file.
// A word is a contiguous sequence of alphabetic characters.
//
// Usage: hica run exercises/pwords.hc -- <file>
//
// In C this requires manual character-by-character parsing,
// pointer arithmetic, and in-place reversal for comparison.
// In hica it's split + filter with a palindrome check.

fun is_palindrome(s: string) : bool {
  let chars = split(s, "")
  chars == reverse(chars)
}

fun main() {
  let args = get_args()
  if length(args) != 1 {
    println("usage: pwords <file>")
  } else {
    let text = read_file(args[0]) |> unwrap
    let ws = text.words()
    let palindromes = ws.filter((w) => is_palindrome(w))
    println("total words: {ws.length()}")
    println("palindromes: {palindromes.length()}")
    if palindromes.length() > 0 {
      palindromes.foreach((p) => println("  {p}"))
    }
  }
}

test "single char is palindrome" {
  assert_true(is_palindrome("a"))
}

test "aba is palindrome" {
  assert_true(is_palindrome("aba"))
}

test "racecar is palindrome" {
  assert_true(is_palindrome("racecar"))
}

test "hello is not palindrome" {
  assert_false(is_palindrome("hello"))
}
