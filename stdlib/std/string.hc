// hica – string stdlib module
//
// Extended string functions. Auto-import with: import "std/string"
// Functions that depend on prelude internals (pad_left, pad_right, repeat_str,
// removeprefix) stay in the prelude until std/cli is separated.
//
// This source file is part of the hica open source project
// Copyright (C) 2026 Claes Adamsson <claes.adamsson@gmail.com>
//
// See https://github.com/cladam/hica/blob/main/LICENSE for license information

// --- Counting ---

pub fun count_substr(s: string, sub: string) => length(split(s, sub)) - 1

// --- Wrapping ---

pub fun surround(s: string, wrap: string) => wrap + s + wrap

// --- Case helpers ---

pub fun capitalise(s: string) : string =>
  if str_length(s) == 0 { "" }
  else { to_upper(s[:1]) + to_lower(s[1:]) }

pub fun capwords(s: string) : string =>
  join(map(filter(split(s, " "), (w) => str_length(w) != 0), (w) => capitalise(w)), " ")

pub fun shout(s: string) : string => to_upper(s) + "!"

// --- Suffix removal ---

pub fun removesuffix(s: string, suf: string) : string =>
  if ends_with(s, suf) { s[:str_length(s) - str_length(suf)] }
  else { s }
