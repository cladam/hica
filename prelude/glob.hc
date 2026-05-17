// hica – glob prelude
//
// Character classification and glob pattern matching.
// Provides is_digit, is_alpha, etc. for character-level checks,
// and glob_match for simple wildcard pattern matching (* and ?).
//
// This source file is part of the hica open source project
// Copyright (C) 2026 Claes Adamsson <claes.adamsson@gmail.com>
//
// See https://github.com/cladam/hica/blob/main/LICENSE for license information

// ---------------------------------------------------------------------------
// Character classification
// ---------------------------------------------------------------------------

// True if c is an ASCII digit (0–9)
fun is_digit(c: char) : bool {
  let n = ord(c)
  n >= 48 && n <= 57
}

// True if c is an ASCII uppercase letter (A–Z)
fun is_upper(c: char) : bool {
  let n = ord(c)
  n >= 65 && n <= 90
}

// True if c is an ASCII lowercase letter (a–z)
fun is_lower(c: char) : bool {
  let n = ord(c)
  n >= 97 && n <= 122
}

// True if c is an ASCII letter (a–z, A–Z)
fun is_alpha(c: char) : bool => is_upper(c) || is_lower(c)

// True if c is an ASCII letter or digit
fun is_alnum(c: char) : bool => is_alpha(c) || is_digit(c)

// True if c is an ASCII whitespace character
fun is_space(c: char) : bool {
  let n = ord(c)
  n == 32 || n == 9 || n == 10 || n == 13
}

// True if c is an ASCII punctuation character (printable, non-alnum, non-space)
fun is_punct(c: char) : bool {
  let n = ord(c)
  (n >= 33 && n <= 47) || (n >= 58 && n <= 64) || (n >= 91 && n <= 96) || (n >= 123 && n <= 126)
}

// ---------------------------------------------------------------------------
// String-level classification helpers
// ---------------------------------------------------------------------------

// True if every character in s is a digit
fun all_digits(s: string) : bool =>
  if str_length(s) == 0 { false }
  else { all(chars(s), is_digit) }

// True if every character in s is a letter
fun all_alpha(s: string) : bool =>
  if str_length(s) == 0 { false }
  else { all(chars(s), is_alpha) }

// True if every character in s is uppercase
fun all_upper(s: string) : bool =>
  if str_length(s) == 0 { false }
  else { all(chars(s), is_upper) }

// True if every character in s is lowercase
fun all_lower(s: string) : bool =>
  if str_length(s) == 0 { false }
  else { all(chars(s), is_lower) }

// True if every character in s is alphanumeric
fun all_alnum(s: string) : bool =>
  if str_length(s) == 0 { false }
  else { all(chars(s), is_alnum) }

// ---------------------------------------------------------------------------
// Glob matching
// ---------------------------------------------------------------------------

// Match a list of pattern chars against a list of input chars.
// Supports:
//   *  — matches zero or more characters (non-greedy, does not cross /)
//   ?  — matches exactly one character (any except /)
//   everything else — literal match
fun glob_match_chars(pat: list<char>, input: list<char>) : bool =>
  match pat {
    [] => match input {
      [] => true,
      _ => false
    },
    [p, ..prest] => match char_to_string(p) {
      "?" => match input {
        [] => false,
        [c, ..irest] => if char_to_string(c) == "/" { false } else { glob_match_chars(prest, irest) }
      },
      "*" => match prest {
        // trailing * matches everything (except nothing with /)
        [] => all(input, (c) => char_to_string(c) != "/"),
        _ => {
          // try matching zero chars, then one, then two, etc.
          glob_star(prest, input)
        }
      },
      _ => match input {
        [] => false,
        [c, ..irest] => if p == c { glob_match_chars(prest, irest) } else { false }
      }
    }
  }

// Helper: try matching rest of pattern after * at each position
fun glob_star(prest: list<char>, input: list<char>) : bool =>
  if glob_match_chars(prest, input) { true }
  else {
    match input {
      [] => false,
      [c, ..irest] => if char_to_string(c) == "/" { false } else { glob_star(prest, irest) }
    }
  }

// Match a glob pattern against a string.
// Patterns: * matches any chars (not /), ? matches one char (not /).
// For paths, match each segment or use glob_match_path for ** support.
fun glob_match(pattern: string, s: string) : bool =>
  glob_match_chars(chars(pattern), chars(s))

// ---------------------------------------------------------------------------
// Path glob matching (with ** support)
// ---------------------------------------------------------------------------

// Match a glob pattern against a path, splitting on /.
// ** matches zero or more path segments.
fun glob_match_path(pattern: string, path: string) : bool {
  let pat_parts = split(pattern, "/")
  let path_parts = split(path, "/")
  glob_match_segments(pat_parts, path_parts)
}

// Match pattern segments against path segments
fun glob_match_segments(pats: list<string>, paths: list<string>) : bool =>
  match pats {
    [] => match paths {
      [] => true,
      _ => false
    },
    [p, ..prest] => if p == "**" {
      // ** matches zero or more segments
      glob_doublestar(prest, paths)
    } else {
      match paths {
        [] => false,
        [s, ..srest] => if glob_match(p, s) { glob_match_segments(prest, srest) } else { false }
      }
    }
  }

// Helper: try matching rest of pattern after ** at each position
fun glob_doublestar(prest: list<string>, paths: list<string>) : bool =>
  if glob_match_segments(prest, paths) { true }
  else {
    match paths {
      [] => false,
      [_, ..srest] => glob_doublestar(prest, srest)
    }
  }
