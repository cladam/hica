// hica – string prelude
//
// Higher-level string functions built on top of the string primitives
// (str_length, contains, trim, split, etc.).
//
// This source file is part of the hica open source project
// Copyright (C) 2026 Claes Adamsson <claes.adamsson@gmail.com>
//
// See https://github.com/cladam/hica/blob/main/LICENSE for license information

// --- Predicates ---

fun is_empty(s) => str_length(s) == 0

fun is_blank(s) => is_empty(trim(s))

// --- Splitting helpers ---

fun words(s: string) => filter(split(s, " "), (w) => not_(is_empty(w)))

fun lines(s) => split(s, "\n")

fun unwords(ws) => join(ws, " ")

fun unlines(ls) => join(ls, "\n")

// --- Counting ---

fun count_substr(s: string, sub: string) => length(split(s, sub)) - 1

// --- Building ---

fun repeat_str(s: string, n: int) : string => if n <= 0 { "" } else { s + repeat_str(s, n - 1) }

fun pad_left(s: string, width: int, ch: string) => repeat_str(ch, max(0, width - str_length(s))) + s

fun pad_right(s: string, width: int, ch: string) => s + repeat_str(ch, max(0, width - str_length(s)))

fun center(s: string, width: int, ch: string) {
  let total = max(0, width - str_length(s));
  let left = total / 2;
  let right = total - left;
  repeat_str(ch, left) + s + repeat_str(ch, right)
}

fun surround(s: string, wrap: string) => wrap + s + wrap

// --- Case helpers (require slicing) ---

fun capitalize(s: string) : string =>
  if str_length(s) == 0 { "" }
  else { to_upper(s[:1]) + to_lower(s[1:]) }

fun capwords(s: string) : string =>
  join(map(words(s), (w) => capitalize(w)), " ")

// --- Prefix / suffix removal (require slicing) ---

fun removeprefix(s: string, pre: string) : string =>
  if starts_with(s, pre) { s[str_length(pre):] }
  else { s }

fun removesuffix(s: string, suf: string) : string =>
  if ends_with(s, suf) { s[:str_length(s) - str_length(suf)] }
  else { s }
