// Hica — pipe operator
// a |> f desugars to f(a)

// double is in the prelude already
//fun double(n) => n * 2

// square is in the prelude already
//fun square(n) => n * n

fun main() {
  // Chain transformations with |>
  3 |> double |> square
}
