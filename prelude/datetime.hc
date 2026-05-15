// hica – datetime prelude
//
// String-based datetime parsing and decomposition functions.
// All datetimes are represented as plain strings in ISO 8601 format.
// These functions validate and decompose datetime strings into parts
// without pulling in heavy datetime libraries.
//
// Supports the four TOML datetime variants:
//   Offset datetime:  2024-05-15T07:32:00Z   or  2024-05-15T07:32:00+02:00
//   Local datetime:   2024-05-15T07:32:00
//   Local date:       2024-05-15
//   Local time:       07:32:00   or  07:32:00.123456  or  07:32 (seconds omitted)
//
// This source file is part of the hica open source project
// Copyright (C) 2026 Claes Adamsson <claes.adamsson@gmail.com>
//
// See https://github.com/cladam/hica/blob/main/LICENSE for license information

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

// Check if every character in a string is a digit
fun all_digits(s: string) : bool =>
  if str_length(s) == 0 { false }
  else {
    let chars = split(s, "")
    all(chars, (c) => c >= "0" && c <= "9")
  }

// Parse a substring as an integer, returning None on failure
fun parse_part(s: string, start: int, len: int) : maybe<int> =>
  parse_int(s[start:start + len])

// Check if a value falls within an inclusive range
fun in_range(n: int, lo: int, hi: int) : bool => n >= lo && n <= hi

// Days in a given month (handles leap years)
fun days_in_month(year: int, month: int) : int =>
  match month {
    1 => 31,
    2 => if (year % 4 == 0 && year % 100 != 0) || year % 400 == 0 { 29 } else { 28 },
    3 => 31,
    4 => 30,
    5 => 31,
    6 => 30,
    7 => 31,
    8 => 31,
    9 => 30,
    10 => 31,
    11 => 30,
    12 => 31,
    _ => 0
  }

// ---------------------------------------------------------------------------
// Validation
// ---------------------------------------------------------------------------

// Validate a date string: YYYY-MM-DD
fun is_valid_date(s: string) : bool =>
  if str_length(s) != 10 { false }
  else if s[4:5] != "-" || s[7:8] != "-" { false }
  else if !all_digits(s[0:4]) || !all_digits(s[5:7]) || !all_digits(s[8:10]) { false }
  else {
    match parse_int(s[0:4]) {
      Some(y) => match parse_int(s[5:7]) {
        Some(m) => match parse_int(s[8:10]) {
          Some(d) => in_range(m, 1, 12) && in_range(d, 1, days_in_month(y, m)),
          None => false
        },
        None => false
      },
      None => false
    }
  }

// Validate HH:MM (seconds omitted)
fun is_valid_time_short(s: string) : bool =>
  match parse_int(s[0:2]) {
    Some(h) => match parse_int(s[3:5]) {
      Some(m) => in_range(h, 0, 23) && in_range(m, 0, 59),
      None => false
    },
    None => false
  }

// Validate HH:MM:SS with optional fractional seconds
fun is_valid_time_full(s: string) : bool =>
  if !all_digits(s[6:8]) { false }
  else {
    let hh = parse_int(s[0:2])
    let mm = parse_int(s[3:5])
    let ss = parse_int(s[6:8])
    match hh {
      Some(h) => match mm {
        Some(m) => match ss {
          Some(sec) => {
            let base_ok = in_range(h, 0, 23) && in_range(m, 0, 59) && in_range(sec, 0, 59)
            if str_length(s) == 8 { base_ok }
            else if s[8:9] == "." {
              let frac = s[9:]
              base_ok && str_length(frac) > 0 && all_digits(frac)
            }
            else { false }
          },
          None => false
        },
        None => false
      },
      None => false
    }
  }

// Validate a time string: HH:MM:SS, HH:MM:SS.fraction, or HH:MM (seconds omitted)
fun is_valid_time(s: string) : bool =>
  if str_length(s) < 5 { false }
  else if s[2:3] != ":" { false }
  else if !all_digits(s[0:2]) || !all_digits(s[3:5]) { false }
  else if str_length(s) == 5 { is_valid_time_short(s) }
  else if str_length(s) >= 8 && s[5:6] == ":" { is_valid_time_full(s) }
  else { false }

// Validate an offset: Z, +HH:MM, or -HH:MM
fun is_valid_offset(s: string) : bool =>
  if s == "Z" || s == "z" { true }
  else if str_length(s) != 6 { false }
  else {
    let sign = s[0:1]
    if sign != "+" && sign != "-" { false }
    else if s[3:4] != ":" { false }
    else if !all_digits(s[1:3]) || !all_digits(s[4:6]) { false }
    else {
      match parse_int(s[1:3]) {
        Some(h) => match parse_int(s[4:6]) {
          Some(m) => in_range(h, 0, 23) && in_range(m, 0, 59),
          None => false
        },
        None => false
      }
    }
  }

// Check if rest (time+offset) is valid with Z/z offset
fun check_z_offset(rest: string) : bool {
  let zi = match index_of(rest, "Z") { Some(i) => i, None => match index_of(rest, "z") { Some(i) => i, None => 0 } }
  let t = rest[0:zi]
  is_valid_time(t) && is_valid_offset(rest[zi:])
}

// Check if rest (time+offset) is valid with +/-HH:MM offset
fun check_numeric_offset(rest: string) : bool {
  if str_length(rest) < 11 { false }
  else {
    let sign_pos = str_length(rest) - 6
    let sign_char = rest[sign_pos:sign_pos + 1]
    if sign_char != "+" && sign_char != "-" { false }
    else {
      let t = rest[0:sign_pos]
      let o = rest[sign_pos:]
      is_valid_time(t) && is_valid_offset(o)
    }
  }
}

// Validate an ISO 8601 offset datetime: YYYY-MM-DDThh:mm[:ss[.frac]]Z/±HH:MM
fun is_iso_datetime(s: string) : bool =>
  if str_length(s) < 17 { false }
  else {
    let sep = s[10:11]
    if sep != "T" && sep != "t" && sep != " " { false }
    else if !is_valid_date(s[0:10]) { false }
    else {
      let rest = s[11:]
      if contains(rest, "Z") || contains(rest, "z") { check_z_offset(rest) }
      else { check_numeric_offset(rest) }
    }
  }

// Validate a local datetime: YYYY-MM-DDThh:mm[:ss[.frac]] (no offset)
fun is_local_datetime(s: string) : bool =>
  if str_length(s) < 16 { false }
  else {
    let sep = s[10:11]
    if sep != "T" && sep != "t" && sep != " " { false }
    else {
      is_valid_date(s[0:10]) && is_valid_time(s[11:])
    }
  }

// Validate a local date: YYYY-MM-DD
fun is_local_date(s: string) : bool => is_valid_date(s)

// Validate a local time: HH:MM:SS[.frac]
fun is_local_time(s: string) : bool => is_valid_time(s)

// ---------------------------------------------------------------------------
// Decomposition
// ---------------------------------------------------------------------------

// Parse a date string into (year, month, day) or Err
fun date_parts(s: string) : result<(int, int, int), string> =>
  if !is_valid_date(s) { Err("invalid date: " + s) }
  else {
    match parse_int(s[0:4]) {
      Some(y) => match parse_int(s[5:7]) {
        Some(m) => match parse_int(s[8:10]) {
          Some(d) => Ok((y, m, d)),
          None => Err("invalid day")
        },
        None => Err("invalid month")
      },
      None => Err("invalid year")
    }
  }

// Parse a time string into (hour, minute, second) or Err
// Fractional seconds are truncated. Seconds-omitted times return 0 for seconds.
fun time_parts(s: string) : result<(int, int, int), string> =>
  if !is_valid_time(s) { Err("invalid time: " + s) }
  else if str_length(s) == 5 {
    // HH:MM — seconds omitted
    match parse_int(s[0:2]) {
      Some(h) => match parse_int(s[3:5]) {
        Some(m) => Ok((h, m, 0)),
        None => Err("invalid minute")
      },
      None => Err("invalid hour")
    }
  }
  else {
    match parse_int(s[0:2]) {
      Some(h) => match parse_int(s[3:5]) {
        Some(m) => match parse_int(s[6:8]) {
          Some(sec) => Ok((h, m, sec)),
          None => Err("invalid second")
        },
        None => Err("invalid minute")
      },
      None => Err("invalid hour")
    }
  }

// Extract the date portion from a datetime string
fun datetime_date(s: string) : result<string, string> =>
  if str_length(s) >= 10 && is_valid_date(s[0:10]) { Ok(s[0:10]) }
  else { Err("no valid date in: " + s) }

// Strip offset from a time+offset string to get just the time portion
fun strip_offset(rest: string) : string =>
  if contains(rest, "Z") || contains(rest, "z") {
    match index_of(rest, "Z") { Some(i) => rest[0:i], None => match index_of(rest, "z") { Some(i) => rest[0:i], None => rest } }
  } else if str_length(rest) >= 11 && (rest[str_length(rest) - 6:str_length(rest) - 5] == "+" || rest[str_length(rest) - 6:str_length(rest) - 5] == "-") {
    rest[0:str_length(rest) - 6]
  } else {
    rest
  }

// Extract the time portion from a local or offset datetime string
fun datetime_time(s: string) : result<string, string> =>
  if str_length(s) < 16 { Err("string too short for datetime") }
  else {
    let sep = s[10:11]
    if sep != "T" && sep != "t" && sep != " " { Err("no datetime separator found") }
    else {
      let time_part = strip_offset(s[11:])
      if is_valid_time(time_part) { Ok(time_part) }
      else { Err("invalid time portion") }
    }
  }

// Extract the offset portion from an offset datetime, or None for local
fun datetime_offset(s: string) : maybe<string> =>
  if contains(s, "Z") { Some("Z") }
  else if contains(s, "z") { Some("Z") }
  else if str_length(s) >= 22 && (s[str_length(s) - 6:str_length(s) - 5] == "+" || s[str_length(s) - 6:str_length(s) - 5] == "-") {
    let o = s[str_length(s) - 6:]
    if is_valid_offset(o) { Some(o) } else { None }
  }
  else { None }

// Classify a datetime string into its variant
fun datetime_kind(s: string) : string =>
  if is_local_time(s) { "local-time" }
  else if is_local_date(s) && str_length(s) == 10 { "local-date" }
  else if is_iso_datetime(s) { "offset-datetime" }
  else if is_local_datetime(s) { "local-datetime" }
  else { "invalid" }

// ---------------------------------------------------------------------------
// Comparison
// ---------------------------------------------------------------------------

// Compare two date strings lexicographically (ISO 8601 sorts correctly).
// Returns -1 if d1 < d2, 0 if equal, 1 if d1 > d2.
// Both must be valid dates; returns 0 on invalid input.
fun date_cmp(d1: string, d2: string) : int =>
  if !is_valid_date(d1) || !is_valid_date(d2) { 0 }
  else if d1 < d2 { -1 }
  else if d1 > d2 { 1 }
  else { 0 }

// Compare two time strings (HH:MM:SS[.frac]).
fun time_cmp(t1: string, t2: string) : int =>
  if !is_valid_time(t1) || !is_valid_time(t2) { 0 }
  else if t1 < t2 { -1 }
  else if t1 > t2 { 1 }
  else { 0 }

// Compare two local datetime strings.
fun datetime_cmp(d1: string, d2: string) : int =>
  if !is_local_datetime(d1) || !is_local_datetime(d2) { 0 }
  else if d1 < d2 { -1 }
  else if d1 > d2 { 1 }
  else { 0 }

// True if d1 is strictly before d2 (works for dates and local datetimes).
fun is_before(d1: string, d2: string) : bool =>
  if is_valid_date(d1) && is_valid_date(d2) { d1 < d2 }
  else if is_local_datetime(d1) && is_local_datetime(d2) { d1 < d2 }
  else if is_valid_time(d1) && is_valid_time(d2) { d1 < d2 }
  else { false }

// ---------------------------------------------------------------------------
// Offset manipulation
// ---------------------------------------------------------------------------

// Convert an offset string (Z, +HH:MM, -HH:MM) to total minutes.
// Z and +00:00 return Ok(0), +02:00 returns Ok(120), -05:30 returns Ok(-330).
fun offset_to_minutes(s: string) : result<int, string> =>
  if s == "Z" || s == "z" { Ok(0) }
  else if !is_valid_offset(s) { Err("invalid offset: " + s) }
  else {
    let sign = if s[0:1] == "-" { -1 } else { 1 }
    match parse_int(s[1:3]) {
      Some(h) => match parse_int(s[4:6]) {
        Some(m) => Ok(sign * (h * 60 + m)),
        None => Err("invalid offset minutes")
      },
      None => Err("invalid offset hours")
    }
  }

// ---------------------------------------------------------------------------
// Weekday calculation (Tomohiko Sakamoto's algorithm)
// ---------------------------------------------------------------------------

// Helper: look up a value from a small list by index
fun list_int_nth(xs: list<int>, i: int) : int => match xs {
  [] => 0,
  [x, ..rest] => if i == 0 { x } else { list_int_nth(rest, i - 1) }
}

// Day of week for a valid date. Returns "monday" through "sunday".
fun day_of_week(s: string) : result<string, string> =>
  if !is_valid_date(s) { Err("invalid date: " + s) }
  else {
    match date_parts(s) {
      Err(e) => Err(e),
      Ok(parts) => {
        // Sakamoto's algorithm
        let y = if parts.1 < 3 { parts.0 - 1 } else { parts.0 }
        let t = [0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4]
        let idx = (y + y / 4 - y / 100 + y / 400 + list_int_nth(t, parts.1 - 1) + parts.2) % 7
        let names = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
        match idx {
          0 => Ok("sunday"),
          1 => Ok("monday"),
          2 => Ok("tuesday"),
          3 => Ok("wednesday"),
          4 => Ok("thursday"),
          5 => Ok("friday"),
          6 => Ok("saturday"),
          _ => Err("unreachable")
        }
      }
    }
  }

// ---------------------------------------------------------------------------
// Future: epoch conversion (to_unix / from_unix) and ISO 8601 durations
// are deferred to Phase 3 when richer datetime types or Koka std/time
// backing may be introduced.
// ---------------------------------------------------------------------------
