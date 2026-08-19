/*
 * hica – source code formatter
 * 
 * This source file is part of the hica open source project
 * Copyright (C) 2026 Claes Adamsson <claes.adamsson@gmail.com>
 *
 * See https://github.com/cladam/hica/blob/main/LICENSE for license information
*/
module format/formatter

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

// Format a hica source string according to the style guide.
pub fun format-source( source : string ) : div string
  val raw-lines = source.lines
  val trimmed   = raw-lines.map(fn(l) l.strip-trailing)
  val spaced    = trimmed.map(fn(l) fix-spacing(l))
  val blanked   = normalise-blank-lines(spaced)
  val gapped    = insert-toplevel-blanks(blanked)
  val result    = gapped.join("\n")
  // Ensure file ends with a single trailing newline
  if result.list.last == Just('\n') then result
  else result ++ "\n"

// ---------------------------------------------------------------------------
// Trailing whitespace (rule 1)
// ---------------------------------------------------------------------------

fun strip-trailing( s : string ) : string
  val cs = s.list.reverse.drop-while(fn(c) c == ' ' || c == '\t')
  cs.reverse.string

// ---------------------------------------------------------------------------
// Spacing fixes (rules 2, 5, 6, 7, 8)
// ---------------------------------------------------------------------------

// Process a single line. We walk the character list building an output
// accumulator (reversed). This lets us inspect what was just emitted
// to handle "space before operator" correctly.
fun fix-spacing( line : string ) : div string
  val cs = line.list
  format-chars(cs, [], False).reverse.string

// acc is the reversed output so far.
// We can peek at acc.head to see the previous emitted character.
fun format-chars( cs : list<char>, acc : list<char>, in-str : bool ) : div list<char>
  match cs
    Nil -> acc
    // --- String literals: pass through ---
    Cons('"', rest) ->
      format-chars(rest, Cons('"', acc), !in-str)
    Cons('\\', Cons(c2, rest)) | in-str ->
      format-chars(rest, Cons(c2, Cons('\\', acc)), True)
    Cons(c, rest) | in-str ->
      format-chars(rest, Cons(c, acc), True)
    // --- Line comments: pass through rest unchanged ---
    Cons('/', Cons('/', rest)) ->
      // Ensure space before // if previous char isn't whitespace/start-of-line
      val acc' = match acc
        Cons(' ', _) -> acc
        Cons('\t', _) -> acc
        Nil -> acc
        _ -> Cons(' ', acc)
      rest.reverse ++ Cons('/', Cons('/', acc'))
    // --- Rule 7: commas — no space before, one space after ---
    Cons(' ', Cons(',', rest)) ->
      // Remove space before comma, then handle comma
      format-chars(Cons(',', rest), acc, False)
    Cons(',', rest) ->
      val rest' = rest.drop-while(fn(c) c == ' ')
      match rest'
        Nil -> Cons(',', acc)
        Cons(')', _) -> format-chars(rest', Cons(',', acc), False)
        Cons(']', _) -> format-chars(rest', Cons(',', acc), False)
        Cons('}', _) -> format-chars(rest', Cons(',', acc), False)
        _ -> format-chars(rest', Cons(' ', Cons(',', acc)), False)
    // --- Rule 8: colon — space after, not before (for param annotations) ---
    Cons(' ', Cons(':', Cons(':', rest))) ->
      // :: — leave spaces as-is
      format-chars(rest, Cons(':', Cons(':', Cons(' ', acc))), False)
    Cons(' ', Cons(':', rest)) ->
      // Space before colon: remove for param annotations (after ident),
      // but keep for return type annotations (after ')')
      match acc
        Cons(')', _) ->
          // Return type: `) : type` — keep the space
          val rest' = rest.drop-while(fn(c) c == ' ')
          match rest'
            Nil -> Cons(':', Cons(' ', acc))
            _   -> format-chars(rest', Cons(' ', Cons(':', Cons(' ', acc))), False)
        _ ->
          // Param annotation: `x : int` → `x: int` — remove space before
          format-chars(Cons(':', rest), acc, False)
    Cons(':', rest) ->
      val rest' = rest.drop-while(fn(c) c == ' ')
      match rest'
        Nil -> Cons(':', acc)
        Cons(':', _) -> format-chars(rest', Cons(':', acc), False) // :: operator
        _ ->
          // Don't add space in slice context: [1:3], [:2], [3:]
          // Don't add space in empty map literal: {:}
          val in-slice = match acc
            Cons('[', _) -> True
            Cons(c, _) | c.is-digit -> True
            _ -> False
          val before-close-brace = match rest'
            Cons('}', _) -> True
            _ -> False
          if in-slice || before-close-brace then format-chars(rest', Cons(':', acc), False)
          else format-chars(rest', Cons(' ', Cons(':', acc)), False)
    // --- Rule 5: no space inside brackets ---
    Cons('(', rest) ->
      val rest' = rest.drop-while(fn(c) c == ' ')
      format-chars(rest', Cons('(', acc), False)
    Cons('[', rest) ->
      val rest' = rest.drop-while(fn(c) c == ' ')
      format-chars(rest', Cons('[', acc), False)
    // Spaces before closing brackets — collapse to zero (not braces)
    // Only strip when there is non-whitespace content before on this line,
    // otherwise these spaces are indentation.
    Cons(' ', rest) | acc.has-nonspace && rest.drop-while(fn(c) c == ' ').is-close-paren-or-bracket ->
      format-chars(rest.drop-while(fn(c) c == ' '), acc, False)
    // --- Rule 2: space around operators ---
    // Multi-char operators first (must come before single-char)
    Cons('=', Cons('=', rest)) -> emit-op(acc, ['=', '='], rest)
    Cons('!', Cons('=', rest)) -> emit-op(acc, ['!', '='], rest)
    Cons('<', Cons('=', rest)) -> emit-op(acc, ['<', '='], rest)
    Cons('<', Cons('-', rest)) -> emit-op(acc, ['<', '-'], rest)  // <- effects bind
    Cons('>', Cons('=', rest)) -> emit-op(acc, ['>', '='], rest)
    Cons('&', Cons('&', rest)) -> emit-op(acc, ['&', '&'], rest)
    Cons('|', Cons('|', rest)) -> emit-op(acc, ['|', '|'], rest)
    Cons('|', Cons('>', rest)) -> emit-op(acc, ['|', '>'], rest)
    Cons('=', Cons('>', rest)) -> emit-op(acc, ['=', '>'], rest)
    // Single = (assignment) — space around, but not after . (field access .. or ..=)
    Cons('=', rest) ->
      match acc
        Cons('.', _) -> format-chars(rest, Cons('=', acc), False) // ..= range — no spacing
        _ -> emit-op(acc, ['='], rest)
    // + — space around
    Cons('+', rest) -> emit-op(acc, ['+'], rest)
    // - binary/unary: binary after alnum, _, ), ] — unary otherwise
    Cons('-', Cons('>', rest)) ->
      // -> type annotation arrow: pass through without spacing
      format-chars(rest, Cons('>', Cons('-', acc)), False)
    Cons('-', rest) ->
      match acc.prev-non-space
        Just(c) | c.is-alpha || c.is-digit || c == '_' || c == ')' || c == ']' ->
          emit-op(acc, ['-'], rest)
        _ ->
          format-chars(rest, Cons('-', acc), False)
    // * — space around
    Cons('*', rest) -> emit-op(acc, ['*'], rest)
    // / — but not // (comment handled earlier)
    Cons('/', rest) -> emit-op(acc, ['/'], rest)
    // % — space around
    Cons('%', rest) -> emit-op(acc, ['%'], rest)
    // --- Rule 6: no space before function-call parens ---
    // Space before ( — remove if previous is identifier char, but not keywords
    Cons(' ', Cons('(', rest)) ->
      match acc
        Cons(prev, _) | prev.is-alpha || prev.is-digit || prev == '_' || prev == ')' || prev == ']' ->
          if acc.acc-keyword then
            // Keep space after keywords: let (x, y), if (cond), etc.
            val rest' = rest.drop-while(fn(c) c == ' ')
            format-chars(rest', Cons('(', Cons(' ', acc)), False)
          else
            val rest' = rest.drop-while(fn(c) c == ' ')
            format-chars(rest', Cons('(', acc), False)
        _ ->
          val rest' = rest.drop-while(fn(c) c == ' ')
          format-chars(rest', Cons('(', Cons(' ', acc)), False)
    // --- Default ---
    Cons(c, rest) ->
      format-chars(rest, Cons(c, acc), False)

// Emit an operator with exactly one space before and after.
// acc is reversed output, op is the operator chars, rest is remaining input.
fun emit-op( acc : list<char>, op : list<char>, rest : list<char> ) : div list<char>
  // Ensure space before (strip trailing spaces from acc, then add one)
  val acc' = match acc
    Cons(' ', _) -> acc  // already have space
    Nil -> acc           // start of line — no space needed
    _ -> Cons(' ', acc)
  // Add operator chars (reversed onto acc)
  val acc'' = op.foldl(acc', fn(a, c) Cons(c, a))
  // Ensure space after (strip leading spaces from rest)
  val rest' = rest.drop-while(fn(c) c == ' ')
  match rest'
    Nil -> acc''
    _   -> format-chars(rest', Cons(' ', acc''), False)

// ---------------------------------------------------------------------------
// Blank line normalisation (rule 3)
// ---------------------------------------------------------------------------

// Ensure exactly one blank line between top-level definitions,
// and no more than one consecutive blank line anywhere.
fun normalise-blank-lines( lines : list<string> ) : div list<string>
  collapse-blanks(lines, False)

// Insert a blank line before top-level definitions that lack one.
fun insert-toplevel-blanks( lines : list<string> ) : div list<string>
  insert-blanks-go(lines, Nothing)

fun insert-blanks-go( lines : list<string>, prev : maybe<string> ) : div list<string>
  match lines
    Nil -> []
    Cons(line, rest) ->
      val needs-blank = match prev
        Nothing -> False
        Just(p) ->
          line.is-toplevel-def
          && p.trim-left-ws != ""          // previous line is not blank
          && !p.trim-left-ws.starts-with("//").bool  // not a comment line
      if needs-blank then
        Cons("", Cons(line, insert-blanks-go(rest, Just(line))))
      else
        Cons(line, insert-blanks-go(rest, Just(line)))

fun is-toplevel-def( line : string ) : bool
  line.starts-with("fun ").bool
  || line.starts-with("pub ").bool
  || line.starts-with("struct ").bool
  || line.starts-with("type ").bool
  || line.starts-with("test \"").bool
  || line.starts-with("effect ").bool
  || line.starts-with("extern ").bool
  || line.starts-with("actor ").bool

fun collapse-blanks( lines : list<string>, prev-blank : bool ) : div list<string>
  match lines
    Nil -> []
    Cons(line, rest) ->
      val is-blank = line.trim-left-ws == ""
      if is-blank && prev-blank then
        // Skip consecutive blank lines
        collapse-blanks(rest, True)
      else
        Cons(line, collapse-blanks(rest, is-blank))

fun trim-left-ws( s : string ) : string
  val cs = s.list.drop-while(fn(c) c == ' ' || c == '\t')
  cs.string

fun is-close-bracket( cs : list<char> ) : bool
  match cs
    Cons(')', _) -> True
    Cons(']', _) -> True
    Cons('}', _) -> True
    _            -> False

fun is-close-paren-or-bracket( cs : list<char> ) : bool
  match cs
    Cons(')', _) -> True
    Cons(']', _) -> True
    _            -> False

// Check if the accumulator contains at least one non-whitespace character.
fun has-nonspace( acc : list<char> ) : bool
  acc.any(fn(c) c != ' ' && c != '\t')

// Return the previous non-space character from the reversed accumulator.
fun prev-non-space( acc : list<char> ) : maybe<char>
  match acc
    Nil -> Nothing
    Cons(' ', rest) -> prev-non-space(rest)
    Cons('\t', rest) -> prev-non-space(rest)
    Cons(c, _) -> Just(c)

// Extract the preceding identifier word from the reversed accumulator
// and check if it's a language keyword that should keep space before '('.
fun acc-keyword( acc : list<char> ) : bool
  val word = acc.take-while(fn(c) c.is-alpha || c.is-digit || c == '_').reverse.string
  match word
    "let"    -> True
    "val"    -> True
    "var"    -> True
    "if"     -> True
    "else"   -> True
    "for"    -> True
    "while"  -> True
    "match"  -> True
    "fun"    -> True
    "return" -> True
    "import" -> True
    "extern" -> True
    "pub"    -> True
    "from"   -> True
    "in"     -> True
    "enum"   -> True
    "struct" -> True
    "type"   -> True
    "test"   -> True
    "handle" -> True
    "effect" -> True
    "actor"  -> True
    "spawn"  -> True
    "as"     -> True
    "with"   -> True
    _        -> False
