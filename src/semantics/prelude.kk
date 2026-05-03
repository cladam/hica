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
    ("eprintln",    TFun([TVar("_a")], TUnit)) ]
