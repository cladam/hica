// ============================================================
// Lesson 29: Formatted Output
// ============================================================
//
// Hica has functions for formatted text output:
//
// **Padding (alignment):**
//   pad_left(s, width, fill)   — right-align s in a field
//   pad_right(s, width, fill)  — left-align s in a field
//   center(s, width, fill)     — center s in a field
//
//   pad_left("42", 6, " ")    => "    42"
//   pad_right("hi", 6, ".")   => "hi...."
//   center("ok", 8, "-")      => "---ok---"
//
// **Float precision:**
//   show_fixed(value, decimals) — format a float with exact
//                                 decimal places
//
//   show_fixed(3.14159, 2)     => "3.14"
//   show_fixed(100.0 / 3.0, 1) => "33.3"
//
// Combine with `show()` to format integers for tables:
//   pad_left(show(42), 6, " ") => "    42"
//
// ============================================================

fun print_table() {
  // A simple price table
  let items = [("Cheese", 5.0), ("Pepperoni", 5.75), ("Veggie", 7.25)]
  println(pad_right("Item", 14, " ") + pad_left("Price", 8, " "))
  println(repeat_str("-", 22))
  for i in 0..2 {
    let (name, price) = items[i]
    let line = pad_right(name, 14, " ") + pad_left("$" + show_fixed(price, 2), 8, " ")
    println(line)
  }
}

fun print_scores() {
  // Right-aligned numbers in a column
  let scores = [100, 85, 7, 1234]
  for i in 0..3 {
    println(pad_left(show(scores[i]), 6, " "))
  }
}

fun main() {
  print_table()
  println("")
  print_scores()
}

// ============================================================
// Expected output:
//   Item              Price
//   ----------------------
//   Cheese            $5.00
//   Pepperoni         $5.75
//   Veggie            $7.25
//
//      100
//       85
//        7
//     1234
//
// Challenge: Print a multiplication table (1-5 × 1-5) where
// each number is right-aligned in a 4-character column.
// ============================================================
