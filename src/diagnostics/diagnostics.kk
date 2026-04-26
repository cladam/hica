/*
 * hica – diagnostics and error reporting
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
module diagnostics/diagnostics

import syntax/ast

pub type severity
  Error
  Warning
  Info

pub struct diagnostic
  severity : severity
  span     : span
  message  : string

pub fun diagnostic/show( d : diagnostic ) : string
  val sev = match d.severity
    Error   -> "error"
    Warning -> "warning"
    Info    -> "info"
  sev ++ " at " ++ d.span.start.show ++ "-" ++ d.span.end.show ++ ": " ++ d.message

// Compiler diagnostics effect
pub effect diag
  fun emit-diagnostic( d : diagnostic ) : ()

pub fun emit-error( sp : span, msg : string ) : diag ()
  emit-diagnostic(Diagnostic(Error, sp, msg))

pub fun emit-warning( sp : span, msg : string ) : diag ()
  emit-diagnostic(Diagnostic(Warning, sp, msg))

// Collect all diagnostics into a list
pub fun collect-diagnostics( action : () -> <diag|e> a ) : e (a, list<diagnostic>)
  var ds := []
  with handler
    fun emit-diagnostic(d) { ds := Cons(d, ds) }
  val result = action()
  (result, ds.reverse)
