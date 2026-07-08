// hica – std/trusted — type-safe string trust boundaries
//
// Provides the Trusted type: a string that has explicitly crossed a trust
// boundary through a smart constructor or validator.
//
// Usage: import "std/trusted"
//
// Pattern:
//   1. Raw strings arrive from external sources (user input, env vars, …)
//   2. They pass through a validate_* function, which returns maybe<Trusted>
//   3. Functions that need verified data accept Trusted, not plain string
//   4. Callers cannot forge a Trusted value — the constructor is opaque
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
pub fun validate_maxlen(s: string, max: int) : maybe<Trusted> =>
  if str_length(s) <= max { Some(Trusted { data: s }) }
  else { None }

// Accept a non-empty string containing only alphanumeric characters (a-z A-Z 0-9).
// Useful for identifiers, tokens, and simple keys.
pub fun validate_alnum(s: string) : maybe<Trusted> =>
  if all_alnum(s) { Some(Trusted { data: s }) }
  else { None }

// Accept a string that satisfies a caller-supplied predicate.
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
