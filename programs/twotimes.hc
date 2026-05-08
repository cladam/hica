// Exercise: twotimes
// Adapted from USI Systems Programming (Carzaniga, 2017)
//
// Check if a string consists of two identical halves concatenated.
// "mammamiamammamia" → true  (mammamia + mammamia)
// "abracadabra"      → false
//
// Usage: hica run exercises/twotimes.hc -- <file>
//
// In C this requires strlen, manual pointer arithmetic, and strncmp.
// In hica it's slicing + comparison.

fun twotimes(s: string) : bool {
  let n = str_length(s)
  if n % 2 != 0 { false }
  else {
    let half = n / 2
    s[:half] == s[half:]
  }
}

fun main() {
  let args = get_args()
  if length(args) == 0 {
    let raw = input("Enter a string: ")
    let s = trim(raw)
    if twotimes(s) { println("YES") }
    else { println("NO") }
  } else {
    let raw = read_file(args[0]) |> unwrap
    let s = trim(raw)
    if twotimes(s) { println("YES") }
    else { println("NO") }
  }
}

test "even-length repeated string" {
  assert_true(twotimes("abcabc"))
}

test "single repeated char" {
  assert_true(twotimes("aa"))
}

test "odd-length string is never twotimes" {
  assert_false(twotimes("abc"))
}

test "different halves" {
  assert_false(twotimes("abcdef"))
}

test "empty string is twotimes" {
  assert_true(twotimes(""))
}
