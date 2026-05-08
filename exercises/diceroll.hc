// Exercise: diceroll
// A dice-rolling simulator with formatted output.
//
// Rolls N dice (default 3), displays each roll in a table,
// and shows the total and average.
//
// Usage: hica run exercises/diceroll.hc
//        hica run exercises/diceroll.hc -- 5    (roll 5 dice)
//
// In C this requires srand(time(NULL)), rand() % 6, and
// printf format strings for alignment. In hica it's
// random() + pad_left() + show_fixed().

fun roll_dice(n: int) {
  println("Rolling {n} dice:")
  println("")
  println(pad_left("#", 4, " ") + pad_left("Die", 6, " "))
  println(pad_left("--", 4, " ") + pad_left("---", 6, " "))
  var total = 0
  for i in 1..n {
    let roll = random(1, 7)
    total = total + roll
    println(pad_left(show(i), 4, " ") + pad_left(show(roll), 6, " "))
  }
  println("")
  println("Total:   " + show(total))
  println("Average: " + show(total / n))
}

fun main() {
  let args = get_args()
  let n = if length(args) == 0 { 3 }
  else {
    match parse_int(args[0]) {
      Some(v) => v,
      None => 3
    }
  }
  roll_dice(n)
}
