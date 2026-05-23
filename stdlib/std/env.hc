// hica – environment variable helpers
//
// Convenience wrappers around the built-in get_env().
// Import with: import "std/env"
//
// This source file is part of the hica open source project
// Copyright (C) 2026 Claes Adamsson <claes.adamsson@gmail.com>
//
// See https://github.com/cladam/hica/blob/main/LICENSE for license information

// Get an environment variable, or return a default value if not set
pub fun env_or(key, default) => match get_env(key) {
  Some(v) => v,
  None => default
}

// Get a required environment variable.
// Prints an error to stderr and returns "" if the variable is not set.
pub fun env_require(key) => match get_env(key) {
  Some(v) => v,
  None => {
    eprintln("Error: environment variable '" + key + "' is required but not set")
    ""
  }
}

// Get an environment variable and parse it as an integer.
// Returns None if the variable is not set or is not a valid integer.
pub fun env_int(key) => match get_env(key) {
  Some(v) => parse_int(v),
  None => None
}
