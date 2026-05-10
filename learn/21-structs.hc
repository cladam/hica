// ============================================================
// Lesson 21: Structs
// ============================================================
//
// A struct defines a named record with typed fields:
//
//   struct Point { x: int, y: int }
//   let p = Point { x: 3, y: 4 }
//   p.x   // 3
//
// Functions that operate on structs are regular free functions:
//
//   fun distance_sq(p: Point) : int => p.x * p.x + p.y * p.y
//
// Struct names must start with an uppercase letter.
//
// ── Struct vs. Tuple ─────────────────────────────────────────
//
// Use a tuple for quick, temporary grouping:
//
//   let pair = (3, 4)       // anonymous — what do 3 and 4 mean?
//
// Use a struct when the data has a clear identity:
//
//   let p = Point { x: 3, y: 4 }  // self-documenting
//
// Rule of thumb:
//   • Tuple  → throwaway pairs, returning two values from a function
//   • Struct → domain concepts (Point, Person, Config, …)
//
// If you find yourself writing comments to explain a tuple's
// fields, it's time to reach for a struct.
//
// ============================================================

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
  let love = Person { name: "Love", age: 12 }
  println(greet(love))

  // println auto-shows structs
  println(origin)
  println(love)

  // --- Struct update syntax ---
  // Create a new struct based on an existing one, overriding some fields:
  let moved = Point { ...p, x: 10 }
  println(moved)                     // Point(x: 10, y: 4)

  // Override all fields
  let flipped = Point { ...p, x: p.y, y: p.x }
  println(flipped)                   // Point(x: 4, y: 3)

  // Copy with no overrides (creates an identical value)
  let twin = Point { ...p }
  println(twin)                      // Point(x: 3, y: 4)

  // Works with any struct
  let older = Person { ...love, age: 13 }
  println(greet(older))              // "Hej, Love! You are 13 years old."
}
