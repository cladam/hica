// Hica — Uniform Function Call Syntax (UFCS)
// a.f(b) desugars to f(a, b)
// Enables fluent method-style chains on any function.

fun triple(x) => x * 3
fun inc(x) => x + 1
fun squared(x) => x * x

fun main() {
  // UFCS: call functions with dot-syntax
  let a = 5.triple()
  println(a)

  // Chain multiple calls
  let b = 4.triple().inc().squared()
  println(b)

  // Works with prelude/stdlib functions too
  let nums = [1, 2, 3, 4, 5]
  let result = nums.map((x) => x * 2).filter((x) => x > 4)
  println(result)

  // Strings
  let s = "  hello, hica!  "
  println(s.trim().to_upper())

  // Equivalent to pipe: 5 |> triple |> inc
  let c = 5.triple().inc()
  let d = 5 |> triple |> inc
  println(c == d)
}
