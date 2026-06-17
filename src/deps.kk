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
import http

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
        elif value.contains("/") then
          // git URL: github.com/user/repo@tag or github.com/user/repo
          val at-parts = value.split("@")
          match at-parts
            Cons(url, Cons(tag, _)) ->
              Just(Dep-spec(name, GitDep(url.trim, tag.trim)))
            _ ->
              Just(Dep-spec(name, GitDep(value, "main")))
        else
          // registry dep: plain version string like "0.1.0" or "latest"
          Just(Dep-spec(name, RegistryDep(value)))
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
    RegistryDep(version) -> fetch-registry(dep.name, version)
    PathDep(p) ->
      val resolved = base-dir / p.path
      if !is-directory(resolved) then
        println("error: dependency '" ++ dep.name ++ "': path not found: " ++ resolved.show)
        Nothing
      else Just(resolved)

// ---------------------------------------------------------------------------
// Registry
// ---------------------------------------------------------------------------

// Extract a string value for a key from flat JSON: "key": "value"
// Works for our controlled registry metadata format (no escaped quotes in values).
fun json-get-str( json : string, key : string ) : div maybe<string>
  val needle = "\"" ++ key ++ "\": \""
  val parts = json.split(needle)
  match parts
    Cons(_, Cons(after, _)) ->
      val val-parts = after.split("\"")
      match val-parts
        Cons(value, _) -> Just(value)
        _              -> Nothing
    _ -> Nothing

fun fetch-registry( dep-name : string, version-str : string ) : io maybe<path>
  match (safe-shell-arg(dep-name), safe-shell-arg(version-str))
    (Nothing, _) ->
      println("error: registry package name '" ++ dep-name ++ "' contains unsafe characters")
      Nothing
    (_, Nothing) ->
      println("error: registry version '" ++ version-str ++ "' contains unsafe characters")
      Nothing
    (Just(safe-name), Just(_)) ->
      val resolved = if version-str == "latest" then
        http-get("https://pkg.hica.dev/" ++ safe-name ++ "/latest").trim
      else version-str
      if resolved.is-empty then
        println("error: could not resolve version of '" ++ safe-name ++ "'")
        Nothing
      else
        val cache   = hica-cache-dir()
        val dep-dir = cache / "pkg.hica.dev".path / safe-name.path / resolved.path
        if is-directory(dep-dir) then Just(dep-dir)
        else fetch-registry-install(safe-name, resolved, dep-dir)

fun fetch-registry-install( safe-name : string, version : string, dep-dir : path ) : io maybe<path>
  val meta-url = "https://pkg.hica.dev/" ++ safe-name ++ "/" ++ version ++ ".json"
  val meta     = http-get(meta-url)
  if meta.is-empty then
    println("error: package '" ++ safe-name ++ "@" ++ version ++ "' not found in registry")
    Nothing
  else
    match json-get-str(meta, "tarball")
      Nothing ->
        println("error: malformed registry metadata for '" ++ safe-name ++ "'")
        Nothing
      Just(tarball-url) ->
        val tmp-tar = "/tmp/hica-" ++ safe-name ++ "-" ++ version ++ ".tar.gz"
        println("  fetching " ++ safe-name ++ " (" ++ version ++ ") from registry")
        val dl-code = http-download(tarball-url, tmp-tar)
        if dl-code != 0 then
          println("error: failed to download '" ++ safe-name ++ "' from " ++ tarball-url)
          Nothing
        else
          val quoted-dir = "\"" ++ dep-dir.show ++ "\""
          val mkdir-exit = run-system("mkdir -p " ++ quoted-dir)
          if mkdir-exit != 0 then
            println("error: failed to create cache directory for '" ++ safe-name ++ "'")
            Nothing
          else
            val tar-exit = run-system("tar -xzf " ++ tmp-tar ++ " -C " ++ quoted-dir)
            if tar-exit != 0 then
              println("error: failed to extract '" ++ safe-name ++ "'")
              Nothing
            else Just(dep-dir)

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
// Lockfile
// ---------------------------------------------------------------------------

val lockfile-name = "hica.lock"

// Format a single dep-spec as a lockfile [[package]] entry.
fun format-lock-entry( d : dep-spec ) : string
  val source-str = match d.source
    GitDep(url, tag)     -> "git+https://" ++ url ++ "?tag=" ++ tag
    PathDep(p)           -> "path:" ++ p
    RegistryDep(version) -> "registry+pkg.hica.dev@" ++ version
  val version-str = match d.source
    GitDep(_, tag)       -> tag
    PathDep(_)           -> "0.0.0"
    RegistryDep(version) -> version
  "[[package]]\n" ++
  "name = \"" ++ d.name ++ "\"\n" ++
  "version = \"" ++ version-str ++ "\"\n" ++
  "source = \"" ++ source-str ++ "\"\n"

// Write hica.lock from a list of resolved dep-specs.
pub fun write-lockfile( dep-list : list<dep-spec> ) : io ()
  val entries = dep-list.map(format-lock-entry)
  val content = "# hica.lock — auto-generated, do not edit\n\n" ++ entries.join("\n")
  write-text-file(lockfile-name.path, content)

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
// Formats:
//   "github.com/user/repo@tag"  → git dep
//   "github.com/user/repo"      → git dep (main branch)
//   "path:../dir"               → path dep
//   "json@0.1.0"                → registry dep (exact version)
//   "json"                      → registry dep (latest)
pub fun parse-dep-spec( spec : string ) : div dep-spec
  if spec.starts-with("path:").bool then
    val p = spec.slice.sslice/drop(5).string.trim
    val name = p.path.stemname
    Dep-spec(name, PathDep(p))
  else
    val at-parts = spec.split("@")
    match at-parts
      Cons(pkg, Cons(version, _)) ->
        if pkg.contains("/") then
          // git: github.com/user/repo@tag
          val name = infer-dep-name(pkg)
          Dep-spec(name, GitDep(pkg, version))
        else
          // registry: json@0.1.0
          Dep-spec(pkg.trim, RegistryDep(version.trim))
      _ ->
        if spec.contains("/") then
          // git URL without tag
          val name = infer-dep-name(spec)
          Dep-spec(name, GitDep(spec, "main"))
        else
          // registry package, latest
          Dep-spec(spec.trim, RegistryDep("latest"))
