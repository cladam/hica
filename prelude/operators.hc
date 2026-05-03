// hica – operator prelude
//
// Operators as first-class functions, inspired by Python's operator module.
// Pass these to map, filter, fold, etc. instead of writing lambdas.
//
//   fold(xs, 0, add)       // instead of fold(xs, 0, fun(a, b) => a + b)
//   filter(xs, is_positive) // instead of filter(xs, fun(n) => n > 0)
//
// This source file is part of the hica open source project
// Copyright (C) 2026 Claes Adamsson <claes.adamsson@gmail.com>
//
// See https://github.com/cladam/hica/blob/main/LICENSE for license information

// --- Arithmetic ---

fun add(a, b) => a + b

fun sub(a, b) => a - b

fun mul(a, b) => a * b

fun div(a, b) => a / b

fun mod(a, b) => a % b

fun neg(n) => -n

// --- Comparison ---

fun lt(a, b) => a < b

fun le(a, b) => a <= b

fun gt(a, b) => a > b

fun ge(a, b) => a >= b

// --- Logical ---

fun not_(b) => !b

fun and_(a, b) => a && b

fun or_(a, b) => a || b

// --- Predicates ---

fun is_positive(n) => n > 0

fun is_negative(n) => n < 0

fun is_zero(n) => n == 0

fun is_even(n) => n % 2 == 0

fun is_odd(n) => n % 2 != 0

// --- Utility ---

fun identity(x) => x

fun square(n) => n * n
