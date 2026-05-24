// hica – I/O stdlib module
//
// File I/O helpers. Import with: import "std/io"
// Note: read_file and write_file (the underlying primitives) are always available.
//
// This source file is part of the hica open source project
// Copyright (C) 2026 Claes Adamsson <claes.adamsson@gmail.com>
//
// See https://github.com/cladam/hica/blob/main/LICENSE for license information

// Read a file and split it into lines (throws on error)
pub fun read_lines(file_path: string) => split(unwrap(read_file(file_path)), "\n")

// Write a list of lines to a file (joins with newlines); returns result<(), string>
pub fun write_lines(file_path: string, xs: list<string>) => write_file(file_path, join(xs, "\n"))

// Run a shell command and return its stdout split into lines, or Err on failure.
// Note: exec and exec_args are always available as primitives without importing std/io.
// exec_args joins args with spaces — it does NOT protect against shell injection.
pub fun exec_lines(cmd: string) : result<list<string>, string> =>
  match exec(cmd) {
    Ok(out) => Ok(split(trim(out), "\n")),
    Err(e)  => Err(e)
  }
