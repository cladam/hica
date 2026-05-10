// Struct destructuring in match
struct Point { x: int, y: int }
struct Color { r: int, g: int, b: int }

fun describe(p: Point) : string => match p {
  Point { x: 0, y: 0 } => "origin",
  Point { x, y: 0 }    => "on x-axis at {x}",
  Point { x: 0, y }    => "on y-axis at {y}",
  Point { x, y }       => "({x}, {y})"
}

fun is_bright(c: Color) : bool => match c {
  Color { r, g, b } => r + g + b > 400
}

fun main() {
  let p1 = Point { x: 0, y: 0 }
  let p2 = Point { x: 5, y: 0 }
  let p3 = Point { x: 0, y: 3 }
  let p4 = Point { x: 2, y: 7 }
  println(describe(p1))
  println(describe(p2))
  println(describe(p3))
  println(describe(p4))

  let white = Color { r: 255, g: 255, b: 255 }
  let dark  = Color { r: 10, g: 10, b: 10 }
  println(is_bright(white))
  println(is_bright(dark))
}
