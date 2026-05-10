// ============================================================
// Lesson 34: Struct Patterns — Destructuring in Match
// ============================================================
//
// You already know how to destructure tuples in match:
//   (0, 0) => "origin"
//
// Struct patterns let you do the same with structs:
//   Point { x: 0, y: 0 } => "origin"
//
// Three forms:
//
//   Point { x, y }       — bind all fields to variables
//   Point { x: 0, y }    — match a literal, bind the rest
//   Point { x }          — partial: unmentioned fields are _
//
// ============================================================

struct Point { x: int, y: int }

// --- Full destructuring: bind all fields ---
fun describe(p: Point) : string => match p {
  Point { x: 0, y: 0 } => "origin",
  Point { x, y: 0 }    => "on x-axis at {x}",
  Point { x: 0, y }    => "on y-axis at {y}",
  Point { x, y }       => "({x}, {y})"
}

// --- Partial destructuring: only the fields you need ---
struct Player { name: string, score: int, level: int }

fun rank(p: Player) : string => match p {
  Player { score: 0 }           => "newcomer",
  Player { level, score } => "level {level} with {score} pts"
}

fun main() {
  // Point examples
  println(describe(Point { x: 0, y: 0 }))   // origin
  println(describe(Point { x: 5, y: 0 }))   // on x-axis at 5
  println(describe(Point { x: 0, y: 3 }))   // on y-axis at 3
  println(describe(Point { x: 2, y: 7 }))   // (2, 7)

  // Partial destructuring
  let kalle = Player { name: "Kalle", score: 0, level: 1 }
  let lisa   = Player { name: "Lisa", score: 42, level: 3 }
  println(rank(kalle))   // newcomer
  println(rank(lisa))     // level 3 with 42 pts
}
