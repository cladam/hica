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

  println("")

  // Ilseon palette — true color (24-bit RGB), inspired by github.com/cladam/ilseon
  // A low-sensory, OLED-focused dark palette with organic and muted accents.
  println(ilseon_teal("TealAccent — primary action"))
  println(ilseon_muted_red("MutedRed — urgent / priority high"))
  println(ilseon_amber("QuietAmber — priority medium"))
  println(ilseon_ochre("StatusHigh — warm ochre / high energy"))
  println(ilseon_sage("StatusMedium — muted sage / balanced"))
  println(ilseon_slate("StatusLow — steel blue-grey / low pressure"))
  println(ilseon_muted_teal("MutedTeal — green-teal accent"))
  println(ilseon_blue_teal("BlueTeal — secondary highlight"))
  println(ilseon_slate_blue("SlateBlue — quiet UI element"))
  println(ilseon_detail("MutedDetail — secondary text"))

  println("")

  // Combining ilseon colors with styles
  println(bold(ilseon_muted_red("error: ")) + "build failed")
  println(bold(ilseon_amber("warning: ")) + "deprecated usage")
  println(bold(ilseon_teal("ok: ")) + "all tests passed")
}
