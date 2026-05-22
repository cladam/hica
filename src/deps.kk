/*
 * hica – dependency management
 * 
 * This source file is part of the hica open source project
 * Copyright (C) 2026 Claes Adamsson <claes.adamsson@gmail.com>
 *
 * See https://github.com/cladam/hica/blob/main/LICENSE for license information
*/
module deps

import std/os/env
import std/os/dir
import std/os/file
import std/os/path
import std/os/process

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

pub struct dep-spec
  name : string
  source : dep-source

pub type dep-source
  GitDep( url : string, ref-tag : string )
  PathDep( dep-path : string )
  RegistryDep( version : string )  // Phase 3: pkg.hica.dev registry (not yet implemented)

// Format a dep-spec as a hica.hml dependency line
pub fun format-dep( d : dep-spec ) : string
  val value = match d.source
    GitDep(url, tag)     -> url ++ "@" ++ tag
    PathDep(p)           -> "path:" ++ p
    RegistryDep(version) -> version
  "    " ++ d.name ++ ": \"" ++ value ++ "\""

// ---------------------------------------------------------------------------
// Parse @dependencies from hml content
// ---------------------------------------------------------------------------

// Parse the @dependencies block from hica.hml content.
// Supported formats:
//   name: "github.com/owner/repo@tag"   (git dependency)
//   name: "github.com/owner/repo"       (git, defaults to "main" branch)
//   name: "path:../local-dir"           (local path dependency)
pub fun parse-deps-section( content : string ) : div list<dep-spec>
  val all-lines = content.lines
  var in-deps := False
  var result : list<dep-spec> := []
  all-lines.foreach fn(line)
    val trimmed = line.trim
    if trimmed.starts-with("@dependencies").bool then
      in-deps := True
    elif in-deps && trimmed == "}" then
      in-deps := False
    elif in-deps && !trimmed.is-empty && !trimmed.starts-with("//").bool && trimmed != "{" then
      match parse-dep-line(trimmed)
        Just(dep) -> result := Cons(dep, result)
        Nothing   -> ()
  result.reverse

fun parse-dep-line( line : string ) : div maybe<dep-spec>
  val parts = line.split(":")
  match parts
    Cons(key, rest) ->
      if rest.is-nil then Nothing
      else
        val name = key.trim
        val raw-value = rest.join(":").trim
        val value = dep-unquote(raw-value)
        if name.is-empty || value.is-empty then Nothing
        elif value.starts-with("path:").bool then
          val p = value.slice.sslice/drop(5).string.trim
          Just(Dep-spec(name, PathDep(p)))
        else
          val at-parts = value.split("@")
          match at-parts
            Cons(url, Cons(tag, _)) ->
              Just(Dep-spec(name, GitDep(url.trim, tag.trim)))
            _ ->
              Just(Dep-spec(name, GitDep(value, "main")))
    _ -> Nothing

fun dep-unquote( s : string ) : string
  if s.count >= 2 && s.starts-with("\"").bool && s.ends-with("\"").bool then
    s.slice.sslice/drop(1).sslice/extend(0 - 1).string
  else s

// ---------------------------------------------------------------------------
// Cache
// ---------------------------------------------------------------------------

pub fun hica-cache-dir() : io path
  homedir() / ".hica".path / "cache".path

// ---------------------------------------------------------------------------
// Fetch
// ---------------------------------------------------------------------------

// Fetch all dependencies and return their local include paths.
pub fun fetch-all-deps( dep-list : list<dep-spec>, base-dir : path ) : io list<string>
  dep-list.map(fn(d)
    match fetch-dep(d, base-dir)
      Just(p) -> [p.show]
      Nothing -> []
  ).concat

// Fetch a single dependency. Returns the local path on success.
pub fun fetch-dep( dep : dep-spec, base-dir : path ) : io maybe<path>
  match dep.source
    GitDep(url, tag) -> fetch-git(dep.name, url, tag)
    RegistryDep(_) ->
      println("error: registry dependencies not yet implemented")
      Nothing
    PathDep(p) ->
      val resolved = base-dir / p.path
      if !is-directory(resolved) then
        println("error: dependency '" ++ dep.name ++ "': path not found: " ++ resolved.show)
        Nothing
      else Just(resolved)

// Reject strings containing shell metacharacters to prevent command injection.
fun safe-shell-arg( s : string ) : maybe<string>
  val dangerous = [';', '&', '|', '$', '`', '(', ')', '<', '>', '\n', '\r', ' ', '"', '\'']
  if dangerous.any(fn(c) s.contains(c.show)) then Nothing
  else Just(s)

fun fetch-git( name : string, url : string, tag : string ) : io maybe<path>
  match (safe-shell-arg(url), safe-shell-arg(tag))
    (Nothing, _) ->
      println("error: dependency '" ++ name ++ "': url contains unsafe characters")
      Nothing
    (_, Nothing) ->
      println("error: dependency '" ++ name ++ "': tag contains unsafe characters")
      Nothing
    (Just(safe-url), Just(safe-tag)) ->
      val cache = hica-cache-dir()
      val dep-dir = cache / safe-url.path / safe-tag.path
      if is-directory(dep-dir) then
        Just(dep-dir)
      else
        println("  fetching " ++ name ++ " (" ++ safe-url ++ "@" ++ safe-tag ++ ")")
        ensure-dir(dep-dir.dirname.path)
        val git-url = "https://" ++ safe-url
        val exit-code = run-system("git clone --depth 1 --branch " ++ safe-tag ++ " " ++ git-url ++ " " ++ dep-dir.show)
        if exit-code != 0 then
          println("error: failed to fetch '" ++ name ++ "' from " ++ git-url)
          Nothing
        else Just(dep-dir)

// ---------------------------------------------------------------------------
// Manifest manipulation
// ---------------------------------------------------------------------------

// Add a dependency to hica.hml content. Returns the updated content.
pub fun add-dep-to-hml( content : string, dep : dep-spec ) : div string
  val dep-line = format-dep(dep)
  val all-lines = content.lines
  val has-section = all-lines.any(fn(l) l.trim.starts-with("@dependencies").bool)
  if !has-section then
    val base = if content.ends-with("\n").bool then content else content ++ "\n"
    base ++ "\n@dependencies {\n" ++ dep-line ++ "\n}\n"
  else
    // Insert before the closing } of the @dependencies block
    var in-deps := False
    var close-at := 0
    var idx := 0
    all-lines.foreach fn(line)
      val trimmed = line.trim
      if trimmed.starts-with("@dependencies").bool then
        in-deps := True
        close-at := idx + 1
      elif in-deps && trimmed == "}" then
        close-at := idx
        in-deps := False
      idx := idx + 1
    val before = all-lines.take(close-at)
    val after = all-lines.drop(close-at)
    (before ++ [dep-line] ++ after).join("\n")

// Remove a dependency from hica.hml content by name. Returns the updated content.
pub fun remove-dep-from-hml( content : string, dep-name : string ) : div string
  val all-lines = content.lines
  var in-deps := False
  val filtered = all-lines.filter fn(line)
    val trimmed = line.trim
    if trimmed.starts-with("@dependencies").bool then
      in-deps := True
      True
    elif in-deps && trimmed == "}" then
      in-deps := False
      True
    elif in-deps && !trimmed.is-empty && !trimmed.starts-with("//").bool then
      val parts = trimmed.split(":")
      match parts
        Cons(key, _) -> key.trim != dep-name
        _            -> True
    else True
  filtered.join("\n")

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

// Infer a package name from a git URL (last path component).
pub fun infer-dep-name( url : string ) : div string
  val parts = url.split("/")
  match parts.reverse
    Cons(last, _) -> last
    _             -> url

// Parse a dependency spec from a CLI argument.
// Format: "host/owner/repo@tag" or "path:../dir"
pub fun parse-dep-spec( spec : string ) : div dep-spec
  if spec.starts-with("path:").bool then
    val p = spec.slice.sslice/drop(5).string.trim
    val name = p.path.stemname
    Dep-spec(name, PathDep(p))
  else
    val parts = spec.split("@")
    match parts
      Cons(url, Cons(tag, _)) ->
        val name = infer-dep-name(url)
        Dep-spec(name, GitDep(url, tag))
      _ ->
        val name = infer-dep-name(spec)
        Dep-spec(name, GitDep(spec, "main"))
