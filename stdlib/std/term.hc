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

// ---------------------------------------------------------------------------
// True color (24-bit RGB) — requires a modern terminal
// Foreground: term_rgb(r, g, b, s)  — wraps s in \e[38;2;R;G;Bm ... \e[0m
// ---------------------------------------------------------------------------

pub fun term_rgb(r: int, g: int, b: int, s: string) : string =>
  term_esc() + "[38;2;" + show(r) + ";" + show(g) + ";" + show(b) + "m" + s + term_esc() + "[0m"

// ---------------------------------------------------------------------------
// Ilseon palette — inspired by github.com/cladam/ilseon
//
// A low-sensory, OLED-focused dark palette with organic and muted accents.
// Colours follow the "Pulse" spectrum (energy & priority) and semantic slots
// from the ilseon app theme.
//
// Requires true color terminal support (iTerm2, VS Code, most modern terminals).
// ---------------------------------------------------------------------------

pub fun ilseon_teal(s: string) : string => term_rgb(0, 191, 165, s)        // #00BFA5  TealAccent — primary action
pub fun ilseon_muted_red(s: string) : string => term_rgb(179, 95, 95, s)   // #B35F5F  MutedRed — urgent / priority high
pub fun ilseon_amber(s: string) : string => term_rgb(192, 138, 62, s)      // #C08A3E  QuietAmber — priority medium
pub fun ilseon_ochre(s: string) : string => term_rgb(226, 176, 94, s)      // #E2B05E  StatusHigh — warm ochre / high energy
pub fun ilseon_sage(s: string) : string => term_rgb(163, 169, 145, s)      // #A3A991  StatusMedium — muted sage / balanced
pub fun ilseon_slate(s: string) : string => term_rgb(125, 133, 151, s)     // #7D8597  StatusLow — steel blue-grey / low pressure
pub fun ilseon_muted_teal(s: string) : string => term_rgb(90, 155, 128, s) // #5A9B80  MutedTeal — green-teal accent
pub fun ilseon_blue_teal(s: string) : string => term_rgb(76, 154, 155, s)  // #4C9A9B  BlueTeal — secondary highlight
pub fun ilseon_slate_blue(s: string) : string => term_rgb(94, 109, 126, s) // #5E6D7E  SlateBlue — quiet UI element
pub fun ilseon_detail(s: string) : string => term_rgb(136, 136, 136, s)    // #888888  MutedDetail — secondary text / low priority

// ----------------------------------------------------------------------------
// hica unique palette
// ---------------------------------------------------------------------------- 