// hica – dotenv stdlib module
//
// Reads .env files and loads key-value pairs into the process environment.
// Import with: import "std/dotenv"
//
// Usage:
//   import "std/dotenv"
//
//   fun main() {
//     dotenv_load(".env")        // load .env; skip already-set vars
//     let db = env_or("DB_URL", "sqlite://dev.db")
//     println("DB: {db}")
//   }
//
// .env format (subset of the de facto standard):
//   KEY=value
//   KEY="quoted value"
//   KEY='single quoted'
//   export KEY=value        # optional export keyword
//   # this is a comment
//
// Note: dotenv_load() must be called before get_env()/env_or() for the
// loaded values to be visible, because the Koka env cache is computed once
// on first access.
//
// This source file is part of the hica open source project
// Copyright (C) 2026 Claes Adamsson <claes.adamsson@gmail.com>
//
// See https://github.com/cladam/hica/blob/main/LICENSE for license information

// ---------------------------------------------------------------------------
// Parsing helpers
// ---------------------------------------------------------------------------

// Strip surrounding single or double quotes from a value string.
// Falls back to trimming whitespace if no quotes are present.
pub fun dotenv_strip_quotes(s: string) : string {
  let n = str_length(s)
  if n >= 2 && starts_with(s, "\"") && ends_with(s, "\"") { s[1:n-1] }
  else if n >= 2 && starts_with(s, "'") && ends_with(s, "'") { s[1:n-1] }
  else { trim(s) }
}

// Given a raw `KEY=VALUE` string and the position of `=`, return (key, value).
// Returns None if the key is empty.
pub fun dotenv_parse_kv(s: string, i: int) : maybe<(string, string)> {
  let key = trim(s[:i])
  if str_length(key) == 0 { None }
  else { Some((key, dotenv_strip_quotes(s[i+1:]))) }
}

// Parse one line of .env content into a (key, value) pair.
// Returns None for blank lines, comment lines, and malformed entries.
pub fun dotenv_parse_line(line: string) : maybe<(string, string)> {
  let trimmed = trim(line)
  if str_length(trimmed) == 0 { None }
  else if starts_with(trimmed, "#") { None }
  else {
    let s = if starts_with(trimmed, "export ") { trimmed[7:] } else { trimmed }
    match index_of(s, "=") {
      None => None,
      Some(i) => dotenv_parse_kv(s, i)
    }
  }
}

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

// Parse a multi-line .env format string into a list of (key, value) pairs.
// Blank lines and # comments are ignored.
pub fun dotenv_parse(content: string) : list<(string, string)> {
  fold(split(content, "\n"), [], (acc, line) => match dotenv_parse_line(line) {
    None => acc,
    Some(pair) => acc + [pair]
  })
}

// Apply a list of (key, value) pairs to the environment.
// Variables already set in the environment are NOT overwritten.
// Uses setenv(..., 0) at the OS level — never forces Koka's env cache.
pub fun dotenv_apply(pairs) {
  foreach(pairs, (p) => match p {
    (k, v) => set_env_nooverwrite(k, v)
  })
}

// Apply a list of (key, value) pairs to the environment, overwriting existing values.
pub fun dotenv_apply_override(pairs) {
  foreach(pairs, (p) => match p {
    (k, v) => set_env(k, v)
  })
}

// Load a .env file into the process environment.
// Variables already set in the environment are NOT overwritten (safe default).
// Silently ignores missing or unreadable files.
pub fun dotenv_load(path: string) {
  match read_file(path) {
    Ok(content) => dotenv_apply(dotenv_parse(content)),
    Err(_) => { }
  }
}

// Load a .env file, overwriting any existing environment variables.
// Silently ignores missing or unreadable files.
pub fun dotenv_load_override(path: string) {
  match read_file(path) {
    Ok(content) => dotenv_apply_override(dotenv_parse(content)),
    Err(_) => { }
  }
}
