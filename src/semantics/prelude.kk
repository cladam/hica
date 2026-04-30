/*
 * hica – prelude: built-in type environment
 * Copyright (C) 2026 Claes Adamsson <claes.adamsson@gmail.com>
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE 
 * SOFTWARE.
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
    ("foreach", TFun([TList(TVar("_a")), TFun([TVar("_a")], TUnit)], TUnit)) ]
