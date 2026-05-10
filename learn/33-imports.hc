// ============================================================
// Lesson 33: Imports — Using Code from Other Files
// ============================================================
//
// As programs grow, you'll want to split code across files.
// Hica's import system lets you do this cleanly.
//
// Three forms:
//
//   import "greet"                   — import all pub items
//   from "greet" import { hello }    — import only specific items
//   pub import "utils"               — re-export to your own importers
//
// Only functions marked `pub` in the imported file are visible.
// Private functions stay private — encapsulation is built in.
//
// The path is relative to the importing file, no .hc extension:
//   import "greet"        →  looks for greet.hc in same directory
//   import "lib/helpers"  →  looks for lib/helpers.hc
//
// ============================================================

// This file imports from greet.hc (in the examples/ directory).
// To run it:
//   ./hica run learn/33-imports.hc
//
// But first, make sure examples/greet.hc exists with:
//   pub fun hello(name: string) { println("hello, " + name + "!") }
//   pub fun goodbye(name: string) { println("goodbye, " + name + "!") }

// NOTE: This lesson explains the concept. Because learn/ and
// examples/ are in different directories, we'll demonstrate
// with a self-contained example below.

// --- Creating a module ---
//
// Any .hc file can be a module. Mark functions with `pub` to export them:
//
//   // math_helpers.hc
//   pub fun square(x) => x * x
//   pub fun cube(x) => x * x * x
//   fun internal_helper(x) => x + 1   // private, not visible
//
// --- Importing a module ---
//
//   // main.hc
//   import "math_helpers"
//
//   fun main() {
//     println(square(5))   // works — square is pub
//     println(cube(3))     // works — cube is pub
//     // internal_helper(1) would fail — not exported
//   }
//
// --- Selective imports ---
//
//   from "math_helpers" import { square }
//
//   fun main() {
//     println(square(5))   // works
//     // cube(3) would fail — not imported
//   }
//
// --- Re-exporting ---
//
//   pub import "math_helpers"
//
//   This makes math_helpers' pub items available to anyone
//   who imports YOUR module. Useful for building libraries.

fun main() {
  println("Lesson 33: Imports")
  println("")
  println("Imports let you split code across files.")
  println("See examples/greet.hc and examples/import.hc for a working example.")
  println("")
  println("Three forms:")
  println("  import path        - import all pub items")
  println("  from path import   - selective import")
  println("  pub import path    - re-export")
  println("")
  println("Try it:")
  println("  ./hica run examples/import.hc")
  println("  ./hica run examples/import-selective.hc")
}
