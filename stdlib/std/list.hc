// hica – list prelude
//
// Higher-level list functions built on top of the list primitives
// (map, filter, fold, etc.).
//
// This source file is part of the hica open source project
// Copyright (C) 2026 Claes Adamsson <claes.adamsson@gmail.com>
//
// See https://github.com/cladam/hica/blob/main/LICENSE for license information

// --- Transformations ---

pub fun intersperse(xs, sep) => match xs {
  [] => [],
  [x] => [x],
  [x, ..rest] => [x, sep] + intersperse(rest, sep)
}

// --- Reductions ---

pub fun sum(xs) => fold(xs, 0, (a, b) => a + b)

pub fun product(xs) => fold(xs, 1, (a, b) => a * b)

pub fun scan(xs, init, f) => match xs {
  [] => [init],
  [x, ..rest] => [init] + scan(rest, f(init, x), f)
}

// --- Combining ---

pub fun zip_with(xs, ys, f) => map(zip(xs, ys), (pair) => f(pair.0, pair.1))

// --- Filtering ---

pub fun unique(xs: list<int>) : list<int> => fold(xs, [], (acc, x) => if x in acc { acc } else { acc + [x] })

// --- Splitting ---

pub fun chunks(xs, n) => match xs {
  [] => [],
  _ => [take(xs, n)] + chunks(drop(xs, n), n)
}
