// hica – std/trusted — type-safe string trust boundaries
//
// Provides the Trusted type: a string that has explicitly crossed a trust
// boundary through a smart constructor or validator.
//
// Usage: import "std/trusted"
//
// ── The validation ladder ────────────────────────────────────────────────
//
// Apply validators in this order (cheapest first) to keep rejection fast
// and deny attackers the expensive steps:
//
//   1. Origin      — does this come from a trusted source? (app-level)
//   2. Size        — validate_range / validate_maxlen  (constant time)
//   3. Characters  — validate_alnum / validate_with    (scan, no parse)
//   4. Format      — validate_with(s, regex_pred)      (parser / regex)
//   5. Semantic    — DB / state check                  (app-level)
//
// std/trusted covers rungs 2-4. Rungs 1 and 5 are intentionally left to
// application code because they require external context (network origin,
// database state). This is by design: those checks are expensive, and the
// type system ensures callers consciously perform them.
//
// Once a value is Trusted, `trusted_value(t)` is the only way to read it
// back. That explicit unwrap is the right place to decide whether to log the
// raw string — you almost never should (log the fact of rejection, not the
// rejected input itself).
//
// This source file is part of the hica open source project
// Copyright (C) 2026 Claes Adamsson <claes.adamsson@gmail.com>
//
// See https://github.com/cladam/hica/blob/main/LICENSE for license information

// The Trusted type. The constructor is private to this module —
// callers must use trust() or a validate_* function.
pub struct Trusted priv { data: string }

// Explicit trust marker: "I have verified this string is safe."
// Use only when you are certain the value is already known-good.
pub fun trust(s: string) : Trusted => Trusted { data: s }

// Unwrap the inner string from a Trusted value.
pub fun trusted_value(t: Trusted) : string => t.data

// ---------------------------------------------------------------------------
// Validators — each returns Some(Trusted) on success, None on failure
// ---------------------------------------------------------------------------

// Accept any non-empty string.
pub fun validate_nonempty(s: string) : maybe<Trusted> =>
  if str_length(s) > 0 { Some(Trusted { data: s }) }
  else { None }

// Accept a string whose length does not exceed `max` characters.
// Rung 2 of the validation ladder: size upper bound.
pub fun validate_maxlen(s: string, max: int) : maybe<Trusted> =>
  if str_length(s) <= max { Some(Trusted { data: s }) }
  else { None }

// Accept a string whose length is between `min` and `max` (inclusive).
// Rung 2 of the validation ladder: both size bounds at once.
// Prefer this over chaining validate_nonempty + validate_maxlen.
pub fun validate_range(s: string, min_len: int, max_len: int) : maybe<Trusted> =>
  if str_length(s) >= min_len && str_length(s) <= max_len { Some(Trusted { data: s }) }
  else { None }

// Accept a non-empty string containing only alphanumeric characters (a-z A-Z 0-9).
// Rung 3 of the validation ladder: character-set check (any order, no parsing).
// Useful for identifiers, tokens, and simple keys.
pub fun validate_alnum(s: string) : maybe<Trusted> =>
  if all_alnum(s) { Some(Trusted { data: s }) }
  else { None }

// Accept a string that satisfies a caller-supplied predicate.
// Rung 3 (character check) or Rung 4 (format/regex) depending on the predicate.
// This is the escape hatch for custom validation logic:
//
//   let t = validate_with(input, (s) => starts_with(s, "usr_"))
pub fun validate_with(s: string, pred: (string) -> bool) : maybe<Trusted> =>
  if pred(s) { Some(Trusted { data: s }) }
  else { None }

// ---------------------------------------------------------------------------
// Combinators
// ---------------------------------------------------------------------------

// Chain two validators: both must pass.
// validate_and(validate_nonempty(s), validate_maxlen(s, 64))
pub fun validate_and(a: maybe<Trusted>, b: maybe<Trusted>) : maybe<Trusted> =>
  match a {
    None => None,
    Some(_) => b
  }

// Unwrap a trusted value with a fallback string (already trusted).
pub fun trusted_or(t: maybe<Trusted>, fallback: string) : Trusted =>
  match t {
    Some(v) => v,
    None => Trusted { data: fallback }
  }
