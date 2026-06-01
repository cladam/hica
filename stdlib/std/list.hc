// hica – list prelude
//
// Higher-level list functions built on top of the list primitives
// (map, filter, fold, etc.).
//
// This source file is part of the hica open source project
// Copyright (C) 2026 Claes Adamsson <claes.adamsson@gmail.com>
//
// See https://github.com/cladam/hica/blob/main/LICENSE for license information

// --- Generation ---

// Range [lo, hi) — lo inclusive, hi exclusive (Python-style)
pub fun range(lo: int, hi: int) : list<int> =>
  if lo >= hi { [] }
  else { [lo] + range(lo + 1, hi) }

// Range [lo, hi] — both ends inclusive
pub fun range_inc(lo: int, hi: int) : list<int> =>
  if lo > hi { [] }
  else { [lo] + range_inc(lo + 1, hi) }

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

// --- Head/Tail helpers ---

// First element or a default value (avoids unwrapping maybe after length check)
pub fun head_or(xs, default) => match xs {
  [] => default,
  [x, ..] => x
}

// --- Prefix/Suffix predicates ---

// Take elements from the front while predicate holds
pub fun take_while(xs, pred) => match xs {
  [] => [],
  [x, ..rest] => if pred(x) { [x] + take_while(rest, pred) } else { [] }
}

// Drop elements from the front while predicate holds; return the rest
pub fun drop_while(xs, pred) => match xs {
  [] => [],
  [x, ..rest] => if pred(x) { drop_while(rest, pred) } else { xs }
}

// --- Counting ---

// Count elements matching predicate
pub fun count(xs, pred) => fold(xs, 0, (acc, x) => if pred(x) { acc + 1 } else { acc })

// --- Grouping ---

// Internal helper: insert item into existing (key, group) pair list
pub fun group_by_insert(pairs, key: string, item) => match pairs {
  [] => [(key, [item])],
  [p, ..rest] => match p {
    (k, vs) => if k == key { [(k, vs + [item])] + rest } else { [(k, vs)] + group_by_insert(rest, key, item) }
  }
}

// Group elements by key function f(x) -> string; returns list of (key, group) pairs
pub fun group_by(xs, f) => fold(xs, [], (acc, x) => group_by_insert(acc, f(x), x))

// --- Min/Max by key ---

// Internal helpers (pub required for stdlib modules)
pub fun pick_min(a, b, ka: int, kb: int) => if ka < kb { a } else { b }
pub fun pick_max(a, b, ka: int, kb: int) => if ka > kb { a } else { b }

// Element with the smallest int key (None on empty list)
pub fun min_by(xs, f) => match xs {
  [] => None,
  [first, ..rest] => Some(fold(rest, first, (best, x) => pick_min(x, best, f(x), f(best))))
}

// Element with the largest int key (None on empty list)
pub fun max_by(xs, f) => match xs {
  [] => None,
  [first, ..rest] => Some(fold(rest, first, (best, x) => pick_max(x, best, f(x), f(best))))
}
