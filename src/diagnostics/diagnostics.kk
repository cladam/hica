// Hica — Diagnostics
// Effect-based error and warning reporting.
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
