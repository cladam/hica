/*
 * hica – diagnostics and error reporting
 * 
 * This source file is part of the hica open source project
 * Copyright (C) 2026 Claes Adamsson <claes.adamsson@gmail.com>
 *
 * See https://github.com/cladam/hica/blob/main/LICENSE for license information
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

// ---------------------------------------------------------------------------
// Structured error rendering with source snippets
// ---------------------------------------------------------------------------

// Compute (line, column) from a 0-based character offset.
// Both line and column are 1-based in the output.
fun offset-to-line-col( source : string, offset : int ) : (int, int)
  var line := 1
  var col  := 1
  var i    := 0
  val chars = source.list
  chars.foreach fn(c)
    if i < offset then
      if c == '\n' then
        line := line + 1
        col  := 1
      else
        col := col + 1
      i := i + 1
  (line, col)

// Extract the text of a single line (1-based line number).
fun get-source-line( source : string, line-num : int ) : string
  val lines = source.lines
  if line-num >= 1 && line-num <= lines.length then
    match lines.drop(line-num - 1)
      Cons(l, _) -> l
      Nil        -> ""
  else ""

// Render a diagnostic with source context.
// Format:
//   error[filename:3:5]: message
//    3 | let x = 42 + "hello"
//      |         ^^^^^^^^^^^^^
pub fun render-diagnostic( source : string, filename : string, d : diagnostic ) : string
  val sev = match d.severity
    Error   -> "error"
    Warning -> "warning"
    Info    -> "info"
  if d.span.start == 0 && d.span.end == 0 then
    sev ++ "[" ++ filename ++ "]: " ++ d.message
  else
    val (line, col) = offset-to-line-col(source, d.span.start)
    val src-line = get-source-line(source, line)
    val line-str = line.show
    val gutter = line-str ++ " | "
    val blank-gutter = repeat-char(' ', line-str.count) ++ " | "
    val underline-len = max(1, d.span.end - d.span.start)
    val carets = repeat-char(' ', col - 1) ++ repeat-char('^', underline-len)
    sev ++ "[" ++ filename ++ ":" ++ line.show ++ ":" ++ col.show ++ "]: " ++ d.message ++ "\n" ++
    " " ++ gutter ++ src-line ++ "\n" ++
    " " ++ blank-gutter ++ carets

fun repeat-char( c : char, n : int ) : string
  if n <= 0 then "" else list(1, n, fn(_) c).string
