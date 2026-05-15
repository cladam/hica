// ============================================================
// Lesson 39: Dates & Times
// ============================================================
//
// The prelude includes datetime functions (v0.1.0) for working
// with dates and times as strings in ISO 8601 format.
//
// These are string-based — no heavy datetime library, just
// validation, decomposition, and comparison.
//
// Four formats are supported (matching TOML):
//   "2024-05-15"                  — local date
//   "07:32:00"                    — local time
//   "2024-05-15T07:32:00"         — local datetime
//   "2024-05-15T07:32:00Z"        — offset datetime
//   "2024-05-15T07:32:00+02:00"   — offset datetime
//
// Key functions:
//   is_valid_date(s)              — validate a date
//   is_valid_time(s)              — validate a time
//   datetime_kind(s)              — classify the variant
//   date_parts(s)                 — (year, month, day)
//   time_parts(s)                 — (hour, minute, second)
//   is_before(d1, d2)             — comparison
//   day_of_week(s)                — weekday name
//   offset_to_minutes(s)          — "+02:00" → 120
//
// ============================================================

fun main() {
  // --- Validation ---
  println(is_valid_date("2024-05-15"))     // true
  println(is_valid_date("2024-02-29"))     // true  (leap year)
  println(is_valid_date("2023-02-29"))     // false (not a leap year)
  println(is_valid_time("07:32:00"))       // true
  println(is_valid_time("07:32:00.123"))   // true  (fractional seconds)
  println(is_valid_time("25:00:00"))       // false

  // --- Classify ---
  println(datetime_kind("2024-05-15"))                 // "local-date"
  println(datetime_kind("07:32:00"))                   // "local-time"
  println(datetime_kind("2024-05-15T07:32:00"))        // "local-datetime"
  println(datetime_kind("2024-05-15T07:32:00Z"))       // "offset-datetime"
  println(datetime_kind("2024-05-15T07:32:00+02:00"))  // "offset-datetime"
  println(datetime_kind("not-a-date"))                 // "invalid"

  // --- Decompose ---
  match date_parts("2024-05-15") {
    Ok(d) => println("year={d.0} month={d.1} day={d.2}"),
    Err(e) => println(e)
  }

  match time_parts("07:32:45") {
    Ok(t) => println("hour={t.0} min={t.1} sec={t.2}"),
    Err(e) => println(e)
  }

  // --- Extract parts from a full datetime ---
  match datetime_date("2024-05-15T07:32:00+02:00") {
    Ok(d) => println(d),   // "2024-05-15"
    Err(e) => println(e)
  }

  match datetime_time("2024-05-15T07:32:00+02:00") {
    Ok(t) => println(t),   // "07:32:00"
    Err(e) => println(e)
  }

  // --- Offset ---
  match datetime_offset("2024-05-15T07:32:00+02:00") {
    Some(o) => println(o),   // "+02:00"
    None => println("local")
  }

  match offset_to_minutes("+05:30") {
    Ok(m) => println(m),   // 330
    Err(e) => println(e)
  }

  // --- Comparison ---
  println(is_before("2024-01-01", "2024-12-31"))   // true
  println(is_before("2024-12-31", "2024-01-01"))   // false
  println(date_cmp("2024-01-01", "2024-12-31"))    // -1
  println(date_cmp("2024-05-15", "2024-05-15"))    // 0

  // --- Weekday ---
  match day_of_week("2026-05-15") {
    Ok(d) => println(d),   // "friday"
    Err(e) => println(e)
  }

  match day_of_week("2000-01-01") {
    Ok(d) => println(d),   // "saturday"
    Err(e) => println(e)
  }

  // --- UFCS style works too ---
  println("2024-05-15".is_valid_date)           // true
  println("07:32:00".datetime_kind)             // "local-time"
  println("2024-01-01".is_before("2024-12-31")) // true
}
