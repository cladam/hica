struct Point { x: int, y: int }

fun distance_sq(p: Point) : int => p.x * p.x + p.y * p.y

fun main() {
  let p = Point { x: 3, y: 4 }
  println("x = {p.x}")
  println("y = {p.y}")
  println("distance² = {distance_sq(p)}")
  println(p)

  // Struct update — create a new struct from an existing one
  let q = Point { ...p, x: 10 }
  println(q)                        // Point(x: 10, y: 4)

  // Update multiple fields
  let r = Point { ...p, x: 0, y: 0 }
  println(r)                        // Point(x: 0, y: 0)

  // Copy with no changes
  let s = Point { ...p }
  println(s)                        // Point(x: 3, y: 4)
}
