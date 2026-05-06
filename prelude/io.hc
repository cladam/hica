// hica – I/O prelude
//
// Higher-level file I/O functions built on top of the extern primitives
// (read_file, write_file).
//
// This source file is part of the hica open source project
// Copyright (C) 2026 Claes Adamsson <claes.adamsson@gmail.com>
//
// See https://github.com/cladam/hica/blob/main/LICENSE for license information

// Read a file and split it into lines (throws on error)
fun read_lines(file_path: string) => read_file(file_path) |> unwrap |> lines

// Write a list of lines to a file (joins with newlines)
fun write_lines(file_path: string, xs: list<string>) => write_file(file_path, unlines(xs))
