/*
 * hica – prelude: built-in type environment
 * 
 * This source file is part of the hica open source project
 * Copyright (C) 2026 Claes Adamsson <claes.adamsson@gmail.com>
 *
 * See https://github.com/cladam/hica/blob/main/LICENSE for license information
*/
module semantics/prelude

import syntax/ast

// ---------------------------------------------------------------------------
// Extern environment: Koka stdlib functions that cannot be written in Hica
// ---------------------------------------------------------------------------

// Type signatures for Koka built-ins.  Everything that *can* be written
// in Hica lives in prelude/*.hc instead.  `println` uses a TVar param
// so it accepts any type — the codegen auto-wraps non-string arguments
// with `.show`.  `show` likewise uses a TVar so `show(true)` works.
// TVars in extern signatures are freshened on each lookup (see
// checker.kk `env/lookup`).
pub fun extern-env() : type-env
  [ ("println", TFun([TVar("_a")], TUnit)),
    ("print",   TFun([TVar("_a")], TUnit)),
    ("show",    TFun([TVar("_a")], TString)),
    ("map",     TFun([TList(TVar("_a")), TFun([TVar("_a")], TVar("_b"))], TList(TVar("_b")))),
    ("filter",  TFun([TList(TVar("_a")), TFun([TVar("_a")], TBool)], TList(TVar("_a")))),
    ("fold",    TFun([TList(TVar("_a")), TVar("_b"), TFun([TVar("_b"), TVar("_a")], TVar("_b"))], TVar("_b"))),
    ("length",  TFun([TList(TVar("_a"))], TInt)),
    ("reverse", TFun([TList(TVar("_a"))], TList(TVar("_a")))),
    ("take",    TFun([TList(TVar("_a")), TInt], TList(TVar("_a")))),
    ("drop",    TFun([TList(TVar("_a")), TInt], TList(TVar("_a")))),
    ("zip",     TFun([TList(TVar("_a")), TList(TVar("_b"))], TList(TTuple([TVar("_a"), TVar("_b")])))),
    ("concat",  TFun([TList(TList(TVar("_a")))], TList(TVar("_a")))),
    ("any",     TFun([TList(TVar("_a")), TFun([TVar("_a")], TBool)], TBool)),
    ("all",     TFun([TList(TVar("_a")), TFun([TVar("_a")], TBool)], TBool)),
    ("find",    TFun([TList(TVar("_a")), TFun([TVar("_a")], TBool)], TMaybe(TVar("_a")))),
    ("foreach", TFun([TList(TVar("_a")), TFun([TVar("_a")], TUnit)], TUnit)),
    ("enumerate", TFun([TList(TVar("_a"))], TList(TTuple([TInt, TVar("_a")])))),
    ("cons",      TFun([TVar("_a"), TList(TVar("_a"))], TList(TVar("_a")))),
    // String utilities — backed by Koka std/core/string
    ("str_length",  TFun([TString], TInt)),
    ("contains",    TFun([TString, TString], TBool)),
    ("str_contains", TFun([TString, TString], TBool)),
    ("starts_with", TFun([TString, TString], TBool)),
    ("ends_with",   TFun([TString, TString], TBool)),
    ("trim",        TFun([TString], TString)),
    ("trim_start",  TFun([TString], TString)),
    ("trim_end",    TFun([TString], TString)),
    ("to_upper",    TFun([TString], TString)),
    ("to_lower",    TFun([TString], TString)),
    ("split",       TFun([TString, TString], TList(TString))),
    ("replace",     TFun([TString, TString, TString], TString)),
    ("join",        TFun([TList(TString), TString], TString)),
    ("index_of",    TFun([TString, TString], TMaybe(TInt))),
    ("to_int",      TFun([TString], TInt)),
    ("parse_int",   TFun([TString], TMaybe(TInt))),
    ("parse_float", TFun([TString], TMaybe(TFloat))),

    // Environment helpers
    ("get_args",    TFun([], TList(TString))),
    ("get_env",     TFun([TString], TMaybe(TString))),
    ("set_env",     TFun([TString, TString], TUnit)),
    ("set_env_nooverwrite", TFun([TString, TString], TUnit)),
    ("eprintln",    TFun([TVar("_a")], TUnit)),
    ("exit",        TFun([TInt], TUnit)),

    // Raw terminal I/O — backed by term_raw.kk C FFI
    ("read_key",     TFun([], TInt)),
    ("term_cols",    TFun([], TInt)),
    ("term_rows",    TFun([], TInt)),
    ("flush_stdout", TFun([], TUnit)),

    // User input
    ("input",       TFun([TString], TString)),

    // File I/O
    ("read_file",   TFun([TString], TResult(TString, TString))),
    ("write_file",  TFun([TString, TString], TResult(TUnit, TString))),
    ("exec",        TFun([TString], TResult(TString, TString))),
    ("exec_args",   TFun([TString, TList(TString)], TResult(TString, TString))),

    // Random numbers
    ("random",       TFun([TInt, TInt], TInt)),
    ("random_float", TFun([], TFloat)),

    // System clock — backed by Koka std/time
    ("now_unix",    TFun([], TInt)),
    ("now_iso",     TFun([], TString)),
    ("unix_to_iso", TFun([TInt], TString)),

    // Formatting
    ("show_fixed", TFun([TFloat, TInt], TString)),

    // Maybe combinators
    ("map_maybe",       TFun([TMaybe(TVar("_a")), TFun([TVar("_a")], TVar("_b"))], TMaybe(TVar("_b")))),
    ("and_then",        TFun([TMaybe(TVar("_a")), TFun([TVar("_a")], TMaybe(TVar("_b")))], TMaybe(TVar("_b")))),
    ("unwrap_maybe",    TFun([TMaybe(TVar("_a"))], TVar("_a"))),
    ("unwrap_maybe_or", TFun([TMaybe(TVar("_a")), TVar("_a")], TVar("_a"))),
    ("is_some",         TFun([TMaybe(TVar("_a"))], TBool)),
    ("is_none",         TFun([TMaybe(TVar("_a"))], TBool)),

    // Result combinators
    ("unwrap",          TFun([TResult(TVar("_a"), TVar("_b"))], TVar("_a"))),
    ("unwrap_or",       TFun([TResult(TVar("_a"), TVar("_b")), TVar("_a")], TVar("_a"))),
    ("map_result",      TFun([TResult(TVar("_a"), TVar("_b")), TFun([TVar("_a")], TVar("_c"))], TResult(TVar("_c"), TVar("_b")))),
    ("map_err",         TFun([TResult(TVar("_a"), TVar("_b")), TFun([TVar("_b")], TVar("_c"))], TResult(TVar("_a"), TVar("_c")))),
    ("and_then_result", TFun([TResult(TVar("_a"), TVar("_b")), TFun([TVar("_a")], TResult(TVar("_c"), TVar("_b")))], TResult(TVar("_c"), TVar("_b")))),
    ("is_ok",           TFun([TResult(TVar("_a"), TVar("_b"))], TBool)),
    ("is_err",          TFun([TResult(TVar("_a"), TVar("_b"))], TBool)),

    // Bitwise operations — backed by Koka std/num/int32
    ("bit_and",  TFun([TInt, TInt], TInt)),
    ("bit_or",   TFun([TInt, TInt], TInt)),
    ("bit_xor",  TFun([TInt, TInt], TInt)),
    ("bit_not",  TFun([TInt], TInt)),
    ("bit_shl",  TFun([TInt, TInt], TInt)),
    ("bit_shr",  TFun([TInt, TInt], TInt)),

    // Test assertions
    ("assert",        TFun([TBool], TUnit)),
    ("assert_eq",     TFun([TVar("_a"), TVar("_a")], TUnit)),
    ("assert_ne",     TFun([TVar("_a"), TVar("_a")], TUnit)),
    ("assert_true",   TFun([TBool], TUnit)),
    ("assert_false",  TFun([TBool], TUnit)),
    ("assert_contains", TFun([TList(TVar("_a")), TVar("_a")], TUnit)),
    ("assert_empty",  TFun([TList(TVar("_a"))], TUnit)),
    ("assert_not_empty", TFun([TList(TVar("_a"))], TUnit)),

    // Map operations — maps are list<(k, v)>
    ("map_get",          TFun([TList(TTuple([TVar("_k"), TVar("_v")])), TVar("_k")], TMaybe(TVar("_v")))),
    ("map_set",          TFun([TList(TTuple([TVar("_k"), TVar("_v")])), TVar("_k"), TVar("_v")], TList(TTuple([TVar("_k"), TVar("_v")])))),
    ("map_remove",       TFun([TList(TTuple([TVar("_k"), TVar("_v")])), TVar("_k")], TList(TTuple([TVar("_k"), TVar("_v")])))),
    ("map_keys",         TFun([TList(TTuple([TVar("_k"), TVar("_v")]))], TList(TVar("_k")))),
    ("map_values",       TFun([TList(TTuple([TVar("_k"), TVar("_v")]))], TList(TVar("_v")))),
    ("map_contains_key", TFun([TList(TTuple([TVar("_k"), TVar("_v")])), TVar("_k")], TBool)),
    ("map_size",         TFun([TList(TTuple([TVar("_k"), TVar("_v")]))], TInt)),

    // Extended list operations — backed by Koka std/core/list
    ("head",      TFun([TList(TVar("_a"))], TMaybe(TVar("_a")))),
    ("tail",      TFun([TList(TVar("_a"))], TList(TVar("_a")))),
    ("last",      TFun([TList(TVar("_a"))], TMaybe(TVar("_a")))),
    ("flat_map",  TFun([TList(TVar("_a")), TFun([TVar("_a")], TList(TVar("_b")))], TList(TVar("_b")))),
    ("sort_by",   TFun([TList(TVar("_a")), TFun([TVar("_a"), TVar("_a")], TBool)], TList(TVar("_a")))),

    // Float math — backed by Koka std/num/float64
    ("sqrt",      TFun([TFloat], TFloat)),
    ("floor",     TFun([TFloat], TInt)),
    ("ceil",      TFun([TFloat], TInt)),
    ("round",     TFun([TFloat], TInt)),
    ("to_float",  TFun([TInt], TFloat)),

    // Char/string conversions
    ("chars",           TFun([TString], TList(TChar))),
    ("from_chars",      TFun([TList(TChar)], TString)),
    ("chr",             TFun([TInt], TChar)),
    ("ord",             TFun([TChar], TInt)),
    ("char_to_string",  TFun([TChar], TString)) ]
