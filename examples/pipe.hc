// Hica — pipe operator
// a |> f desugars to f(a)
fun double(n) => n * 2

fun square(n) => n * n

fun main() {
  // Chain transformations with |>
  3 |> double |> square
}
