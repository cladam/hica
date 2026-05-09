// ============================================================
// Lesson 31: Enum Types
// ============================================================
//
// An enum defines a type with named variants:
//
//   type Direction {
//     North,
//     South,
//     East,
//     West
//   }
//
// Variants can carry data:
//
//   type Shape {
//     Circle(radius: float),
//     Rect(width: float, height: float),
//     Point
//   }
//
// Construct variants like function calls:
//
//   let d = North
//   let s = Circle(5.0)
//
// Use match to handle each variant:
//
//   match s {
//     Circle(r)  => "circle",
//     Rect(w, h) => "rect",
//     Point      => "point"
//   }
//
// ── Enum vs. Struct ──────────────────────────────────────────
//
// Use a struct when every value has the same fields:
//
//   struct Point { x: int, y: int }
//
// Use an enum when a value can be one of several shapes:
//
//   type Shape { Circle(r: float), Rect(w: float, h: float) }
//
// Rule of thumb:
//   • Struct → every value looks the same (AND of fields)
//   • Enum  → each value is one of several alternatives (OR)
//
// ============================================================

// A simple enum — like a list of named constants
type Season {
  Spring,
  Summer,
  Autumn,
  Winter
}

// An enum with data — each variant can hold different fields
type Animal {
  Dog(name: string, age: int),
  Cat(name: string),
  Fish
}

fun season_message(s: Season) : string => match s {
  Spring => "flowers bloom",
  Summer => "sun shines",
  Autumn => "leaves fall",
  Winter => "snow falls"
}

fun greet_animal(a: Animal) : string => match a {
  Dog(name, age) => "{name} the dog, {age} years old",
  Cat(name)      => "{name} the cat",
  Fish           => "just a fish"
}

fun is_pet(a: Animal) : bool => match a {
  Fish => false,
  _    => true
}

fun main() {
  // Simple enum values — no parentheses needed
  let s = Winter
  println(season_message(s))

  // Enum with data — construct like a function call
  let dog = Dog("Buddy", 3)
  let cat = Cat("Whiskers")
  let fish = Fish

  println(greet_animal(dog))
  println(greet_animal(cat))
  println(greet_animal(fish))

  // println auto-shows enums
  println(dog)
  println(cat)
  println(s)

  // Use in if/match expressions
  let animals = [dog, cat, fish]
  let pets = animals |> filter(is_pet)
  println("Pets: {pets}")

  // Exhaustiveness: the compiler warns if you forget a variant!
  // Try commenting out a match arm to see the warning.
}
