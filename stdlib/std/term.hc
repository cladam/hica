// hica standard library — terminal colors and styles
//
// ANSI escape code wrappers for colored/styled terminal output.
// Import with:  import "std/term"
//
// All functions wrap a string with ANSI SGR codes and reset to default after.
// Functions are composable: bold(red("error:")) works correctly.
//
// Example:
//   import "std/term"
//
//   fun main() {
//     println(green("OK"))
//     println(bold(red("error: something went wrong")))
//     println(cyan("info: ") + "all good")
//   }
//
// This source file is part of the hica open source project
// Copyright (C) 2026 Claes Adamsson <claes.adamsson@gmail.com>
//
// See https://github.com/cladam/hica/blob/main/LICENSE for license information

// ESC character (ASCII 27) — used to build ANSI escape sequences
pub fun term_esc() : string => char_to_string(chr(27))

// Apply an ANSI SGR code to text, resetting to default after.
// This is the building block for all color/style functions.
pub fun term_ansi(code: string, s: string) : string =>
  term_esc() + "[" + code + "m" + s + term_esc() + "[0m"

// ---------------------------------------------------------------------------
// Foreground colors
// ---------------------------------------------------------------------------

pub fun red(s: string) : string => term_ansi("31", s)
pub fun green(s: string) : string => term_ansi("32", s)
pub fun yellow(s: string) : string => term_ansi("33", s)
pub fun blue(s: string) : string => term_ansi("34", s)
pub fun magenta(s: string) : string => term_ansi("35", s)
pub fun cyan(s: string) : string => term_ansi("36", s)
pub fun white(s: string) : string => term_ansi("37", s)

// ---------------------------------------------------------------------------
// Text styles
// ---------------------------------------------------------------------------

pub fun bold(s: string) : string => term_ansi("1", s)
pub fun dim(s: string) : string => term_ansi("2", s)
pub fun italic(s: string) : string => term_ansi("3", s)
pub fun underline(s: string) : string => term_ansi("4", s)
pub fun strikethrough(s: string) : string => term_ansi("9", s)

// ---------------------------------------------------------------------------
// Bright foreground colors
// ---------------------------------------------------------------------------

pub fun bright_red(s: string) : string => term_ansi("91", s)
pub fun bright_green(s: string) : string => term_ansi("92", s)
pub fun bright_yellow(s: string) : string => term_ansi("93", s)
pub fun bright_blue(s: string) : string => term_ansi("94", s)
pub fun bright_cyan(s: string) : string => term_ansi("96", s)
pub fun bright_white(s: string) : string => term_ansi("97", s)
