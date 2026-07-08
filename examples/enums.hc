// hica — Enum types (algebraic data types)

// Simple enum — no data, just named variants
type Color {
  Red,
  Green,
  Blue
}

// Enum with data — each variant can carry fields
type Shape {
  Circle(radius: float),
  Rect(width: float, height: float),
  Point
}

// Use match to handle each variant
fun describe(s: Shape) : string => match s {
  Circle(r)    => "circle with radius {r}",
  Rect(w, h)   => "{w} x {h} rectangle",
  Point        => "a point"
}

fun area(s: Shape) : float => match s {
  Circle(r)    => 3.14159 * r * r,
  Rect(w, h)   => w * h,
  Point        => 0.0
}

fun color_name(c: Color) : string => match c {
  Red   => "red",
  Green => "green",
  Blue  => "blue"
}

fun main() {
  // Construct enum values
  let c = Red
  let s1 = Circle(5.0)
  let s2 = Rect(3.0, 4.0)
  let s3 = Point

  // println auto-shows enum values
  println(c)
  println(s1)
  println(s2)

  // Match on them
  println(color_name(c))
  println(describe(s1))
  println(describe(s2))
  println(describe(s3))

  // Use in expressions
  println("Area of circle: {area(s1)}")
  println("Area of rect: {area(s2)}")
}
