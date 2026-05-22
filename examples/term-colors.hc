// Terminal color and style demo using the std/term stdlib module.
//
// Usage: hica run examples/term-colors.hc

import "std/term"

fun main() {
  // Foreground colors
  println(red("red text"))
  println(green("green text"))
  println(yellow("yellow text"))
  println(blue("blue text"))
  println(magenta("magenta text"))
  println(cyan("cyan text"))
  println(white("white text"))

  // Styles
  println(bold("bold text"))
  println(dim("dim text"))
  println(italic("italic text"))
  println(underline("underlined text"))
  println(strikethrough("strikethrough text"))

  // Bright variants
  println(bright_red("bright red"))
  println(bright_green("bright green"))
  println(bright_cyan("bright cyan"))

  // Composition: nest functions to combine effects
  println(bold(red("bold red")))
  println(bold(green("bold green")))
  println(underline(cyan("underlined cyan")))

  // Practical patterns
  println(green("OK") + " build passed")
  println(red("error: ") + "file not found")
  println(bold(yellow("warning: ")) + "deprecated function")
  println(dim("# this is a comment"))
}
