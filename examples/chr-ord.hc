// chr(code) — construct a char from a Unicode code point
// ord(c)    — get the code point of a char
// char_to_string(c) — convert a single char to a string

fun main() {
  // chr: int → char
  let a = chr(65)
  println(a)             // A

  // ord: char → int
  let code = ord('A')
  println(code)          // 65

  // Round-trip
  let c = chr(72)
  println(ord(c))        // 72

  // Build a string from code points using chr + from_chars
  let hi = from_chars([chr(72), chr(105)])
  println(hi)            // Hi

  // char_to_string: single char → string
  let s = char_to_string(chr(66))
  println(s)             // B
}
