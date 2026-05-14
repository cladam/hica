// ============================================================
// Lesson 38: Math & Float Extras
// ============================================================
//
// The prelude provides extra math functions:
//
//   lcm(a, b)       - least common multiple
//   pow(base, exp)   - integer exponentiation
//   sign(n)          - returns -1, 0, or 1
//
// Float math:
//
//   sqrt(x)          - square root (float -> float)
//   floor(x)         - round down (float -> int)
//   ceil(x)          - round up (float -> int)
//   round(x)         - round to nearest (float -> int)
//   to_float(n)      - convert int to float
//
// Char / string conversions:
//
//   chars(s)         - string to list of chars
//   from_chars(cs)   - list of chars to string
//
// ============================================================

fun main() {
  // --- Integer math ---

  // lcm — least common multiple
  println(lcm(12, 18))        // 36
  println(lcm(7, 5))          // 35

  // pow — exponentiation
  println(pow(2, 10))         // 1024
  println(pow(3, 4))          // 81

  // sign — which side of zero?
  println(sign(42))           // 1
  println(sign(0))            // 0
  println(sign(-7))           // -1

  // --- Float math ---

  // sqrt — square root
  println(sqrt(25.0))         // 5
  println(sqrt(2.0))          // 1.4142135623730951

  // floor, ceil, round — float to int
  println(floor(3.7))         // 3
  println(ceil(3.2))          // 4
  println(round(3.5))         // 4
  println(round(3.4))         // 3

  // to_float — int to float
  println(to_float(42))       // 42

  // Combining them: integer square root
  let n = 50
  let root = floor(sqrt(to_float(n)))
  println(root)               // 7

  // --- Char / string conversions ---

  // chars — break a string into characters
  let cs = chars("hello")
  println(cs)                 // ['h', 'e', 'l', 'l', 'o']

  // from_chars — put characters back together
  println(from_chars(cs))     // "hello"

  // Combine with list functions to transform strings
  let upper_chars = filter(chars("Hello, World!"), (c) => c != ' ')
  println(from_chars(upper_chars))  // "Hello,World!"
}
