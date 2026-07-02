// Hica — functional programming scratch tests
import "std/list"
fun apply_int(f, x: int) => f(x)

fun main() {
  // First-class functions
  let double = (x) => x * 2
  let greet  = (name) => "Hello, " + name
  println(apply_int(double, 5))  // 10
  println(greet("cladam"))       // Hello, cladam

  // Pipe + filter + map + fold
  let result = [1..=10]
    |> filter((x) => x % 2 == 0)
    |> map((x) => x * x)
    |> fold(0, (acc, x) => acc + x)
  println(result)   // 220
}
