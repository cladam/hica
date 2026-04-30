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
// Prelude: Koka stdlib functions known to the type checker
// ---------------------------------------------------------------------------

// Build the prelude environment with type signatures for Koka stdlib
// functions.  These are all monomorphic for now.  `show` is typed as
// `(int) -> string` which covers the most common case; other uses
// (e.g. `show(true)`) will get a type error from the checker but still
// compile correctly because Koka resolves the polymorphic `show`.
pub fun prelude-env() : type-env
  [ ("println", TFun([TString], TUnit)),
    ("show",    TFun([TInt], TString)),
    ("abs",     TFun([TInt], TInt)),
    ("min",     TFun([TInt, TInt], TInt)),
    ("max",     TFun([TInt, TInt], TInt)) ]
