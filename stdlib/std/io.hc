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

// Write a list of lines to a file (joins with newlines)
pub fun write_lines(file_path: string, xs: list<string>) => write_file(file_path, join(xs, "\n"))
