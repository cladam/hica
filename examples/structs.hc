struct Point { x: int, y: int }

fun distance_sq(p: Point) : int => p.x * p.x + p.y * p.y

fun main() {
  let p = Point { x: 3, y: 4 }
  println("x = {p.x}")
  println("y = {p.y}")
  println("distance² = {distance_sq(p)}")
  println(p)
}
