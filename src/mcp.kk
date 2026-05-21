/*
 * hica – MCP (Model Context Protocol) server
 *
 * This source file is part of the hica open source project
 * Copyright (C) 2026 Claes Adamsson <claes.adamsson@gmail.com>
 *
 * See https://github.com/cladam/hica/blob/main/LICENSE for license information
 *
 * Provides an MCP-compatible stdio server that exposes hica tools
 * (check, test, run, eval) to AI coding agents. PoC stage...
 *
 * Activated via: hica --mcp (hidden flag, not shown in --help)
 *
 * Protocol: JSON-RPC 2.0 over stdio, newline-delimited messages.
 */
module mcp

import std/os/env
import std/os/path
import std/os/readline
import std/os/process

// ---------------------------------------------------------------------------
// JSON helpers (minimal, just enough for MCP protocol messages)
// ---------------------------------------------------------------------------

// Extract a string value for a given key from a flat JSON object.
// Handles: "key":"value" and "key": "value"
fun json-get-string( json : string, key : string ) : div string
  val needle = "\"" ++ key ++ "\""
  val idx = json.index-of(needle)
  if idx < 0 then ""
  else
    // Skip past key and find the colon, then the opening quote
    val after-key = json.slice.drop(idx + needle.count).string.trim
    if after-key.starts-with(":").bool then
      val after-colon = after-key.slice.drop(1).string.trim
      if after-colon.starts-with("\"").bool then
        val content = after-colon.slice.drop(1).string
        extract-until-quote(content)
      else ""
    else ""

// Extract characters until an unescaped closing quote
fun extract-until-quote( s : string ) : div string
  extract-until-quote-acc(s.list, [])

fun extract-until-quote-acc( cs : list<char>, acc : list<char> ) : div string
  match cs
    Nil -> acc.reverse.string
    Cons('"', _) -> acc.reverse.string
    Cons('\\', Cons(c, rest)) -> extract-until-quote-acc(rest, Cons(c, Cons('\\', acc)))
    Cons(c, rest) -> extract-until-quote-acc(rest, Cons(c, acc))

// Extract an integer value for a given key
fun json-get-int( json : string, key : string ) : div int
  val needle = "\"" ++ key ++ "\""
  val idx = json.index-of(needle)
  if idx < 0 then 0
  else
    val after-key = json.slice.drop(idx + needle.count).string.trim
    if after-key.starts-with(":").bool then
      val after-colon = after-key.slice.drop(1).string.trim
      parse-int-prefix(after-colon)
    else 0

fun parse-int-prefix( s : string ) : div int
  parse-int-prefix-acc(s.list, 0)

fun parse-int-prefix-acc( cs : list<char>, acc : int ) : div int
  match cs
    Cons(c, rest) | c >= '0' && c <= '9' ->
      parse-int-prefix-acc(rest, acc * 10 + (c - '0').int)
    _ -> acc

// Extract nested object as raw string for a given key
fun json-get-object( json : string, key : string ) : div string
  val needle = "\"" ++ key ++ "\""
  val idx = json.index-of(needle)
  if idx < 0 then "{}"
  else
    val after-key = json.slice.drop(idx + needle.count).string.trim
    if after-key.starts-with(":").bool then
      val after-colon = after-key.slice.drop(1).string.trim
      if after-colon.starts-with("{").bool then
        extract-braced(after-colon)
      else "{}"
    else "{}"

// Extract a balanced {...} substring
fun extract-braced( s : string ) : div string
  extract-braced-acc(s.list, [], 0)

fun extract-braced-acc( cs : list<char>, acc : list<char>, depth : int ) : div string
  match cs
    Nil -> acc.reverse.string
    Cons('{', rest) ->
      extract-braced-acc(rest, Cons('{', acc), depth + 1)
    Cons('}', rest) ->
      if depth == 1 then (Cons('}', acc)).reverse.string
      else extract-braced-acc(rest, Cons('}', acc), depth - 1)
    Cons('"', rest) ->
      // Skip string contents (handle escaped quotes)
      val (str-chars, remaining) = skip-json-string(rest)
      extract-braced-acc(remaining, str-chars ++ acc, depth)
    Cons(c, rest) ->
      extract-braced-acc(rest, Cons(c, acc), depth)

fun skip-json-string( cs : list<char> ) : div (list<char>, list<char>)
  skip-json-string-acc(cs, ['"'])

fun skip-json-string-acc( cs : list<char>, acc : list<char> ) : div (list<char>, list<char>)
  match cs
    Nil -> (acc, [])
    Cons('"', rest) -> (Cons('"', acc), rest)
    Cons('\\', Cons(c, rest)) -> skip-json-string-acc(rest, Cons(c, Cons('\\', acc)))
    Cons(c, rest) -> skip-json-string-acc(rest, Cons(c, acc))

// Escape a string for JSON output
fun json-escape( s : string ) : div string
  json-escape-acc(s.list, [])

fun json-escape-acc( cs : list<char>, acc : list<char> ) : div string
  match cs
    Nil -> acc.reverse.string
    Cons('"', rest)  -> json-escape-acc(rest, Cons('"', Cons('\\', acc)))
    Cons('\\', rest) -> json-escape-acc(rest, Cons('\\', Cons('\\', acc)))
    Cons('\n', rest) -> json-escape-acc(rest, Cons('n', Cons('\\', acc)))
    Cons('\r', rest) -> json-escape-acc(rest, Cons('r', Cons('\\', acc)))
    Cons('\t', rest) -> json-escape-acc(rest, Cons('t', Cons('\\', acc)))
    Cons(c, rest)    -> json-escape-acc(rest, Cons(c, acc))

// Simple index-of for strings (returns -1 if not found)
fun index-of( s : string, needle : string ) : div int
  index-of-loop(s, needle, 0)

fun index-of-loop( s : string, needle : string, idx : int ) : div int
  if s.count < needle.count then -1
  elif s.starts-with(needle).bool then idx
  else index-of-loop(s.slice.drop(1).string, needle, idx + 1)

// ---------------------------------------------------------------------------
// MCP Protocol implementation
// ---------------------------------------------------------------------------

val mcp-server-name = "hica"
val mcp-server-version = "0.1.0"

// The tools we expose
fun tools-json() : string
  "[" ++
    "{\"name\":\"hica_check\",\"description\":\"Type-check a .hc file and return diagnostics (errors, warnings, effect summary)\"," ++
     "\"inputSchema\":{\"type\":\"object\",\"properties\":{\"file\":{\"type\":\"string\",\"description\":\"Path to the .hc file to check\"}},\"required\":[\"file\"]}}," ++
    "{\"name\":\"hica_test\",\"description\":\"Run inline tests in a .hc file and return pass/fail results\"," ++
     "\"inputSchema\":{\"type\":\"object\",\"properties\":{\"file\":{\"type\":\"string\",\"description\":\"Path to the .hc file containing tests\"}},\"required\":[\"file\"]}}," ++
    "{\"name\":\"hica_run\",\"description\":\"Compile and run a .hc file, returning its stdout/stderr output\"," ++
     "\"inputSchema\":{\"type\":\"object\",\"properties\":{\"file\":{\"type\":\"string\",\"description\":\"Path to the .hc file to run\"},\"args\":{\"type\":\"string\",\"description\":\"Optional command-line arguments (space-separated)\"}},\"required\":[\"file\"]}}," ++
    "{\"name\":\"hica_eval\",\"description\":\"Evaluate a hica expression and return the result\"," ++
     "\"inputSchema\":{\"type\":\"object\",\"properties\":{\"expression\":{\"type\":\"string\",\"description\":\"A hica expression to evaluate\"}},\"required\":[\"expression\"]}}" ++
  "]"

// Get the path to the current hica binary
fun hica-bin() : io string
  match get-env-value("_")
    Nothing -> "hica"
    Just("") -> "hica"
    Just(v)  -> v

// Run a hica command and capture output
fun run-hica-cmd( args : string ) : io string
  val bin = hica-bin()
  val cmd = bin ++ " " ++ args ++ " 2>&1"
  match run-system-read(cmd)
    Ok(output) -> output
    Error(_)   -> "error: failed to execute command"

// Handle a tools/call request
fun handle-tool-call( name : string, arguments : string ) : io string
  match name
    "hica_check" ->
      val file = json-get-string(arguments, "file")
      if file == "" then "error: missing 'file' argument"
      else run-hica-cmd("check " ++ file)
    "hica_test" ->
      val file = json-get-string(arguments, "file")
      if file == "" then "error: missing 'file' argument"
      else run-hica-cmd("test " ++ file)
    "hica_run" ->
      val file = json-get-string(arguments, "file")
      val args = json-get-string(arguments, "args")
      if file == "" then "error: missing 'file' argument"
      elif args == "" then run-hica-cmd("run " ++ file)
      else run-hica-cmd("run " ++ file ++ " -- " ++ args)
    "hica_eval" ->
      val expr = json-get-string(arguments, "expression")
      if expr == "" then "error: missing 'expression' argument"
      else
        val bin = hica-bin()
        val cmd = "echo " ++ show-shell(expr) ++ " | " ++ bin ++ " repl 2>&1"
        match run-system-read(cmd)
          Ok(output) -> clean-repl-output(output)
          Error(_)   -> "error: failed to evaluate expression"
    _ -> "error: unknown tool '" ++ name ++ "'"

// Shell-escape a string for echo
fun show-shell( s : string ) : div string
  "'" ++ s.mcp-replace-all("'", "'\\''") ++ "'"

// Strip REPL prompt/banner from output
fun clean-repl-output( output : string ) : string
  val lines = output.lines
  val filtered = lines.filter(fn(l)
    !l.starts-with("hica=>").bool && !l.starts-with("Welcome to").bool && l != "Bye!" && l.trim != ""
  )
  filtered.join("\n")

// Replace all occurrences of a substring
fun mcp-replace-all( s : string, old : string, new_ : string ) : div string
  if old == "" then s
  else
    val idx = s.index-of(old)
    if idx < 0 then s
    else
      val before = s.slice.take(idx).string
      val after  = s.slice.drop(idx + old.count).string
      before ++ new_ ++ after.mcp-replace-all(old, new_)

// ---------------------------------------------------------------------------
// JSON-RPC response builders
// ---------------------------------------------------------------------------

fun rpc-result( id : int, result : string ) : string
  "{\"jsonrpc\":\"2.0\",\"id\":" ++ id.show ++ ",\"result\":" ++ result ++ "}"

fun rpc-error( id : int, code : int, message : string ) : div string
  "{\"jsonrpc\":\"2.0\",\"id\":" ++ id.show ++ ",\"error\":{\"code\":" ++ code.show ++ ",\"message\":\"" ++ json-escape(message) ++ "\"}}"

// ---------------------------------------------------------------------------
// Message dispatch
// ---------------------------------------------------------------------------

fun handle-message( msg : string ) : io string
  val method = json-get-string(msg, "method")
  val id     = json-get-int(msg, "id")
  match method
    "initialize" ->
      val result = "{\"protocolVersion\":\"2024-11-05\"," ++
                    "\"capabilities\":{\"tools\":{}}," ++
                    "\"serverInfo\":{\"name\":\"" ++ mcp-server-name ++ "\",\"version\":\"" ++ mcp-server-version ++ "\"}}"
      rpc-result(id, result)
    "notifications/initialized" -> "" // No response needed for notifications
    "tools/list" ->
      val result = "{\"tools\":" ++ tools-json() ++ "}"
      rpc-result(id, result)
    "tools/call" ->
      val params = json-get-object(msg, "params")
      val name = json-get-string(params, "name")
      val arguments = json-get-object(params, "arguments")
      val output = handle-tool-call(name, arguments)
      val is-error = output.starts-with("error:").bool
      val content = "[{\"type\":\"text\",\"text\":\"" ++ json-escape(output) ++ "\"}]"
      val result = "{\"content\":" ++ content ++ ",\"isError\":" ++ (if is-error then "true" else "false") ++ "}"
      rpc-result(id, result)
    "ping" ->
      rpc-result(id, "{}")
    _ ->
      if id > 0 then
        rpc-error(id, -32601, "Method not found: " ++ method)
      else "" // Ignore unknown notifications

// ---------------------------------------------------------------------------
// Main server loop
// ---------------------------------------------------------------------------

pub fun mcp-serve() : io ()
  // Log to stderr so it doesn't interfere with the JSON-RPC protocol on stdout
  trace("hica mcp server started (protocol 2024-11-05)")
  mcp-loop()

fun mcp-loop() : io ()
  val result = try({ Just(readline()) }) fn(_exn) { Nothing }
  match result
    Nothing -> () // EOF — client disconnected
    Just(line) ->
      val trimmed = line.trim
      if trimmed == "" then mcp-loop() // skip empty lines
      else
        val response = handle-message(trimmed)
        if response != "" then
          println(response)
        mcp-loop()
