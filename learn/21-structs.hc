// 21 — Structs
// Structs define named records with typed fields.

struct Point { x: int, y: int }

struct Person { name: string, age: int }

fun distance_sq(p: Point) : int => p.x * p.x + p.y * p.y

fun greet(p: Person) : string => "Hej, {p.name}! You are {p.age} years old."

fun main() {
  // Construction
  let origin = Point { x: 0, y: 0 }
  let p = Point { x: 3, y: 4 }

  // Field access
  println("origin: ({origin.x}, {origin.y})")
  println("point: ({p.x}, {p.y})")
  println("distance² = {distance_sq(p)}")

  // Struct with string fields
  let alice = Person { name: "Love", age: 12 }
  println(greet(alice))

  // println auto-shows structs
  println(origin)
  println(alice)
}
