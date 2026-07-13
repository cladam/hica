/*
 * hica – Koka code generation
 * 
 * This source file is part of the hica open source project
 * Copyright (C) 2026 Claes Adamsson <claes.adamsson@gmail.com>
 *
 * See https://github.com/cladam/hica/blob/main/LICENSE for license information
*/
module emit/codegen

import syntax/ast

// ---------------------------------------------------------------------------
// Module name sanitisation: Koka keywords cannot be used as module names.
// ---------------------------------------------------------------------------

val koka-keywords = ["match", "fun", "val", "var", "if", "else", "elif",
  "then", "return", "with", "handle", "handler", "effect", "type", "struct",
  "alias", "module", "import", "pub", "abstract", "extern", "fn", "forall",
  "raw", "inline", "include", "co", "rec", "open", "extend", "behind",
  "linear", "value", "reference", "named", "scoped", "context", "initially",
  "finally", "override", "path"]

pub fun safe-module-name( name : string ) : string
  if koka-keywords.any(fn(k) k == name) then "hc-" ++ name
  else match name.list
    Cons(c, _) | c.is-digit -> "hc" ++ name
    _                       -> name

// Extract the basename from an import path: "lib/utils" → "utils"
fun import-basename( p : string ) : div string
  match p.list.reverse.span(fn(c) c != '/')
    (_, Nil)        -> p
    (rev-base, _)   -> rev-base.reverse.string

// ---------------------------------------------------------------------------
// Name marshalling: prefix user-declared names to avoid Koka stdlib clashes.
// Names declared by the user or that conflict with Koka builtins get an hc_ prefix.
// ---------------------------------------------------------------------------

val koka-reserved-names = ["list", "vector", "string", "int", "bool", "float",
  "char", "order", "maybe", "either", "tuple", "sslice", "console", "debug",
  "exn", "div", "ndet", "io", "show", "core", "std"]

fun marshal-name( name : string, declared : list<string> ) : string
  if declared.any(fn(d) d == name) || koka-reserved-names.any(fn(r) r == name)
    || koka-keywords.any(fn(k) k == name)
    then "hc_" ++ name
  else name

// ---------------------------------------------------------------------------
// Type annotation emission: convert hica types to Koka type syntax
// ---------------------------------------------------------------------------

fun emit-type( t : hica-type ) : div string
  match t
    TInt        -> "int"
    TFloat      -> "float64"
    TBool       -> "bool"
    TString     -> "string"
    TChar       -> "char"
    TUnit       -> ""    // omit — let Koka infer effects
    TTuple(es)  ->
      val parts = es.map(fn(e) emit-type(e))
      if parts.any(fn(p) p == "") then ""
      else "(" ++ parts.join(", ") ++ ")"
    TList(e)    ->
      val inner = emit-type(e)
      if inner == "" then "" else "list<" ++ inner ++ ">"
    TMaybe(e)   ->
      val inner = emit-type(e)
      if inner == "" then "" else "maybe<" ++ inner ++ ">"
    TResult(o, e) ->
      val ok-str = emit-type(o)
      val err-str = emit-type(e)
      if ok-str == "" || err-str == "" then "" else "either<" ++ err-str ++ ", " ++ ok-str ++ ">"
    TFun(ps, r) ->
      val param-strs = ps.map(fn(p) emit-type(p))
      val ret-str = emit-type(r)
      if param-strs.any(fn(s) s == "") || ret-str == "" then ""
      else "(" ++ param-strs.join(", ") ++ ") -> " ++ ret-str
    TStruct(name) -> name.struct-type-name
    TEnum(name)   -> name.to-lower
    TVar(_)     -> ""  // unresolved — omit annotation

// ---------------------------------------------------------------------------
// Struct definition emission
// ---------------------------------------------------------------------------

// Convert a struct name to Koka's lowercase type name: Point -> point
fun struct-type-name( name : string ) : string
  name.to-lower

// Marshal a struct/enum field name to avoid Koka keyword clashes.
fun marshal-field( fname : string ) : string
  if koka-keywords.any(fn(k) k == fname) || koka-reserved-names.any(fn(r) r == fname)
    then "hc-" ++ fname
  else fname

fun emit-struct-def( sd : struct-def ) : div string
  val tname = sd.name.struct-type-name
  val pub-str = if sd.is-pub then "pub " else ""
  // Koka uses `abstract struct` (no `pub` prefix) to make a type opaque:
  // the type name is still accessible across modules but the constructor is hidden.
  // This covers both `opaque struct` (P1) and `pub struct … priv` (P2).
  val struct-keyword = if sd.is-opaque then "abstract struct " else "struct "
  val struct-decl-prefix = if sd.is-opaque then "" else pub-str
  val struct-str = struct-decl-prefix ++ struct-keyword ++ tname ++ "\n" ++
    sd.fields.map(fn((fname, ftype)) "  " ++ marshal-field(fname) ++ " : " ++ emit-type(ftype)).join("\n")
  // Emit a show function for the struct
  val show-parts = sd.fields.map fn((fname, ftype))
    "\"" ++ fname ++ ": \" ++ " ++ emit-show-call(ftype, "p." ++ marshal-field(fname))
  // Recursive structs need the `div` effect on show
  val is-rec = sd.fields.any(fn((_, ft)) ft.references-struct(sd.name))
  val effect-ann = if is-rec then " : div string" else " : string"
  val show-fn = pub-str ++ "fun " ++ tname ++ "/show(p : " ++ tname ++ ")" ++ effect-ann ++ "\n" ++
    "  \"" ++ sd.name ++ "(\" ++ " ++ show-parts.join(" ++ \", \" ++ ") ++ " ++ \")\""
  struct-str ++ "\n\n" ++ show-fn

// ---------------------------------------------------------------------------
// Type (enum) definition emission
// ---------------------------------------------------------------------------

fun emit-type-def( td : type-def, structs : list<struct-def>, all-types : list<type-def> = [] ) : div string
  val tname = td.name.to-lower
  val pub-str = if td.is-pub then "pub " else ""
  val type-str = pub-str ++ "type " ++ tname ++ "\n" ++
    td.variants.map(fn(vd)
      if vd.fields.is-nil then "  " ++ vd.name
      else "  " ++ vd.name ++ "(" ++ vd.fields.map(fn((fname, ftype)) marshal-field(fname) ++ " : " ++ emit-type(ftype)).join(", ") ++ ")"
    ).join("\n")
  // Emit a show function for the type
  val is-rec = td.variants.any(fn(vd) vd.fields.any(fn((_, ft)) ft.references-type(td.name)))
  val refs-rec-struct = td.variants.any(fn(vd) vd.fields.any(fn((_, ft)) ft.references-recursive-struct(structs)))
  // Check for mutual recursion: does this type reference another type that references back?
  val refs-rec-type = td.variants.any(fn(vd) vd.fields.any(fn((_, ft))
    all-types.any(fn(other)
      other.name != td.name &&
      ft.references-type(other.name) &&
      other.variants.any(fn(ov) ov.fields.any(fn((_, oft)) oft.references-type(td.name)))
    )
  ))
  val effect-ann = if is-rec || refs-rec-struct || refs-rec-type then " : div string" else " : string"
  val show-arms = td.variants.map fn(vd)
    if vd.fields.is-nil then
      "    " ++ vd.name ++ " -> \"" ++ vd.name ++ "\""
    elif vd.fields.length == 1 then
      match vd.fields
        Cons((fname, ftype), _) ->
          val mf = marshal-field(fname)
          "    " ++ vd.name ++ "(" ++ mf ++ ") -> \"" ++ vd.name ++ "(\" ++ " ++ emit-show-call(ftype, mf) ++ " ++ \")\""
        _ -> ""
    else
      val param-names = vd.fields.map(fn((fname, _)) marshal-field(fname))
      val show-parts = vd.fields.map(fn((fname, ftype)) emit-show-call(ftype, marshal-field(fname)))
      "    " ++ vd.name ++ "(" ++ param-names.join(", ") ++ ") -> \"" ++ vd.name ++ "(\" ++ " ++ show-parts.join(" ++ \", \" ++ ") ++ " ++ \")\""
  val show-fn = pub-str ++ "fun " ++ tname ++ "/show(v : " ++ tname ++ ")" ++ effect-ann ++ "\n" ++
    "  match v\n" ++
    show-arms.join("\n")
  type-str ++ "\n\n" ++ show-fn

// Check if a type references a type name (for recursion detection in enums)
fun references-type( t : hica-type, name : string ) : div bool
  match t
    TEnum(en) -> en == name
    TStruct(sn) -> sn == name
    TMaybe(inner) -> inner.references-type(name)
    TList(inner) -> inner.references-type(name)
    TTuple(ts) -> ts.any(fn(tt) tt.references-type(name))
    TFun(params, ret) -> params.any(fn(p) p.references-type(name)) || ret.references-type(name)
    _ -> False

// Check if a type references a struct by name (for recursion detection)
fun references-struct( t : hica-type, name : string ) : div bool
  match t
    TStruct(sn) -> sn == name
    TMaybe(inner) -> inner.references-struct(name)
    TList(inner) -> inner.references-struct(name)
    TTuple(ts) -> ts.any(fn(tt) tt.references-struct(name))
    TFun(params, ret) -> params.any(fn(p) p.references-struct(name)) || ret.references-struct(name)
    _ -> False

// Check if a type contains a reference to a recursive struct (whose show is div)
fun references-recursive-struct( t : hica-type, structs : list<struct-def> ) : div bool
  match t
    TStruct(sn) -> structs.any(fn(sd) sd.name == sn && sd.fields.any(fn((_, ft)) ft.references-struct(sn)))
    TMaybe(inner) -> inner.references-recursive-struct(structs)
    TList(inner) -> inner.references-recursive-struct(structs)
    TTuple(ts) -> ts.any(fn(tt) tt.references-recursive-struct(structs))
    TFun(params, ret) -> params.any(fn(p) p.references-recursive-struct(structs)) || ret.references-recursive-struct(structs)
    _ -> False

// Emit a show call for a specific type
fun emit-show-call( t : hica-type, expr-str : string ) : div string
  match t
    TInt    -> expr-str ++ ".show"
    TFloat  -> "float64/show(" ++ expr-str ++ ")"
    TBool   -> expr-str ++ ".show"
    TChar   -> expr-str ++ ".show"
    TString -> expr-str
    TStruct(sn) -> sn.struct-type-name ++ "/show(" ++ expr-str ++ ")"
    TEnum(en)   -> en.to-lower ++ "/show(" ++ expr-str ++ ")"
    TMaybe(inner) -> "hc-show-maybe(" ++ expr-str ++ ", fn(x) " ++ emit-show-call(inner, "x") ++ ")"
    TResult(ok, err) -> "hc-show-result(" ++ expr-str ++ ", fn(x) " ++ emit-show-call(ok, "x") ++ ", fn(e) " ++ emit-show-call(err, "e") ++ ")"
    _       -> expr-str ++ ".show"

// ---------------------------------------------------------------------------
// Source mapping: compute line number from byte offset
// ---------------------------------------------------------------------------

fun offset-to-line( source : string, offset : int ) : int
  if source.is-empty then 0
  else
    var line := 1
    var i    := 0
    source.list.foreach fn(c)
      if i < offset then
        if c == '\n' then line := line + 1
        i := i + 1
    line

// ---------------------------------------------------------------------------
// Program-level emission: generates a complete .kk module
// ---------------------------------------------------------------------------

pub fun emit-program( p : program, mod-name : string = "main", imported-names : list<string> = [], source : string = "", prelude-count : int = 0, extra-effectful : list<string> = [], extra-imports : list<string> = [] ) : div string
  val global-names = p.globals.map(fn(g) g.name)
  val declared = p.decls.map(fn(d) d.name).filter(fn(n) n != "main") ++ global-names ++ imported-names
  val float-import = if program-has-float(p) then "import std/num/float64\n\n" else ""
  val random-import = if program-uses-random(p) then "import std/num/random\nimport std/num/int32\n\n" else ""
  val bitwise-import = if !program-uses-random(p) && program-uses-bitwise(p) then "import std/num/int32\n\n" else ""
  val env-import = if program-uses-env(p) then "import std/os/env\n\n" else ""
  val file-import = if program-uses-file-io(p) then "import std/os/file\nimport std/os/path\n\n" else ""
  val exec-import = if program-uses-exec(p) then "import std/os/process\n\n" else ""
  val readline-import = if program-uses-input(p) then "import std/os/readline\n\n" else ""
  val readline-helper = if program-uses-input(p) then readline-helper-code else ""
  val time-import = if program-uses-time(p) then "import std/time/chrono\nimport std/time/utc\nimport std/time/time\nimport std/time/format\nimport std/num/ddouble\n\n" else ""
  val hica-imports = p.imports.map(fn(imp)
    val koka-mod = safe-module-name(imp.path.import-basename)
    val pub-str = if imp.is-pub then "pub " else ""
    pub-str ++ "import " ++ koka-mod ++ "\n"
  ).join("") ++ (if p.imports.is-nil then "" else "\n")
  // Koka treats repeated unqualified imports of a module as separate candidates,
  // making its names ambiguous. Deduplicate the transitive extern-module imports
  // against the module's own imports and against each other.
  val hica-mod-names = p.imports.map(fn(imp) safe-module-name(imp.path.import-basename))
  val extra-dedup = extra-imports.foldl([], fn(acc, m)
    if acc.any(fn(a) a == m) || hica-mod-names.any(fn(a) a == m) then acc else acc ++ [m]
  )
  val extra-kk-imports = extra-dedup.map(fn(m) "import " ++ m ++ "\n").join("") ++ (if extra-dedup.is-nil then "" else "\n")
  val has-brk = program-has-break(p)
  val has-cont = program-has-continue(p)
  val has-try-r = program-has-try-result(p)
  val has-try-m = program-has-try-maybe(p)
  val break-effect = if has-brk then "effect hica-brk\n  ctl hica-break() : a\n\n" else ""
  val cont-effect = if has-cont then "effect hica-cont\n  ctl hica-continue() : a\n\n" else ""
  val try-result-effect = if has-try-r then "effect hica-early-result<a>\n  ctl hica-early-err(e : a) : b\n\n" else ""
  val try-maybe-effect = if has-try-m then "effect hica-early-maybe\n  ctl hica-early-none() : a\n\n" else ""
  val sort-helper = if program-uses-sort(p) then sort-helper-code else ""
  val exit-helper = if program-uses-exit(p) then exit-helper-code else ""
  val get-env-helper = if program-uses-get-env(p) then get-env-helper-code else ""
  val set-env-helper = if program-uses-set-env(p) then set-env-helper-code else ""
  val assert-helper = assert-helper-code
  val show-maybe-helper = show-maybe-helper-code
  val show-result-helper = show-result-helper-code
  val type-defs = p.types.map(fn(td) emit-type-def(td, p.structs, p.types)).join("\n\n")
  val type-sep = if p.types.is-nil then "" else "\n\n"
  val struct-defs = p.structs.map(fn(sd) emit-struct-def(sd)).join("\n\n")
  val struct-sep = if p.structs.is-empty then "" else "\n\n"
  val global-defs = p.globals.map(fn(g) emit-global(g, declared)).join("\n")
  val global-sep = if p.globals.is-empty then "" else "\n\n"
  val rec-names = compute-div-names(p.decls)
  val seed-result = p.decls.filter(fn(d) d.is-recursive && node-has-try-result(d.body)).map(fn(d) d.name)
  val seed-maybe  = p.decls.filter(fn(d) d.is-recursive && node-has-try-maybe(d.body)).map(fn(d) d.name)
  val try-rec-result-names = expand-try-rec-names(p.decls, seed-result)
  val try-rec-maybe-names  = expand-try-rec-names(p.decls, seed-maybe)
  val user-names = p.decls.drop(prelude-count).map(fn(d) d.name)
  val prelude-decls = p.decls.take(prelude-count).filter(fn(d) !user-names.any(fn(n) n == d.name))
  "// Generated by hica\n" ++
  "module " ++ mod-name ++ "\n\n" ++
  float-import ++
  random-import ++
  bitwise-import ++
  env-import ++
  file-import ++
  exec-import ++
  readline-import ++
  time-import ++
  hica-imports ++
  extra-kk-imports ++
  break-effect ++
  cont-effect ++
  try-result-effect ++
  try-maybe-effect ++
  sort-helper ++
  exit-helper ++
  get-env-helper ++
  set-env-helper ++
  readline-helper ++
  assert-helper ++
  show-maybe-helper ++
  show-result-helper ++
  type-defs ++ type-sep ++
  struct-defs ++ struct-sep ++
  global-defs ++ global-sep ++
  prelude-decls.map(fn(d) emit-decl(d, declared, rec-names, extra-effectful = extra-effectful)).join("\n\n") ++
  (if !prelude-decls.is-empty && p.decls.length > prelude-count then "\n\n" else "") ++
  p.decls.drop(prelude-count).map(fn(d) emit-decl(d, declared, rec-names, source, extra-effectful = extra-effectful, try-rec-result-names = try-rec-result-names, try-rec-maybe-names = try-rec-maybe-names)).join("\n\n") ++ "\n"

fun emit-global( g : global-decl, declared : list<string> ) : div string
  val pub-str = if g.is-pub then "pub " else ""
  val name-str = marshal-name(g.name, declared)
  val type-str = match g.typ
    Just(t) -> " : " ++ emit-type(t)
    Nothing -> ""
  pub-str ++ "val " ++ name-str ++ type-str ++ " = " ++ emit-expr(g.body, declared)

fun emit-decl( d : fun-decl, declared : list<string>, rec-names : list<string> = [], source : string = "", extra-effectful : list<string> = [], try-rec-result-names : list<string> = [], try-rec-maybe-names : list<string> = [] ) : div string
  val params-str = emit-typed-params(d.params, d.param-types, declared)
  val has-try-result = node-has-try-result(d.body)
  val has-try-maybe  = node-has-try-maybe(d.body)
  val effectful-prims = [
    // console effect — suppress `: ReturnType` annotation so Koka infers <console|_e>
    "println", "print", "eprintln",
    // io effect
    "input",
    // ndet effect
    "random", "random_float",
    // sys/env effect
    "get_args", "get_env", "set_env", "set_env_nooverwrite", "env_require", "env_or", "env_int",
    // dotenv effect (read file + set env)
    "dotenv_load", "dotenv_load_override", "dotenv_apply", "dotenv_apply_override",
    // fsys effect
    "read_file", "write_file", "read_lines", "write_lines",
    // exec effect
    "exec", "exec_args",
    // time effect
    "now_unix", "now_iso", "unix_to_iso",
    // exit effect
    "exit",
    // rawterm effect
    "read_key", "term_cols", "term_rows", "flush_stdout"
  ] ++ extra-effectful
  val needs-div = d.is-recursive || (!rec-names.is-nil && body-calls-any(d.body, rec-names)) || body-calls-any(d.body, effectful-prims) || node-has-while(d.body)
  val ret-ann = match d.ret-ann
    Just(TFun(_, _)) -> ""
    Just(t) ->
      val ts = emit-type(t)
      if ts == "" then ""
      elif needs-div then ""  // let Koka infer effects (div + fsys, io, etc.)
      else " : " ++ ts
    Nothing -> ""
  val pub-prefix = if d.is-pub then "pub " else ""
  val fn-name = marshal-name(d.name, declared)
  val arg-list = d.params.map(fn(n) marshal-name(n, declared)).join(", ")
  val body-code = emit-body(d.body, declared).lines.map(fn(line) "  " ++ line).join("\n")
  val line-comment = if source.is-empty || d.span.start >= source.count then ""
    else "// .hc:" ++ offset-to-line(source, d.span.start).show ++ "\n"
  val in-result-group = try-rec-result-names.any(fn(n) n == d.name)
  val in-maybe-group  = try-rec-maybe-names.any(fn(n) n == d.name)
  val all-try-rec = try-rec-result-names ++ try-rec-maybe-names
  if (in-result-group || in-maybe-group) && d.is-recursive then
    // This function is in a mutual-recursion SCC that contains at least one `?` operator.
    // Emit a __work function (the full recursive body with all SCC-member calls redirected
    // to __work variants) plus a thin outer wrapper that installs the effect handler.
    // This keeps the entire cycle inside __work so the outer wrappers are not mutually
    // recursive, which would re-introduce the infinite effect-type unification error.
    val work-body = all-try-rec.foldl(body-code, fn(code, fname)
      val en = marshal-name(fname, declared)
      code.replace-all(en ++ "(", en ++ "__work(")
    )
    val ctl-line = if in-result-group
      then "    ctl hica-early-err(e) -> Left(e)\n"
      else "    ctl hica-early-none() -> Nothing\n"
    line-comment ++
    "fun " ++ fn-name ++ "__work(" ++ params-str ++ ")\n" ++ work-body ++ "\n\n" ++
    pub-prefix ++ "fun " ++ fn-name ++ "(" ++ params-str ++ ")\n" ++
    "  with handler\n" ++ ctl-line ++
    "  " ++ fn-name ++ "__work(" ++ arg-list ++ ")"
  else
    val wrapped-body = if has-try-result then
      "  with handler\n    ctl hica-early-err(e) -> Left(e)\n" ++ body-code
    elif has-try-maybe then
      "  with handler\n    ctl hica-early-none() -> Nothing\n" ++ body-code
    else body-code
    line-comment ++
    pub-prefix ++ "fun " ++ fn-name ++ "(" ++ params-str ++ ")" ++ ret-ann ++ "\n" ++
    wrapped-body

// Emit parameter list with type annotations when available.
fun emit-typed-params( names : list<string>, types : list<hica-type>, declared : list<string> ) : div string
  match (names, types)
    (Cons(n, ns), Cons(t, ts)) ->
      val ann = emit-type(t)
      val param = if ann == "" then marshal-name(n, declared)
                  else marshal-name(n, declared) ++ " : " ++ ann
      match ns
        Nil -> param
        _   -> param ++ ", " ++ emit-typed-params(ns, ts, declared)
    (Cons(n, ns), Nil) ->
      // No types available — emit bare names
      match ns
        Nil -> marshal-name(n, declared)
        _   -> marshal-name(n, declared) ++ ", " ++ emit-typed-params(ns, [], declared)
    _ -> ""

fun emit-body( n : node, declared : list<string> ) : div string
  match n.expr
    Block(stmts) -> stmts.map(fn(s) emit-stmt(s, declared)).join("\n")
    _            -> emit-stmt(n, declared)

// Emit a body but wrap the last expression in a constructor, e.g. Just(last-expr)
fun emit-body-wrap-last( wrapper : string, n : node, declared : list<string> ) : div string
  match n.expr
    LetTuple(names, init, body) ->
      "val (" ++ names.map(fn(nm) marshal-name(nm, declared)).join(", ") ++ ") = " ++ emit-expr(init, declared) ++ "\n" ++ emit-body-wrap-last(wrapper, body, declared)
    Let(name, _, init, body) ->
      val init-code = emit-expr(init, declared)
      val binding = if init-code.contains("\n") then
        "val " ++ marshal-name(name, declared) ++ " =\n" ++ indent-all(init-code)
      else
        "val " ++ marshal-name(name, declared) ++ " = " ++ init-code
      binding ++ "\n" ++ emit-body-wrap-last(wrapper, body, declared)
    Block(stmts) ->
      match stmts.reverse
        Cons(last, rest) ->
          rest.reverse.map(fn(s) emit-stmt(s, declared)).join("\n") ++
          (if rest.is-nil then "" else "\n") ++
          emit-body-wrap-last(wrapper, last, declared)
        Nil -> wrapper ++ "()"
    _ -> wrapper ++ "(" ++ emit-expr(n, declared) ++ ")"

fun emit-stmt( n : node, declared : list<string> ) : div string
  match n.expr
    Let(name, _, init, body) ->
      val ann = match init.typ
        Just(t) ->
          val ts = emit-type(t)
          if ts == "" then "" else " : " ++ ts
        Nothing -> ""
      val init-code = emit-expr(init, declared)
      val binding = if init-code.contains("\n") then
        "val " ++ marshal-name(name, declared) ++ ann ++ " =\n" ++ indent-all(init-code)
      else
        "val " ++ marshal-name(name, declared) ++ ann ++ " = " ++ init-code
      binding ++ "\n" ++ emit-stmt(body, declared)
    VarDecl(name, _, init, body) ->
      val ann = match init.typ
        Just(t) ->
          val ts = emit-type(t)
          if ts == "" then "" else " : " ++ ts
        Nothing -> ""
      val init-code = emit-expr(init, declared)
      val binding = if init-code.contains("\n") then
        "var " ++ marshal-name(name, declared) ++ ann ++ " :=\n" ++ indent-all(init-code)
      else
        "var " ++ marshal-name(name, declared) ++ ann ++ " := " ++ init-code
      binding ++ "\n" ++ emit-stmt(body, declared)
    LetTuple(names, init, body) ->
      "val (" ++ names.map(fn(nm) marshal-name(nm, declared)).join(", ") ++ ") = " ++ emit-expr(init, declared) ++ "\n" ++ emit-stmt(body, declared)
    _ -> emit-expr(n, declared)

// ---------------------------------------------------------------------------
// Single-expression emission (legacy: wraps in println)
// ---------------------------------------------------------------------------

pub fun emit( n : node ) : div string
  "// Generated by hica\n" ++
  "module main\n\n" ++
  "fun main()\n" ++
  "  println(" ++ emit-expr(n, []) ++ ".show)\n"

// ---------------------------------------------------------------------------
// Hoist multiline call arguments to val-bindings inside an IIFE.
// Koka's layout-sensitive parser cannot close a `fn` body block via `)`, so
// any multiline arg in a non-trailing position must be pre-bound to a val.
// Returns (hoist-stmts, arg-refs) where each multiline arg becomes
// "val hc__argN = <code>" and the corresponding ref is "hc__argN".
// ---------------------------------------------------------------------------

fun hoist-multiline-args( coded : list<string>, idx : int ) : div (list<string>, list<string>)
  match coded
    Nil -> ([], [])
    Cons(c, rest) ->
      val (rest-hoists, rest-refs) = hoist-multiline-args(rest, idx + 1)
      if c.contains("\n") then
        val nm = "hc__arg" ++ show(idx)
        (Cons("val " ++ nm ++ " = " ++ c, rest-hoists), Cons(nm, rest-refs))
      else
        (rest-hoists, Cons(c, rest-refs))

// ---------------------------------------------------------------------------
// Expression emission
// ---------------------------------------------------------------------------

// Translate escape sequences into Koka-compatible hex escapes.
// Handles two input forms:
//   - Raw control bytes (0x08, 0x0c) — e.g. pasted text or some editors
//   - Typed two-char escapes (backslash+b, backslash+f) — hica source files
// Both become the Koka hex-escape sequences that Koka's string parser accepts.
fun fix-string-escapes( s : string ) : string
  s.replace-all("\x08", "\\x08")   // raw backspace byte → \x08
   .replace-all("\x0c", "\\x0c")   // raw form-feed byte → \x0c
   .replace-all("\\b",  "\\x08")   // typed \b escape    → \x08
   .replace-all("\\f",  "\\x0c")   // typed \f escape    → \x0c

fun emit-expr( n : node, declared : list<string> ) : div string
  match n.expr
    Literal(LitInt(i))      -> i.show
    Literal(LitFloat(f))    -> f
    Literal(LitBool(True))  -> "True"
    Literal(LitBool(False)) -> "False"
    Literal(LitString(s))   -> "\"" ++ fix-string-escapes(s) ++ "\""
    Literal(LitChar(c))     -> "'" ++ c ++ "'"
    Var(name)               -> marshal-name(name, declared)
    Binary(op, l, r)        ->
      match op
        In ->
          // x in list → list.any(fn(hc__el) hc__el == x)
          emit-expr(r, declared) ++ ".any(fn(hc__el) hc__el == " ++ emit-expr(l, declared) ++ ")"
        _ ->
          val op-str = match (op, n.typ)
            (Add, Just(TString))  -> "++"
            (Add, Just(TList(_))) -> "++"
            _                     -> emit-binop(op)
          val l-code = emit-expr(l, declared)
          val r-code = emit-expr(r, declared)
          // Hoist multiline operands to a val binding inside an IIFE so the
          // operator and closing ) are never appended to the last line of a
          // multi-line expression (trailing lambda, if-then-else, etc.).
          if l-code.contains("\n") then
            "(fn()\n" ++ indent-all("val hc__lv = " ++ l-code ++ "\nhc__lv " ++ op-str ++ " " ++ r-code) ++ "\n)()"
          else if r-code.contains("\n") then
            "(fn()\n" ++ indent-all("val hc__rv = " ++ r-code ++ "\n" ++ l-code ++ " " ++ op-str ++ " hc__rv") ++ "\n)()"
          else
            // Koka does not allow `if` as a direct binary operand without parens.
            // Parenthesize any If sub-expression that would appear inline.
            val l-safe = match l.expr
              If(_, _, _) -> "(" ++ l-code ++ ")"
              _           -> l-code
            val r-safe = match r.expr
              If(_, _, _) -> "(" ++ r-code ++ ")"
              _           -> r-code
            "(" ++ l-safe ++ " " ++ op-str ++ " " ++ r-safe ++ ")"
    Unary(Neg, o) ->
      // Use 0.0 for float operands — `(0 - 1.0)` is int - float64 which Koka rejects.
      val zero = match o.typ
        Just(TFloat) -> "0.0"
        _            -> "0"
      "(" ++ zero ++ " - " ++ emit-expr(o, declared) ++ ")"
    Unary(Not, o)           -> "!(" ++ emit-expr(o, declared) ++ ")"
    Let(name, _, init, body) ->
      val init-code = emit-expr(init, declared)
      val binding = if init-code.contains("\n") then
        "val " ++ marshal-name(name, declared) ++ " =\n" ++ indent-all(init-code)
      else
        "val " ++ marshal-name(name, declared) ++ " = " ++ init-code
      binding ++ "\n" ++ emit-expr(body, declared)
    VarDecl(name, _, init, body) ->
      val init-code = emit-expr(init, declared)
      val binding = if init-code.contains("\n") then
        "var " ++ marshal-name(name, declared) ++ " :=\n" ++ indent-all(init-code)
      else
        "var " ++ marshal-name(name, declared) ++ " := " ++ init-code
      binding ++ "\n" ++ emit-expr(body, declared)
    Assign(name, value) ->
      marshal-name(name, declared) ++ " := " ++ emit-expr(value, declared)
    Fun(params, body) ->
      // Detect desugared tuple lambda: fn(_tp) { val (a, b) = _tp; body }
      // Emit as Koka native: fn((a, b)) body
      match (params, body.expr)
        (Cons("_tp", Nil), LetTuple(names, _, actual-body)) ->
          val param-str = "fn((" ++ names.map(fn(nm) marshal-name(nm, declared)).join(", ") ++ "))"
          if actual-body.expr.is-multiline then
            param-str ++ "\n" ++ indent-all(emit-body(actual-body, declared))
          else
            param-str ++ " " ++ emit-expr(actual-body, declared)
        _ ->
          val param-str = "fn(" ++ params.map(fn(p) marshal-name(p, declared)).join(", ") ++ ")"
          if body.expr.is-multiline then
            param-str ++ "\n" ++ indent-all(emit-body(body, declared))
          else
            param-str ++ " " ++ emit-expr(body, declared)
    Call(callee, args) ->
      // Auto-wrap println argument with show when it's not a string
      match (callee.expr, args)
        (Var("println"), [arg]) ->
          match arg.typ
            Just(TString) -> "println(" ++ emit-expr(arg, declared) ++ ")"
            Just(TInt)    -> "println(" ++ emit-expr(arg, declared) ++ ".show)"
            Just(TFloat)  -> "println(" ++ emit-expr(arg, declared) ++ ".show)"
            Just(TBool)   -> "println(" ++ emit-expr(arg, declared) ++ ".show)"
            Just(TChar)   -> "println(" ++ emit-expr(arg, declared) ++ ".string)"
            Just(TMaybe(inner)) -> "println(hc-show-maybe(" ++ emit-expr(arg, declared) ++ ", fn(x) " ++ emit-show-call(inner, "x") ++ "))"
            Just(TResult(ok, err)) -> "println(hc-show-result(" ++ emit-expr(arg, declared) ++ ", fn(x) " ++ emit-show-call(ok, "x") ++ ", fn(e) " ++ emit-show-call(err, "e") ++ "))"
            Just(TStruct(sn))  -> "println(" ++ sn.struct-type-name ++ "/show(" ++ emit-expr(arg, declared) ++ "))"
            Just(TEnum(en))    -> "println(" ++ en.to-lower ++ "/show(" ++ emit-expr(arg, declared) ++ "))"
            _             -> "println(" ++ emit-expr(arg, declared) ++ ".show)"
        (Var("enumerate"), [arg]) ->
          emit-expr(arg, declared) ++ ".map-indexed(fn(hc__i, hc__x) (hc__i, hc__x))"
        // --- String utilities ---
        (Var("str_length"), [s]) ->
          emit-expr(s, declared) ++ ".count"
        // is_empty on lists is rewritten by the checker to list_is_empty
        (Var("list_is_empty"), [xs]) ->
          emit-expr(xs, declared) ++ ".is-nil"
        (Var("contains"), [s, sub]) ->
          emit-expr(s, declared) ++ ".contains(" ++ emit-expr(sub, declared) ++ ")"
        (Var("str_contains"), [s, sub]) ->
          emit-expr(s, declared) ++ ".contains(" ++ emit-expr(sub, declared) ++ ")"
        (Var("starts_with"), [s, pre]) ->
          emit-expr(s, declared) ++ ".starts-with(" ++ emit-expr(pre, declared) ++ ").is-just"
        (Var("ends_with"), [s, suf]) ->
          emit-expr(s, declared) ++ ".ends-with(" ++ emit-expr(suf, declared) ++ ").is-just"
        (Var("trim"), [s]) ->
          emit-expr(s, declared) ++ ".trim"
        (Var("trim_start"), [s]) ->
          emit-expr(s, declared) ++ ".trim-left"
        (Var("trim_end"), [s]) ->
          emit-expr(s, declared) ++ ".trim-right"
        (Var("to_upper"), [s]) ->
          emit-expr(s, declared) ++ ".to-upper"
        (Var("to_lower"), [s]) ->
          emit-expr(s, declared) ++ ".to-lower"
        (Var("split"), [s, sep]) ->
          val s-str = emit-expr(s, declared)
          val sep-str = emit-expr(sep, declared)
          // Bind both args via IIFE so Perceus ref-counting keeps them alive
          // across the is-empty check and the split call (avoids use-after-free
          // when sep comes from a nested match arm Cons destructure).
          "(fn(hc__s: string, hc__sep: string) if hc__sep.is-empty then hc__s.list.map(fn(c) c.string) else hc__s.split(hc__sep))(" ++ s-str ++ ", " ++ sep-str ++ ")"
        (Var("replace"), [s, old, new_]) ->
          emit-expr(s, declared) ++ ".replace-all(" ++ emit-expr(old, declared) ++ ", " ++ emit-expr(new_, declared) ++ ")"
        (Var("join"), [xs, sep]) ->
          emit-expr(xs, declared) ++ ".join(" ++ emit-expr(sep, declared) ++ ")"
        (Var("index_of"), [s, sub]) ->
          "(match " ++ emit-expr(s, declared) ++ ".find(" ++ emit-expr(sub, declared) ++ ") { Just(hc__ss) -> Just(hc__ss.before.count); Nothing -> Nothing })"
        (Var("to_int"), [s]) ->
          "(match " ++ emit-expr(s, declared) ++ ".parse-int { Just(hc__n) -> hc__n; Nothing -> -1 })"
        (Var("parse_int"), [s]) | !declared.any(fn(d) d == "parse_int") ->
          emit-expr(s, declared) ++ ".parse-int"
        (Var("parse_float"), [s]) ->
          emit-expr(s, declared) ++ ".parse-float64"

        // Environment helpers
        (Var("get_args"), []) ->
          "get-args()"
        (Var("get_env"), [key]) ->
          "hica-get-env(" ++ emit-expr(key, declared) ++ ")"
        (Var("set_env"), [key, value]) ->
          "hica-set-env(" ++ emit-expr(key, declared) ++ ", " ++ emit-expr(value, declared) ++ ")"
        (Var("set_env_nooverwrite"), [key, value]) ->
          "hica-set-env-nooverwrite(" ++ emit-expr(key, declared) ++ ", " ++ emit-expr(value, declared) ++ ")"
        (Var("exit"), [code]) ->
          "hica-exit(" ++ emit-expr(code, declared) ++ ")"
        (Var("eprintln"), [arg]) ->
          match arg.typ
            Just(TString) -> "trace(" ++ emit-expr(arg, declared) ++ ")"
            _             -> "trace(" ++ emit-expr(arg, declared) ++ ".show)"

        // User input
        (Var("input"), [prompt]) ->
          "hica-readline-prompt(" ++ emit-expr(prompt, declared) ++ ")"
        (Var("read_file"), [p]) ->
          "(match try({ read-text-file(" ++ emit-expr(p, declared) ++ ".path) }) { Ok(hc__c) -> Right(hc__c); Error(hc__e) -> Left(hc__e.message) })"
        (Var("write_file"), [p, content]) ->
          "(match try({ write-text-file(" ++ emit-expr(p, declared) ++ ".path, " ++ emit-expr(content, declared) ++ ") }) { Ok(_) -> Right(()); Error(hc__e) -> Left(hc__e.message) })"
        (Var("exec"), [cmd]) ->
          "(match run-system-read(" ++ emit-expr(cmd, declared) ++ ") { Ok(hc__c) -> Right(hc__c); Error(hc__e) -> Left(hc__e.message) })"
        (Var("exec_args"), [cmd, args]) ->
          "(match run-system-read(" ++ emit-expr(cmd, declared) ++ " ++ \" \" ++ " ++ emit-expr(args, declared) ++ ".join(\" \")) { Ok(hc__c) -> Right(hc__c); Error(hc__e) -> Left(hc__e.message) })"

        // System clock — backed by Koka std/time
        (Var("now_unix"), []) ->
          "@default-utc { now().unix-timestamp.truncate.int }"
        (Var("now_iso"), []) ->
          "@default-utc { now().time.show-iso.trim-right }"
        (Var("unix_to_iso"), [epoch]) ->
          "@default-utc { unix-instant(" ++ emit-expr(epoch, declared) ++ ").time.show-iso.trim-right }"

        // Random numbers — hica random(min, max) is inclusive on both ends
        (Var("random"), [lo, hi]) ->
          "srandom-int32-range(" ++ emit-expr(lo, declared) ++ ".int32, (" ++ emit-expr(hi, declared) ++ " + 1).int32).int"
        (Var("random_float"), []) ->
          "srandom-float64()"

        // Formatting
        (Var("show_fixed"), [f, prec]) ->
          emit-expr(f, declared) ++ ".show-fixed(" ++ emit-expr(prec, declared) ++ ")"

        // Maybe combinators
        (Var("map_maybe"), [m, f]) ->
          match f.expr
            Fun(Cons(p, Nil), body) | body.expr.is-multiline ->
              val pn = marshal-name(p, declared)
              val m-code = emit-expr(m, declared)
              if m-code.contains("\n") then
                "val hc__mm = " ++ m-code ++ "\n" ++
                "match hc__mm\n" ++
                "  Just(" ++ pn ++ ") ->\n" ++
                indent-all(indent-all(emit-body-wrap-last("Just", body, declared))) ++ "\n" ++
                "  Nothing -> Nothing"
              else
                "match " ++ m-code ++ "\n" ++
                "  Just(" ++ pn ++ ") ->\n" ++
                indent-all(indent-all(emit-body-wrap-last("Just", body, declared))) ++ "\n" ++
                "  Nothing -> Nothing"
            Fun(Cons(p, Nil), body) ->
              val pn = marshal-name(p, declared)
              "(match " ++ emit-expr(m, declared) ++ " { Just(" ++ pn ++ ") -> Just(" ++ emit-expr(body, declared) ++ "); Nothing -> Nothing })"
            _ ->
              "(match " ++ emit-expr(m, declared) ++ " { Just(hc__v) -> Just((" ++ emit-expr(f, declared) ++ ")(hc__v)); Nothing -> Nothing })"
        (Var("and_then"), [m, f]) ->
          match f.expr
            Fun(Cons(p, Nil), body) | body.expr.is-multiline ->
              val pn = marshal-name(p, declared)
              val m-code = emit-expr(m, declared)
              if m-code.contains("\n") then
                "val hc__mm = " ++ m-code ++ "\n" ++
                "match hc__mm\n" ++
                "  Just(" ++ pn ++ ") ->\n" ++
                indent-all(indent-all(emit-body(body, declared))) ++ "\n" ++
                "  Nothing -> Nothing"
              else
                "match " ++ m-code ++ "\n" ++
                "  Just(" ++ pn ++ ") ->\n" ++
                indent-all(indent-all(emit-body(body, declared))) ++ "\n" ++
                "  Nothing -> Nothing"
            Fun(Cons(p, Nil), body) ->
              val pn = marshal-name(p, declared)
              "(match " ++ emit-expr(m, declared) ++ " { Just(" ++ pn ++ ") -> " ++ emit-expr(body, declared) ++ "; Nothing -> Nothing })"
            _ ->
              "(match " ++ emit-expr(m, declared) ++ " { Just(hc__v) -> (" ++ emit-expr(f, declared) ++ ")(hc__v); Nothing -> Nothing })"
        (Var("unwrap_maybe"), [m]) ->
          "(match " ++ emit-expr(m, declared) ++ " { Just(hc__v) -> hc__v; Nothing -> throw(\"unwrap_maybe: None\") })"
        (Var("unwrap_maybe_or"), [m, d]) ->
          emit-expr(m, declared) ++ ".default(" ++ emit-expr(d, declared) ++ ")"
        (Var("is_some"), [m]) ->
          emit-expr(m, declared) ++ ".is-just"
        (Var("is_none"), [m]) ->
          emit-expr(m, declared) ++ ".is-nothing"

        // Result combinators
        (Var("unwrap"), [r]) ->
          "(match " ++ emit-expr(r, declared) ++ " { Right(hc__v) -> hc__v; Left(hc__e) -> throw(\"unwrap: \" ++ hc__e.show) })"
        (Var("unwrap_or"), [r, d]) ->
          "(match " ++ emit-expr(r, declared) ++ " { Right(hc__v) -> hc__v; Left(_) -> " ++ emit-expr(d, declared) ++ " })"
        (Var("map_result"), [r, f]) ->
          match f.expr
            Fun(Cons(p, Nil), body) ->
              val pn = marshal-name(p, declared)
              val rc = emit-expr(r, declared)
              val bc = emit-expr(body, declared)
              if body.expr.is-multiline then
                // Multiline body (e.g. a match) — use layout-based outer match to avoid
                // Koka brace-layout conflict (nested match inside Right(...) in { } match).
                "match " ++ rc ++ "\n  Right(" ++ pn ++ ") ->\n    val hc__mr =\n      " ++ bc.replace-all("\n", "\n      ") ++ "\n    Right(hc__mr)\n  Left(hc__e) -> Left(hc__e)"
              else
                "(match " ++ rc ++ " { Right(" ++ pn ++ ") -> Right(" ++ bc ++ "); Left(hc__e) -> Left(hc__e) })"
            _ ->
              "(match " ++ emit-expr(r, declared) ++ " { Right(hc__v) -> Right((" ++ emit-expr(f, declared) ++ ")(hc__v)); Left(hc__e) -> Left(hc__e) })"
        (Var("map_err"), [r, f]) ->
          match f.expr
            Fun(Cons(p, Nil), body) ->
              val pn = marshal-name(p, declared)
              val rc = emit-expr(r, declared)
              val bc = emit-expr(body, declared)
              if body.expr.is-multiline then
                "match " ++ rc ++ "\n  Right(hc__v) -> Right(hc__v)\n  Left(" ++ pn ++ ") ->\n    val hc__mr =\n      " ++ bc.replace-all("\n", "\n      ") ++ "\n    Left(hc__mr)"
              else
                "(match " ++ rc ++ " { Right(hc__v) -> Right(hc__v); Left(" ++ pn ++ ") -> Left(" ++ bc ++ ") })"
            _ ->
              "(match " ++ emit-expr(r, declared) ++ " { Right(hc__v) -> Right(hc__v); Left(hc__e) -> Left((" ++ emit-expr(f, declared) ++ ")(hc__e)) })"
        (Var("and_then_result"), [r, f]) ->
          match f.expr
            Fun(Cons(p, Nil), body) ->
              val pn = marshal-name(p, declared)
              val rc = emit-expr(r, declared)
              val bc = emit-expr(body, declared)
              if body.expr.is-multiline then
                "match " ++ rc ++ "\n  Right(" ++ pn ++ ") ->\n    " ++ bc.replace-all("\n", "\n    ") ++ "\n  Left(hc__e) -> Left(hc__e)"
              else
                "(match " ++ rc ++ " { Right(" ++ pn ++ ") -> " ++ bc ++ "; Left(hc__e) -> Left(hc__e) })"
            _ ->
              "(match " ++ emit-expr(r, declared) ++ " { Right(hc__v) -> (" ++ emit-expr(f, declared) ++ ")(hc__v); Left(hc__e) -> Left(hc__e) })"
        (Var("is_ok"), [r]) ->
          emit-expr(r, declared) ++ ".is-right"
        (Var("is_err"), [r]) ->
          emit-expr(r, declared) ++ ".is-left"

        // Bitwise operations — convert to int32, apply op, convert back
        (Var("bit_and"), [a, b]) ->
          emit-expr(a, declared) ++ ".int32.and(" ++ emit-expr(b, declared) ++ ".int32).int"
        (Var("bit_or"), [a, b]) ->
          emit-expr(a, declared) ++ ".int32.or(" ++ emit-expr(b, declared) ++ ".int32).int"
        (Var("bit_xor"), [a, b]) ->
          emit-expr(a, declared) ++ ".int32.xor(" ++ emit-expr(b, declared) ++ ".int32).int"
        (Var("bit_not"), [a]) ->
          emit-expr(a, declared) ++ ".int32.not.int"
        (Var("bit_shl"), [a, sh]) ->
          emit-expr(a, declared) ++ ".int32.shl(" ++ emit-expr(sh, declared) ++ ").int"
        (Var("bit_shr"), [a, sh]) ->
          emit-expr(a, declared) ++ ".int32.shr(" ++ emit-expr(sh, declared) ++ ").int"

        // Test assertions — use 1-arg hc-assert to work around Koka Perceus
        // ref-counting bug with multi-arg calls inside nested match arms
        (Var("assert"), [cond]) ->
          "hc-assert(" ++ emit-expr(cond, declared) ++ ")"
        (Var("assert_true"), [cond]) ->
          "hc-assert(" ++ emit-expr(cond, declared) ++ ")"
        (Var("assert_false"), [cond]) ->
          "hc-assert(!" ++ emit-expr(cond, declared) ++ ")"
        (Var("assert_eq"), [expected, actual]) ->
          val e-code = emit-expr(expected, declared)
          val a-code = emit-expr(actual, declared)
          "hc-assert((" ++ e-code ++ ") == (" ++ a-code ++ "))"
        (Var("assert_ne"), [expected, actual]) ->
          val e-code = emit-expr(expected, declared)
          val a-code = emit-expr(actual, declared)
          "hc-assert((" ++ e-code ++ ") != (" ++ a-code ++ "))"
        (Var("assert_contains"), [lst, elem]) ->
          val l-code = emit-expr(lst, declared)
          val e-code = emit-expr(elem, declared)
          "hc-assert(" ++ l-code ++ ".any(fn(hc__el) hc__el == " ++ e-code ++ "))"
        (Var("assert_empty"), [lst]) ->
          val l-code = emit-expr(lst, declared)
          "hc-assert(" ++ l-code ++ ".is-nil)"
        (Var("assert_not_empty"), [lst]) ->
          val l-code = emit-expr(lst, declared)
          "hc-assert(!" ++ l-code ++ ".is-nil)"

        // Map operations — maps are list<(k, v)>
        (Var("map_get"), [m, key]) ->
          val m-code = emit-expr(m, declared)
          val k-code = emit-expr(key, declared)
          "(match " ++ m-code ++ ".find(fn((hc__k, _)) hc__k == " ++ k-code ++ ") { Just((_, hc__v)) -> Just(hc__v); Nothing -> Nothing })"
        (Var("map_set"), [m, key, value]) ->
          val m-code = emit-expr(m, declared)
          val k-code = emit-expr(key, declared)
          val v-code = emit-expr(value, declared)
          "(if " ++ m-code ++ ".any(fn((hc__k, _)) hc__k == " ++ k-code ++ ") then " ++ m-code ++ ".map(fn((hc__k, hc__v)) if hc__k == " ++ k-code ++ " then (" ++ k-code ++ ", " ++ v-code ++ ") else (hc__k, hc__v)) else " ++ m-code ++ " ++ [(" ++ k-code ++ ", " ++ v-code ++ ")])"
        (Var("map_remove"), [m, key]) ->
          val m-code = emit-expr(m, declared)
          val k-code = emit-expr(key, declared)
          m-code ++ ".filter(fn((hc__k, _)) hc__k != " ++ k-code ++ ")"
        (Var("map_keys"), [m]) ->
          emit-expr(m, declared) ++ ".map(fn((hc__k, _)) hc__k)"
        (Var("map_values"), [m]) ->
          emit-expr(m, declared) ++ ".map(fn((_, hc__v)) hc__v)"
        (Var("map_contains_key"), [m, key]) ->
          emit-expr(m, declared) ++ ".any(fn((hc__k, _)) hc__k == " ++ emit-expr(key, declared) ++ ")"
        (Var("map_size"), [m]) ->
          emit-expr(m, declared) ++ ".length"

        // Extended list operations
        (Var("head"), [xs]) ->
          emit-expr(xs, declared) ++ ".head"
        (Var("tail"), [xs]) ->
          emit-expr(xs, declared) ++ ".tail"
        (Var("last"), [xs]) ->
          emit-expr(xs, declared) ++ ".last"
        (Var("flat_map"), [xs, f]) ->
          val xs-code = emit-expr(xs, declared)
          val f-code = emit-expr(f, declared)
          if f.expr.is-fun-multiline then
            // Trailing-lambda form: a wrapping `)` placed after a multiline lambda
            // body (match/if/let block) is absorbed by Koka's layout parser
            // (`unexpected ")"`). Emitting `xs.flatmap fn(...) ...` avoids the paren.
            xs-code ++ ".flatmap " ++ f-code
          else
            xs-code ++ ".flatmap(" ++ f-code ++ ")"
        (Var("sort_by"), [xs, f]) ->
          val xs-code = emit-expr(xs, declared)
          val f-code = emit-expr(f, declared)
          if f.expr.is-fun-multiline then
            "hc-sort-by(" ++ xs-code ++ ") " ++ f-code
          else
            "hc-sort-by(" ++ xs-code ++ ", " ++ f-code ++ ")"

        // Float math
        (Var("sqrt"), [x]) ->
          "sqrt(" ++ emit-expr(x, declared) ++ ")"
        (Var("floor"), [x]) ->
          "floor(" ++ emit-expr(x, declared) ++ ").int"
        (Var("ceil"), [x]) ->
          "ceiling(" ++ emit-expr(x, declared) ++ ").int"
        (Var("round"), [x]) ->
          "round(" ++ emit-expr(x, declared) ++ ").int"
        (Var("to_float"), [x]) ->
          emit-expr(x, declared) ++ ".float64"

        // Char/string conversions
        (Var("chars"), [s]) ->
          emit-expr(s, declared) ++ ".list"
        (Var("from_chars"), [cs]) ->
          emit-expr(cs, declared) ++ ".string"
        (Var("chr"), [x]) ->
          emit-expr(x, declared) ++ ".char"
        (Var("ord"), [c]) ->
          emit-expr(c, declared) ++ ".int"
        (Var("char_to_string"), [c]) ->
          emit-expr(c, declared) ++ ".string"

        _ ->
          val callee-code = match callee.expr
            Var("fold")   -> "foldl"
            Var("length") -> "list/length"
            Var("cons")   -> "Cons"
            Var("show")   -> "show"
            _             -> emit-expr(callee, declared)
          // Use trailing lambda syntax when the last argument is a multiline lambda.
          // For non-trailing multiline args (e.g. `f((fn(n) { let x = ...; x }), 5)`)
          // Koka's layout parser cannot close a `fn` body block via `)`.  We use
          // IIFE hoisting instead: bind each multiline arg to a `val hc__argN`
          // inside `(fn() val hc__arg0 = ...; call(hc__arg0, rest...))()`.
          match args.reverse
            Cons(last, rest) | last.expr.is-fun-multiline ->
              val init-args = rest.reverse.map(fn(a) emit-expr(a, declared))
              val trailing = emit-expr(last, declared)
              if init-args.is-nil then
                callee-code ++ " " ++ trailing
              else
                callee-code ++ "(" ++ init-args.join(", ") ++ ") " ++ trailing
            _ ->
              val coded-args = args.map(fn(a) emit-expr(a, declared))
              if coded-args.all(fn(c) !c.contains("\n")) then
                callee-code ++ "(" ++ coded-args.join(", ") ++ ")"
              else
                // At least one non-trailing arg is multiline — IIFE-hoist each one.
                val (hoists, refs) = hoist-multiline-args(coded-args, 0)
                val inner = (hoists ++ [callee-code ++ "(" ++ refs.join(", ") ++ ")"]).join("\n")
                "(fn()\n" ++ indent-all(inner) ++ "\n)()"
    If(cond, then-e, else-e) ->
      match else-e.expr
        Block([]) ->
          // No else branch — emit statement-level if
          "if " ++ emit-expr(cond, declared) ++ " then\n" ++
          emit-branch(then-e, declared)
        _ ->
          val cond-code = emit-expr(cond, declared)
          if then-e.expr.needs-block || else-e.expr.needs-block then
            val else-part = match else-e.expr
              If(_, _, _) -> "else " ++ emit-expr(else-e, declared)
              _ -> "else\n" ++ emit-branch(else-e, declared)
            "if " ++ cond-code ++ " then\n" ++
            emit-branch(then-e, declared) ++ "\n" ++
            else-part
          else
            val then-code = emit-expr(then-e, declared)
            val else-code = emit-expr(else-e, declared)
            val single = "if " ++ cond-code ++ " then " ++ then-code ++ " else " ++ else-code
            if !then-code.contains("\n") && !else-code.contains("\n") && single.count <= 200 then
              single
            else
              val else-part = match else-e.expr
                If(_, _, _) -> "else " ++ else-code
                _ -> "else\n" ++ indent-all(else-code)
              "if " ++ cond-code ++ " then\n" ++
              indent-all(then-code) ++ "\n" ++
              else-part
    Block(stmts) ->
      stmts.map(fn(s) emit-expr(s, declared)).join("\n")
    Match(scrut, arms) ->
      val expanded = arms.flatmap(fn(a) expand-or-arm(a))
      val scrut-code = emit-expr(scrut, declared)
      val (scrut-pre, scrut-str) = if scrut-code.contains("\n") then
        ("val hc__scrut = " ++ scrut-code ++ "\n", "hc__scrut")
      else ("", scrut-code)
      scrut-pre ++ "match " ++ scrut-str ++ "\n" ++
      expanded.map(fn(a)
        val (pat-str, guard-str) = match a.pattern
          _ ->
            val gs = match a.guard
              Just(g) -> " | " ++ emit-expr(g, declared)
              Nothing -> ""
            (emit-pattern(a.pattern, declared), gs)
        val arm-body = emit-expr(a.body, declared)
        val arm-body-str = if arm-body.is-empty then "()" else arm-body
        "  " ++ pat-str ++ guard-str ++ " ->\n    " ++ arm-body-str.replace-all("\n", "\n    ")
      ).join("\n")
    Repeat(count, body) ->
      val loop-code = "repeat(" ++ emit-expr(count, declared) ++ ")\n" ++
        loop-body(body, declared)
      wrap-break-handler(body, loop-code)
    ForIn(name, start-e, end-e, body) ->
      val loop-code = "for(" ++ emit-expr(start-e, declared) ++ ", " ++ emit-expr(end-e, declared) ++ ") fn(" ++ marshal-name(name, declared) ++ ")\n" ++
        loop-body(body, declared)
      wrap-break-handler(body, loop-code)
    ForEach(name, coll, body) ->
      val loop-code = emit-expr(coll, declared) ++ ".foreach fn(" ++ marshal-name(name, declared) ++ ")\n" ++
        loop-body(body, declared)
      wrap-break-handler(body, loop-code)
    While(cond, body) ->
      val loop-code = "while { " ++ emit-expr(cond, declared) ++ " }\n" ++
        loop-body(body, declared)
      wrap-break-handler(body, loop-code)
    Loop(body) ->
      val loop-code = "while { True }\n" ++
        loop-body(body, declared)
      wrap-break-handler(body, loop-code)
    Break ->
      "hica-break()"
    Continue ->
      "hica-continue()"
    StringInterp(parts) ->
      val emitted = parts.map(fn(p) emit-interp-part(p, declared))
      "(" ++ emitted.join(" ++ ") ++ ")"
    Tuple(elems) ->
      "(" ++ elems.map(fn(e) emit-expr(e, declared)).join(", ") ++ ")"
    EList(elems) ->
      "[" ++ elems.map(fn(e) emit-expr(e, declared)).join(", ") ++ "]"
    MapLit(entries) ->
      "[" ++ entries.map(fn((k, v)) "(" ++ emit-expr(k, declared) ++ ", " ++ emit-expr(v, declared) ++ ")").join(", ") ++ "]"
    ESome(value) ->
      "Just(" ++ emit-expr(value, declared) ++ ")"
    ENone ->
      "Nothing"
    EOk(value) ->
      "Right(" ++ emit-expr(value, declared) ++ ")"
    EErr(value) ->
      "Left(" ++ emit-expr(value, declared) ++ ")"
    ETry(inner) ->
      val inner-code = emit-expr(inner, declared)
      match inner.typ
        Just(TResult(_, _)) ->
          "match " ++ inner-code ++ "\n  Right(hc__v) -> hc__v\n  Left(hc__e) -> hica-early-err(hc__e)"
        Just(TMaybe(_)) ->
          "match " ++ inner-code ++ "\n  Just(hc__v) -> hc__v\n  Nothing -> hica-early-none()"
        _ ->
          // Fallback — assume result
          "match " ++ inner-code ++ "\n  Right(hc__v) -> hc__v\n  Left(hc__e) -> hica-early-err(hc__e)"
    ListIndex(lst, idx) ->
      val lst-code = emit-expr(lst, declared)
      val idx-code = emit-expr(idx, declared)
      match lst.typ
        Just(TString) ->
          match idx.expr
            Unary(Neg, _) ->
              lst-code ++ ".list[" ++ lst-code ++ ".list.length + " ++ idx-code ++ "].unjust"
            _ ->
              lst-code ++ ".list[" ++ idx-code ++ "].unjust"
        _ ->
          match idx.expr
            Unary(Neg, _) ->
              lst-code ++ "[" ++ lst-code ++ ".length + " ++ idx-code ++ "].unjust"
            _ ->
              lst-code ++ "[" ++ idx-code ++ "].unjust"
    ListSlice(lst, start-m, end-m) ->
      val lst-code = emit-expr(lst, declared)
      match lst.typ
        Just(TString) ->
          val l = lst-code ++ ".list"
          fun adj(nd)
            val code = emit-expr(nd, declared)
            match nd.expr
              Unary(Neg, _) -> "(" ++ l ++ ".list/length + " ++ code ++ ")"
              _             -> code
          match start-m
            Just(s) -> match end-m
              Just(e) -> l ++ ".drop(" ++ adj(s) ++ ").take((" ++ adj(e) ++ ") - (" ++ adj(s) ++ ")).string"
              Nothing -> l ++ ".drop(" ++ adj(s) ++ ").string"
            Nothing -> match end-m
              Just(e) -> l ++ ".take(" ++ adj(e) ++ ").string"
              Nothing -> lst-code  // s[:] — identity
        _ ->
          fun adj(nd)
            val code = emit-expr(nd, declared)
            match nd.expr
              Unary(Neg, _) -> "(" ++ lst-code ++ ".list/length + " ++ code ++ ")"
              _             -> code
          match start-m
            Just(s) -> match end-m
              Just(e) -> lst-code ++ ".drop(" ++ adj(s) ++ ").take((" ++ adj(e) ++ ") - (" ++ adj(s) ++ "))"
              Nothing -> lst-code ++ ".drop(" ++ adj(s) ++ ")"
            Nothing -> match end-m
              Just(e) -> lst-code ++ ".take(" ++ adj(e) ++ ")"
              Nothing -> lst-code  // list[:] — identity
    TupleIndex(tup, idx) ->
      emit-expr(tup, declared) ++ "." ++ tuple-field-name(idx)
    LetTuple(names, init, body) ->
      "val (" ++ names.map(fn(nm) marshal-name(nm, declared)).join(", ") ++ ") = " ++ emit-expr(init, declared) ++ "\n" ++ emit-expr(body, declared)
    StructLit(sname, fields) ->
      sname ++ "(" ++ fields.map(fn((_, v)) emit-expr(v, declared)).join(", ") ++ ")"
    StructUpdate(sname, base, overrides, def-fields) ->
      // Emit as an IIFE so the binding works in both expression and assignment
      // (`:=` position) contexts. `{ val hc__base = ...; ... }` is a Koka block
      // (thunk), not an expression, so it is rejected on the RHS of `:=`.
      val base-code = emit-expr(base, declared)
      val args = def-fields.map fn(fname)
        match overrides.find(fn((nm, _)) nm == fname)
          Just((_, fval)) -> emit-expr(fval, declared)
          Nothing -> "hc__base." ++ marshal-field(fname)
      "(fn(hc__base) " ++ sname ++ "(" ++ args.join(", ") ++ "))(" ++ base-code ++ ")"
    FieldAccess(obj, fname) ->
      val obj-is-struct = match obj.typ
        Just(TStruct(_)) -> True
        _                -> False
      val emitted-name = if obj-is-struct then marshal-field(fname) else marshal-name(fname, declared)
      emit-expr(obj, declared) ++ "." ++ emitted-name
    EConstructor(cname, cargs) ->
      if cargs.is-nil then cname
      else cname ++ "(" ++ cargs.map(fn(a) emit-expr(a, declared)).join(", ") ++ ")"

fun emit-interp-part( p : node, declared : list<string> ) : div string
  match p.expr
    Literal(LitString(s)) -> "\"" ++ s ++ "\""
    _ ->
      val inner = emit-expr(p, declared)
      match p.typ
        Just(TInt)    -> "int/show(" ++ inner ++ ")"
        Just(TFloat)  -> "float64/show(" ++ inner ++ ")"
        Just(TBool)   -> "bool/show(" ++ inner ++ ")"
        Just(TChar)   -> inner ++ ".string"
        Just(TString) -> inner
        Just(TTuple(_)) -> inner ++ ".show"
        Just(TList(_))  -> inner ++ ".show"
        Just(TMaybe(_)) -> inner ++ ".show"
        Just(TResult(_, _)) -> inner ++ ".show"
        Just(TStruct(sn)) -> sn.struct-type-name ++ "/show(" ++ inner ++ ")"
        Just(TEnum(en))  -> en.to-lower ++ "/show(" ++ inner ++ ")"
        _             -> inner  // TVar or unknown — emit directly, Koka infers string from ++

// Expand or-patterns: POr([p1, p2, p3]) becomes three separate arms
fun expand-or-arm( a : match-arm ) : list<match-arm>
  match a.pattern
    POr(alts) -> alts.map(fn(p) Match-arm(p, a.guard, a.body))
    _         -> [a]

fun emit-pattern( p : pattern, declared : list<string> ) : div string
  match p
    PWild    -> "_"
    PVar(n)  -> marshal-name(n, declared)
    PLit(l)  -> l.show
    PSome(i) -> "Just(" ++ emit-pattern(i, declared) ++ ")"
    PNone    -> "Nothing"
    POk(i)   -> "Right(" ++ emit-pattern(i, declared) ++ ")"
    PErr(i)  -> "Left(" ++ emit-pattern(i, declared) ++ ")"
    PTuple(es) -> "(" ++ es.map(fn(e) emit-pattern(e, declared)).join(", ") ++ ")"
    POr(alts)  -> alts.map(fn(a) emit-pattern(a, declared)).join(" | ")
    PConstructor(cname, args) ->
      if args.is-nil then cname
      else cname ++ "(" ++ args.map(fn(a) emit-pattern(a, declared)).join(", ") ++ ")"
    PStruct(sname, fps, defs) ->
      val ordered = defs.map fn(fname)
        match fps.find(fn((n, _)) n == fname)
          Just((_, fpat)) -> emit-pattern(fpat, declared)
          Nothing         -> "_"
      sname ++ "(" ++ ordered.join(", ") ++ ")"
    PList(elems, rest) ->
      val tail-str = match rest
        Nothing  -> "Nil"
        Just(rp) -> emit-pattern(rp, declared)
      elems.foldr(tail-str) fn(ep, acc)
        "Cons(" ++ emit-pattern(ep, declared) ++ ", " ++ acc ++ ")"
    PRange(_, _) -> "_"  // desugared before codegen
    PBits(_, _)  -> "_"  // desugared before codegen

fun emit-binop( op : binop ) : string
  match op
    Add -> "+"
    Sub -> "-"
    Mul -> "*"
    Div -> "/"
    Mod -> "%"
    Eq  -> "=="
    Neq -> "!="
    Lt  -> "<"
    Gt  -> ">"
    Le  -> "<="
    Ge  -> ">="
    And -> "&&"
    Or  -> "||"
    In  -> "in"  // never reached — handled specially above

fun repeat-body( e : expr, declared : list<string> ) : div string
  match e
    Block(stmts) -> stmts.map(fn(s) indent-all(emit-stmt(s, declared))).join("\n")
    _            -> indent-all(emit-stmt(Node(no-span, e), declared))

// Emit loop body with continue handler prepended if needed.
fun loop-body( body : node, declared : list<string> ) : div string
  val has-cont = body-has-continue(body)
  if has-cont then
    val cont-header = indent-all("with handler\n  ctl hica-continue() -> ()")
    val body-code = body.expr.repeat-body(declared)
    cont-header ++ "\n" ++ body-code
  else
    body.expr.repeat-body(declared)

// Indent all lines of a string by 2 spaces.
fun indent-all( s : string ) : string
  s.split("\n").map(fn(line) "  " ++ line).join("\n")

// Check if a function body calls any name from a list (e.g. recursive functions).
fun body-calls-any( n : node, names : list<string> ) : div bool
  match n.expr
    Var(v)                    -> names.any(fn(nm) nm == v)
    Call(callee, args)        -> body-calls-any(callee, names) || args.any(fn(a) body-calls-any(a, names))
    Binary(_, l, r)           -> body-calls-any(l, names) || body-calls-any(r, names)
    Unary(_, o)               -> body-calls-any(o, names)
    Let(_, _, init, body)     -> body-calls-any(init, names) || body-calls-any(body, names)
    VarDecl(_, _, init, body) -> body-calls-any(init, names) || body-calls-any(body, names)
    Assign(_, value)          -> body-calls-any(value, names)
    LetTuple(_, init, body)   -> body-calls-any(init, names) || body-calls-any(body, names)
    Block(stmts)              -> stmts.any(fn(st) body-calls-any(st, names))
    If(cond, th, el)          -> body-calls-any(cond, names) || body-calls-any(th, names) || body-calls-any(el, names)
    Match(scrut, arms)        -> body-calls-any(scrut, names) || arms.any(fn(a) body-calls-any(a.body, names))
    Fun(_, body)              -> body-calls-any(body, names)
    EConstructor(_, args)     -> args.any(fn(a) body-calls-any(a, names))
    ESome(v)                  -> body-calls-any(v, names)
    EOk(v)                    -> body-calls-any(v, names)
    EErr(v)                   -> body-calls-any(v, names)
    ETry(v)                   -> body-calls-any(v, names)
    FieldAccess(obj, _)       -> body-calls-any(obj, names)
    TupleIndex(t, _)          -> body-calls-any(t, names)
    Tuple(elems)              -> elems.any(fn(e) body-calls-any(e, names))
    EList(elems)              -> elems.any(fn(e) body-calls-any(e, names))
    StringInterp(parts)       -> parts.any(fn(p) body-calls-any(p, names))
    StructLit(_, fields)      -> fields.any(fn(f) body-calls-any(f.snd, names))
    StructUpdate(_, base, fields, _) -> body-calls-any(base, names) || fields.any(fn(f) body-calls-any(f.snd, names))
    ListIndex(l, i)           -> body-calls-any(l, names) || body-calls-any(i, names)
    ListSlice(l, s, e)        -> body-calls-any(l, names) || s.map(fn(x) body-calls-any(x, names)).default(False) || e.map(fn(x) body-calls-any(x, names)).default(False)
    MapLit(entries)           -> entries.any(fn(e) body-calls-any(e.fst, names) || body-calls-any(e.snd, names))
    ForEach(_, coll, body)    -> body-calls-any(coll, names) || body-calls-any(body, names)
    While(cond, body)         -> body-calls-any(cond, names) || body-calls-any(body, names)
    Loop(body)                -> body-calls-any(body, names)
    _                         -> False

// Compute the transitive closure of div-needing names.
// Seed: all self-recursive functions. Then iteratively add any function whose
// body calls a div-needing function, until no new names are added.
fun compute-div-names( decls : list<fun-decl> ) : div list<string>
  var div-names := decls.filter(fn(d) d.is-recursive).map(fn(d) d.name)
  var changed := True
  while { changed }
    changed := False
    decls.foreach fn(d)
      val already = div-names.any(fn(nm) nm == d.name)
      if !already && body-calls-any(d.body, div-names) then
        div-names := Cons(d.name, div-names)
        changed := True
  div-names

// Compute the set of decl names reachable from `starts` through the call graph
// (transitive closure over direct calls). The starts themselves are included.
fun reachable-from( decls : list<fun-decl>, starts : list<string> ) : div list<string>
  var seen := starts
  var changed := True
  while { changed }
    changed := False
    decls.foreach fn(d)
      if seen.any(fn(nm) nm == d.name) then
        decls.foreach fn(e)
          if !seen.any(fn(nm) nm == e.name) && body-calls-any(d.body, [e.name]) then
            seen := Cons(e.name, seen)
            changed := True
  seen

// Expand a seed list of function names to the full mutual-recursion SCC.
// Starting from seed (all is-recursive functions with `?`), adds any is-recursive
// function that lies on a *cycle* with the seed: the seed can reach it AND it can
// reach back to the seed. Every member of the SCC receives the __work treatment so
// that the handler-wrapper functions are not themselves part of the recursive cycle.
//
// A one-directional caller (e.g. a tuple-returning function that merely calls a
// `?`-using function without being called back) is deliberately excluded: it must
// call the handler-installing wrapper and must NOT be given a result-returning
// handler, which would corrupt its non-result return type
// (`either<_a,_b>` vs `(list<T>, int)`).
fun expand-try-rec-names( decls : list<fun-decl>, seed : list<string> ) : div list<string>
  if seed.is-nil then return []
  // Functions the seed can reach (forward reachability through the call graph).
  val forward = reachable-from(decls, seed)
  decls.filter(fn(d)
    val in-seed = seed.any(fn(nm) nm == d.name)
    if in-seed then True
    elif !d.is-recursive then False
    else
      val seed-reaches-d = forward.any(fn(nm) nm == d.name)
      val d-reaches-seed = reachable-from(decls, [d.name]).any(fn(nm) seed.any(fn(s) s == nm))
      seed-reaches-d && d-reaches-seed
  ).map(fn(d) d.name)

// Map a 0-based tuple index to Koka's named accessor.
fun tuple-field-name( idx : int ) : string
  match idx
    0 -> "fst"
    1 -> "snd"
    2 -> "thd"
    n -> "field" ++ (n + 1).show

// Extract element type annotation from a list-typed node (for sort codegen).
fun list-elem-ann( n : node ) : div string
  match n.typ
    Just(TList(t)) ->
      val ts = emit-type(t)
      if ts == "" then "" else " : " ++ ts
    _ -> ""

// ---------------------------------------------------------------------------
// Float detection: check if the program contains any float literals
// ---------------------------------------------------------------------------

// Check if an expression needs parenthesised block wrapping in if-then-else branches
fun needs-block( e : expr ) : bool
  match e
    Let(_, _, _, _)     -> True
    VarDecl(_, _, _, _) -> True
    Assign(_, _)        -> True
    LetTuple(_, _, _)   -> True
    Match(_, _)         -> True
    Block(Cons(s, Nil)) -> match s.expr
      Let(_, _, _, _)     -> True
      VarDecl(_, _, _, _) -> True
      Assign(_, _)        -> True
      LetTuple(_, _, _)   -> True
      Match(_, _)         -> True
      Block(_)            -> True
      _                   -> False
    Block(_)            -> True
    _                   -> False

// Check if an expression produces multiple lines (needs indented block in lambda body).
// Total (non-recursive) — safe to use in Koka guard expressions.
fun is-multiline( e : expr ) : bool
  match e
    Let(_, _, _, _)     -> True
    VarDecl(_, _, _, _) -> True
    LetTuple(_, _, _)   -> True
    Match(_, _)         -> True
    // If-then-else is always treated as multiline: Koka emits the then/else branches
    // on separate indented lines, so a trailing `)` from a surrounding call would
    // be stuck to the last line of the else branch, breaking layout parsing.
    // Using trailing lambda syntax avoids this entirely.
    If(_, _, _)         -> True
    Block(Cons(s, Nil)) -> match s.expr
      Let(_, _, _, _)     -> True
      VarDecl(_, _, _, _) -> True
      LetTuple(_, _, _)   -> True
      Match(_, _)         -> True
      If(_, _, _)         -> True
      _                   -> False
    Block(stmts)        -> stmts.length > 1
    // map_result / map_err / and_then_result with a match-body lambda are multiline.
    // Use a shallow check (not recursive) to keep this function total.
    Call(callee, args)  -> match (callee.expr, args)
      (Var(nm), [_, f]) | (nm == "map_result" || nm == "map_err" || nm == "and_then_result") ->
        match f.expr
          Fun(_, body) -> is-multiline-shallow(body.expr)
          _            -> False
      _ -> False
    _                   -> False

// Shallow version of is-multiline: checks only the top-level node type, no recursion.
// Used to avoid div in the Call case of is-multiline.
fun is-multiline-shallow( e : expr ) : bool
  match e
    Let(_, _, _, _)     -> True
    VarDecl(_, _, _, _) -> True
    LetTuple(_, _, _)   -> True
    Match(_, _)         -> True
    If(_, _, _)         -> True
    Block(Cons(s, Nil)) -> match s.expr
      Let(_, _, _, _)     -> True
      VarDecl(_, _, _, _) -> True
      LetTuple(_, _, _)   -> True
      Match(_, _)         -> True
      If(_, _, _)         -> True
      _                   -> False
    Block(stmts)        -> stmts.length > 1
    _                   -> False

// Check if an expression is a Fun (lambda) with a multiline body
fun is-fun-multiline( e : expr ) : bool
  match e
    Fun(_, body) -> body.expr.is-multiline
    _            -> False

// Emit an if-branch as an indented block.
fun emit-branch( n : node, declared : list<string> ) : div string
  match n.expr
    Block(stmts) ->
      val code = stmts.map(fn(s) indent-all(emit-stmt(s, declared))).join("\n")
      // Empty block must still emit a valid expression in Koka
      if code.is-empty then "  ()" else code
    _            -> indent-all(emit-stmt(n, declared))

fun program-has-float( p : program ) : div bool
  p.decls.any(fn(d) node-has-float(d.body) || d.param-types.any(fn(t) t.has-float-type) || d.ret-type.map(fn(t) t.has-float-type).default(False)) ||
  p.types.any(fn(td) td.variants.any(fn(vd) vd.fields.any(fn((_, ft)) ft.has-float-type))) ||
  p.structs.any(fn(sd) sd.fields.any(fn((_, ft)) ft.has-float-type))

fun has-float-type( t : hica-type ) : div bool
  match t
    TFloat -> True
    TList(e) -> e.has-float-type
    TMaybe(e) -> e.has-float-type
    TResult(o, e) -> o.has-float-type || e.has-float-type
    TTuple(es) -> es.any(fn(e) e.has-float-type)
    TFun(ps, r) -> ps.any(fn(p) p.has-float-type) || r.has-float-type
    _ -> False

fun is-parse-float( e : expr ) : bool
  match e
    Var("parse_float") -> True
    _                  -> False

fun node-has-float( n : node ) : div bool
  val typ-float = match n.typ
    Just(t) -> t.has-float-type
    Nothing -> False
  if typ-float then True
  else match n.expr
    Literal(LitFloat(_)) -> True
    Call(callee, _) | callee.expr.is-parse-float -> True
    Let(_, _, init, body) -> node-has-float(init) || node-has-float(body)
    VarDecl(_, _, init, body) -> node-has-float(init) || node-has-float(body)
    Assign(_, value)      -> node-has-float(value)
    Fun(_, body)          -> node-has-float(body)
    Call(callee, args)    -> node-has-float(callee) || args.any(fn(a) node-has-float(a))
    Binary(_, lhs, rhs)   -> node-has-float(lhs) || node-has-float(rhs)
    Unary(_, operand)     -> node-has-float(operand)
    If(c, t, e)           -> node-has-float(c) || node-has-float(t) || node-has-float(e)
    Block(stmts)          -> stmts.any(fn(s) node-has-float(s))
    Match(scrut, arms)    -> node-has-float(scrut) || arms.any(fn(a) node-has-float(a.body) || a.guard.map(node-has-float).default(False))
    Repeat(count, body)   -> node-has-float(count) || node-has-float(body)
    ForIn(_, start-e, end-e, body) -> node-has-float(start-e) || node-has-float(end-e) || node-has-float(body)
    ForEach(_, coll, body) -> node-has-float(coll) || node-has-float(body)
    While(cond, body)      -> node-has-float(cond) || node-has-float(body)
    Loop(body)             -> node-has-float(body)
    StringInterp(parts)   -> parts.any(fn(p) node-has-float(p))
    Tuple(elems)           -> elems.any(fn(e) node-has-float(e))
    EList(elems)            -> elems.any(fn(e) node-has-float(e))
    ListIndex(lst, idx)     -> node-has-float(lst) || node-has-float(idx)
    ListSlice(lst, s, e)    -> node-has-float(lst) || s.map(node-has-float).default(False) || e.map(node-has-float).default(False)
    TupleIndex(tup, _)     -> node-has-float(tup)
    LetTuple(_, init, body) -> node-has-float(init) || node-has-float(body)
    ESome(v)                -> node-has-float(v)
    EOk(v)                  -> node-has-float(v)
    EErr(v)                 -> node-has-float(v)
    StructLit(_, fs)        -> fs.any(fn((_, v)) node-has-float(v))
    FieldAccess(o, _)       -> node-has-float(o)
    EConstructor(_, cargs)  -> cargs.any(fn(a) node-has-float(a))
    MapLit(entries)         -> entries.any(fn((k, v)) node-has-float(k) || node-has-float(v))
    _                     -> False

// Check whether the body contains a while or loop node.  These always carry
// the `div` effect in Koka, so an explicit return-type annotation must be
// suppressed (otherwise Koka rejects the pure signature).
fun node-has-while( n : node ) : div bool
  match n.expr
    While(_, _)                    -> True
    Loop(_)                        -> True
    Let(_, _, init, body)          -> node-has-while(init) || node-has-while(body)
    VarDecl(_, _, init, body)      -> node-has-while(init) || node-has-while(body)
    Assign(_, value)               -> node-has-while(value)
    Fun(_, body)                   -> node-has-while(body)
    Call(callee, args)             -> node-has-while(callee) || args.any(fn(a) node-has-while(a))
    Binary(_, lhs, rhs)            -> node-has-while(lhs) || node-has-while(rhs)
    Unary(_, operand)              -> node-has-while(operand)
    If(c, t, e)                    -> node-has-while(c) || node-has-while(t) || node-has-while(e)
    Block(stmts)                   -> stmts.any(fn(s) node-has-while(s))
    Match(scrut, arms)             -> node-has-while(scrut) || arms.any(fn(a) node-has-while(a.body))
    Repeat(count, body)            -> node-has-while(count) || node-has-while(body)
    ForIn(_, s, e, body)           -> node-has-while(s) || node-has-while(e) || node-has-while(body)
    ForEach(_, coll, body)         -> node-has-while(coll) || node-has-while(body)
    StringInterp(parts)            -> parts.any(fn(p) node-has-while(p))
    Tuple(elems)                   -> elems.any(fn(e) node-has-while(e))
    EList(elems)                   -> elems.any(fn(e) node-has-while(e))
    ListIndex(lst, idx)            -> node-has-while(lst) || node-has-while(idx)
    ListSlice(lst, s, e)           -> node-has-while(lst) || s.map(node-has-while).default(False) || e.map(node-has-while).default(False)
    TupleIndex(tup, _)             -> node-has-while(tup)
    LetTuple(_, init, body)        -> node-has-while(init) || node-has-while(body)
    ESome(v)                       -> node-has-while(v)
    EOk(v)                         -> node-has-while(v)
    EErr(v)                        -> node-has-while(v)
    StructLit(_, fs)               -> fs.any(fn((_, v)) node-has-while(v))
    FieldAccess(o, _)              -> node-has-while(o)
    EConstructor(_, cargs)         -> cargs.any(fn(a) node-has-while(a))
    MapLit(entries)                -> entries.any(fn((k, v)) node-has-while(k) || node-has-while(v))
    _                              -> False

// Check whether the program uses get_args — needs `import std/os/env`.
fun program-uses-get-args( p : program ) : div bool
  p.decls.any(fn(d) node-uses-get-args(d.body))

fun node-uses-get-args( n : node ) : div bool
  match n.expr
    Call(callee, args) ->
      val is-get-args = match callee.expr
        Var("get_args") -> True
        _               -> False
      is-get-args || node-uses-get-args(callee) || args.any(fn(a) node-uses-get-args(a))
    Let(_, _, init, body) -> node-uses-get-args(init) || node-uses-get-args(body)
    VarDecl(_, _, init, body) -> node-uses-get-args(init) || node-uses-get-args(body)
    Assign(_, value)      -> node-uses-get-args(value)
    Fun(_, body)          -> node-uses-get-args(body)
    Binary(_, lhs, rhs)   -> node-uses-get-args(lhs) || node-uses-get-args(rhs)
    Unary(_, operand)     -> node-uses-get-args(operand)
    If(c, t, e)           -> node-uses-get-args(c) || node-uses-get-args(t) || node-uses-get-args(e)
    Block(stmts)          -> stmts.any(fn(s) node-uses-get-args(s))
    Match(scrut, arms)    -> node-uses-get-args(scrut) || arms.any(fn(a) node-uses-get-args(a.body) || a.guard.map(node-uses-get-args).default(False))
    Repeat(count, body)   -> node-uses-get-args(count) || node-uses-get-args(body)
    ForIn(_, s, e, body)  -> node-uses-get-args(s) || node-uses-get-args(e) || node-uses-get-args(body)
    ForEach(_, coll, body) -> node-uses-get-args(coll) || node-uses-get-args(body)
    While(cond, body)      -> node-uses-get-args(cond) || node-uses-get-args(body)
    Loop(body)             -> node-uses-get-args(body)
    StringInterp(parts)   -> parts.any(fn(p) node-uses-get-args(p))
    LetTuple(_, init, body) -> node-uses-get-args(init) || node-uses-get-args(body)
    EConstructor(_, cargs)  -> cargs.any(fn(a) node-uses-get-args(a))
    Tuple(elems)            -> elems.any(fn(e) node-uses-get-args(e))
    TupleIndex(t, _)        -> node-uses-get-args(t)
    _                       -> False

// Check whether the program uses get_env — needs `hica-get-env` C helper.
fun program-uses-get-env( p : program ) : div bool
  p.decls.any(fn(d) node-uses-get-env(d.body))

fun node-uses-get-env( n : node ) : div bool
  match n.expr
    Call(callee, args) ->
      val is-get-env = match callee.expr
        Var("get_env")  -> True
        _               -> False
      is-get-env || node-uses-get-env(callee) || args.any(fn(a) node-uses-get-env(a))
    Let(_, _, init, body) -> node-uses-get-env(init) || node-uses-get-env(body)
    VarDecl(_, _, init, body) -> node-uses-get-env(init) || node-uses-get-env(body)
    Assign(_, value)      -> node-uses-get-env(value)
    Fun(_, body)          -> node-uses-get-env(body)
    Binary(_, lhs, rhs)   -> node-uses-get-env(lhs) || node-uses-get-env(rhs)
    Unary(_, operand)     -> node-uses-get-env(operand)
    If(c, t, e)           -> node-uses-get-env(c) || node-uses-get-env(t) || node-uses-get-env(e)
    Block(stmts)          -> stmts.any(fn(s) node-uses-get-env(s))
    Match(scrut, arms)    -> node-uses-get-env(scrut) || arms.any(fn(a) node-uses-get-env(a.body) || a.guard.map(node-uses-get-env).default(False))
    Repeat(count, body)   -> node-uses-get-env(count) || node-uses-get-env(body)
    ForIn(_, s, e, body)  -> node-uses-get-env(s) || node-uses-get-env(e) || node-uses-get-env(body)
    ForEach(_, coll, body) -> node-uses-get-env(coll) || node-uses-get-env(body)
    While(cond, body)      -> node-uses-get-env(cond) || node-uses-get-env(body)
    Loop(body)             -> node-uses-get-env(body)
    StringInterp(parts)   -> parts.any(fn(p) node-uses-get-env(p))
    LetTuple(_, init, body) -> node-uses-get-env(init) || node-uses-get-env(body)
    EConstructor(_, cargs)  -> cargs.any(fn(a) node-uses-get-env(a))
    Tuple(elems)            -> elems.any(fn(e) node-uses-get-env(e))
    TupleIndex(t, _)        -> node-uses-get-env(t)
    _                       -> False

// Legacy alias used in emit-program and emit-test-program env-import detection.
fun program-uses-env( p : program ) : div bool
  program-uses-get-args(p)

// Check whether the program uses file I/O functions (read_file, write_file)
// that require `import std/os/file` and `import std/os/path`.
fun program-uses-file-io( p : program ) : div bool
  p.decls.any(fn(d) node-uses-file-io(d.body))

fun node-uses-file-io( n : node ) : div bool
  match n.expr
    Call(callee, args) ->
      val is-io-fn = match callee.expr
        Var("read_file")  -> True
        Var("write_file") -> True
        _                 -> False
      is-io-fn || node-uses-file-io(callee) || args.any(fn(a) node-uses-file-io(a))
    Let(_, _, init, body) -> node-uses-file-io(init) || node-uses-file-io(body)
    VarDecl(_, _, init, body) -> node-uses-file-io(init) || node-uses-file-io(body)
    Assign(_, value)      -> node-uses-file-io(value)
    Fun(_, body)          -> node-uses-file-io(body)
    Binary(_, lhs, rhs)   -> node-uses-file-io(lhs) || node-uses-file-io(rhs)
    Unary(_, operand)     -> node-uses-file-io(operand)
    If(c, t, e)           -> node-uses-file-io(c) || node-uses-file-io(t) || node-uses-file-io(e)
    Block(stmts)          -> stmts.any(fn(s) node-uses-file-io(s))
    Match(scrut, arms)    -> node-uses-file-io(scrut) || arms.any(fn(a) node-uses-file-io(a.body) || a.guard.map(node-uses-file-io).default(False))
    Repeat(count, body)   -> node-uses-file-io(count) || node-uses-file-io(body)
    ForIn(_, s, e, body)  -> node-uses-file-io(s) || node-uses-file-io(e) || node-uses-file-io(body)
    ForEach(_, coll, body) -> node-uses-file-io(coll) || node-uses-file-io(body)
    While(cond, body)      -> node-uses-file-io(cond) || node-uses-file-io(body)
    Loop(body)             -> node-uses-file-io(body)
    StringInterp(parts)   -> parts.any(fn(p) node-uses-file-io(p))
    LetTuple(_, init, body) -> node-uses-file-io(init) || node-uses-file-io(body)
    EConstructor(_, cargs)  -> cargs.any(fn(a) node-uses-file-io(a))
    Tuple(elems)            -> elems.any(fn(e) node-uses-file-io(e))
    TupleIndex(t, _)        -> node-uses-file-io(t)
    _                       -> False

// Check whether the program uses exec/exec_args
// that require `import std/os/process`.
fun program-uses-exec( p : program ) : div bool
  p.decls.any(fn(d) node-uses-exec(d.body))

fun node-uses-exec( n : node ) : div bool
  match n.expr
    Call(callee, args) ->
      val is-exec-fn = match callee.expr
        Var("exec")      -> True
        Var("exec_args") -> True
        _                -> False
      is-exec-fn || node-uses-exec(callee) || args.any(fn(a) node-uses-exec(a))
    Let(_, _, init, body) -> node-uses-exec(init) || node-uses-exec(body)
    VarDecl(_, _, init, body) -> node-uses-exec(init) || node-uses-exec(body)
    Assign(_, value)      -> node-uses-exec(value)
    Fun(_, body)          -> node-uses-exec(body)
    Binary(_, lhs, rhs)   -> node-uses-exec(lhs) || node-uses-exec(rhs)
    Unary(_, operand)     -> node-uses-exec(operand)
    If(c, t, e)           -> node-uses-exec(c) || node-uses-exec(t) || node-uses-exec(e)
    Block(stmts)          -> stmts.any(fn(s) node-uses-exec(s))
    Match(scrut, arms)    -> node-uses-exec(scrut) || arms.any(fn(a) node-uses-exec(a.body) || a.guard.map(node-uses-exec).default(False))
    Repeat(count, body)   -> node-uses-exec(count) || node-uses-exec(body)
    ForIn(_, s, e, body)  -> node-uses-exec(s) || node-uses-exec(e) || node-uses-exec(body)
    ForEach(_, coll, body) -> node-uses-exec(coll) || node-uses-exec(body)
    While(cond, body)      -> node-uses-exec(cond) || node-uses-exec(body)
    Loop(body)             -> node-uses-exec(body)
    StringInterp(parts)   -> parts.any(fn(p) node-uses-exec(p))
    LetTuple(_, init, body) -> node-uses-exec(init) || node-uses-exec(body)
    EConstructor(_, cargs)  -> cargs.any(fn(a) node-uses-exec(a))
    Tuple(elems)            -> elems.any(fn(e) node-uses-exec(e))
    TupleIndex(t, _)        -> node-uses-exec(t)
    _                       -> False

// Check whether the program uses the input() function
// that requires `import std/os/readline`.
fun program-uses-random( p : program ) : div bool
  p.decls.any(fn(d) node-uses-random(d.body))

fun node-uses-random( n : node ) : div bool
  match n.expr
    Call(callee, args) ->
      val is-random-fn = match callee.expr
        Var("random")       -> True
        Var("random_float") -> True
        _                   -> False
      is-random-fn || node-uses-random(callee) || args.any(fn(a) node-uses-random(a))
    Let(_, _, init, body) -> node-uses-random(init) || node-uses-random(body)
    VarDecl(_, _, init, body) -> node-uses-random(init) || node-uses-random(body)
    Assign(_, value)      -> node-uses-random(value)
    Fun(_, body)          -> node-uses-random(body)
    Binary(_, lhs, rhs)   -> node-uses-random(lhs) || node-uses-random(rhs)
    Unary(_, operand)     -> node-uses-random(operand)
    If(c, t, e)           -> node-uses-random(c) || node-uses-random(t) || node-uses-random(e)
    Block(stmts)          -> stmts.any(fn(s) node-uses-random(s))
    Match(scrut, arms)    -> node-uses-random(scrut) || arms.any(fn(a) node-uses-random(a.body) || a.guard.map(node-uses-random).default(False))
    Repeat(count, body)   -> node-uses-random(count) || node-uses-random(body)
    ForIn(_, s, e, body)  -> node-uses-random(s) || node-uses-random(e) || node-uses-random(body)
    ForEach(_, coll, body) -> node-uses-random(coll) || node-uses-random(body)
    While(cond, body)      -> node-uses-random(cond) || node-uses-random(body)
    Loop(body)             -> node-uses-random(body)
    StringInterp(parts)   -> parts.any(fn(p) node-uses-random(p))
    LetTuple(_, init, body) -> node-uses-random(init) || node-uses-random(body)
    EConstructor(_, cargs)  -> cargs.any(fn(a) node-uses-random(a))
    Tuple(elems)            -> elems.any(fn(e) node-uses-random(e))
    TupleIndex(t, _)        -> node-uses-random(t)
    _                       -> False

fun program-uses-bitwise( p : program ) : div bool
  p.decls.any(fn(d) node-uses-bitwise(d.body))

fun node-uses-bitwise( n : node ) : div bool
  match n.expr
    Call(callee, args) ->
      val is-bitwise-fn = match callee.expr
        Var("bit_and") -> True
        Var("bit_or")  -> True
        Var("bit_xor") -> True
        Var("bit_not") -> True
        Var("bit_shl") -> True
        Var("bit_shr") -> True
        _              -> False
      is-bitwise-fn || node-uses-bitwise(callee) || args.any(fn(a) node-uses-bitwise(a))
    Let(_, _, init, body) -> node-uses-bitwise(init) || node-uses-bitwise(body)
    VarDecl(_, _, init, body) -> node-uses-bitwise(init) || node-uses-bitwise(body)
    Assign(_, value)      -> node-uses-bitwise(value)
    Fun(_, body)          -> node-uses-bitwise(body)
    Binary(_, lhs, rhs)   -> node-uses-bitwise(lhs) || node-uses-bitwise(rhs)
    Unary(_, operand)     -> node-uses-bitwise(operand)
    If(c, t, e)           -> node-uses-bitwise(c) || node-uses-bitwise(t) || node-uses-bitwise(e)
    Block(stmts)          -> stmts.any(fn(s) node-uses-bitwise(s))
    Match(scrut, arms)    -> node-uses-bitwise(scrut) || arms.any(fn(a) arm-uses-bitwise(a))
    Repeat(count, body)   -> node-uses-bitwise(count) || node-uses-bitwise(body)
    ForIn(_, s, e, body)  -> node-uses-bitwise(s) || node-uses-bitwise(e) || node-uses-bitwise(body)
    ForEach(_, coll, body) -> node-uses-bitwise(coll) || node-uses-bitwise(body)
    While(cond, body)      -> node-uses-bitwise(cond) || node-uses-bitwise(body)
    Loop(body)             -> node-uses-bitwise(body)
    StringInterp(parts)   -> parts.any(fn(p) node-uses-bitwise(p))
    LetTuple(_, init, body) -> node-uses-bitwise(init) || node-uses-bitwise(body)
    EConstructor(_, cargs)  -> cargs.any(fn(a) node-uses-bitwise(a))
    Tuple(elems)            -> elems.any(fn(e) node-uses-bitwise(e))
    TupleIndex(t, _)        -> node-uses-bitwise(t)
    _                       -> False

fun arm-uses-bitwise( a : match-arm ) : div bool
  match a.pattern
    PBits(_, _) -> True
    _ -> node-uses-bitwise(a.body) || a.guard.map(node-uses-bitwise).default(False)

fun program-uses-input( p : program ) : div bool
  p.decls.any(fn(d) node-uses-input(d.body))

fun node-uses-input( n : node ) : div bool
  match n.expr
    Call(callee, args) ->
      val is-input-fn = match callee.expr
        Var("input") -> True
        _            -> False
      is-input-fn || node-uses-input(callee) || args.any(fn(a) node-uses-input(a))
    Let(_, _, init, body) -> node-uses-input(init) || node-uses-input(body)
    VarDecl(_, _, init, body) -> node-uses-input(init) || node-uses-input(body)
    Assign(_, value)      -> node-uses-input(value)
    Fun(_, body)          -> node-uses-input(body)
    Binary(_, lhs, rhs)   -> node-uses-input(lhs) || node-uses-input(rhs)
    Unary(_, operand)     -> node-uses-input(operand)
    If(c, t, e)           -> node-uses-input(c) || node-uses-input(t) || node-uses-input(e)
    Block(stmts)          -> stmts.any(fn(s) node-uses-input(s))
    Match(scrut, arms)    -> node-uses-input(scrut) || arms.any(fn(a) node-uses-input(a.body) || a.guard.map(node-uses-input).default(False))
    Repeat(count, body)   -> node-uses-input(count) || node-uses-input(body)
    ForIn(_, s, e, body)  -> node-uses-input(s) || node-uses-input(e) || node-uses-input(body)
    ForEach(_, coll, body) -> node-uses-input(coll) || node-uses-input(body)
    While(cond, body)      -> node-uses-input(cond) || node-uses-input(body)
    Loop(body)             -> node-uses-input(body)
    StringInterp(parts)   -> parts.any(fn(p) node-uses-input(p))
    LetTuple(_, init, body)  -> node-uses-input(init) || node-uses-input(body)
    EConstructor(_, cargs)   -> cargs.any(fn(a) node-uses-input(a))
    Tuple(elems)             -> elems.any(fn(e) node-uses-input(e))
    TupleIndex(t, _)         -> node-uses-input(t)
    _                        -> False

// ---------------------------------------------------------------------------
// Sort detection: emit merge-sort helper when sort_by is used
// ---------------------------------------------------------------------------

fun program-uses-sort( p : program ) : div bool
  p.decls.any(fn(d) node-uses-sort(d.body))

fun node-uses-sort( n : node ) : div bool
  match n.expr
    Call(callee, args) ->
      val is-sort-fn = match callee.expr
        Var("sort_by") -> True
        _              -> False
      is-sort-fn || node-uses-sort(callee) || args.any(fn(a) node-uses-sort(a))
    Let(_, _, init, body) -> node-uses-sort(init) || node-uses-sort(body)
    VarDecl(_, _, init, body) -> node-uses-sort(init) || node-uses-sort(body)
    Assign(_, value)      -> node-uses-sort(value)
    Fun(_, body)          -> node-uses-sort(body)
    Binary(_, lhs, rhs)   -> node-uses-sort(lhs) || node-uses-sort(rhs)
    Unary(_, operand)     -> node-uses-sort(operand)
    If(c, t, e)           -> node-uses-sort(c) || node-uses-sort(t) || node-uses-sort(e)
    Block(stmts)          -> stmts.any(fn(s) node-uses-sort(s))
    Match(scrut, arms)    -> node-uses-sort(scrut) || arms.any(fn(a) node-uses-sort(a.body) || a.guard.map(node-uses-sort).default(False))
    Repeat(count, body)   -> node-uses-sort(count) || node-uses-sort(body)
    ForIn(_, s, e, body)  -> node-uses-sort(s) || node-uses-sort(e) || node-uses-sort(body)
    ForEach(_, coll, body) -> node-uses-sort(coll) || node-uses-sort(body)
    While(cond, body)      -> node-uses-sort(cond) || node-uses-sort(body)
    Loop(body)             -> node-uses-sort(body)
    StringInterp(parts)   -> parts.any(fn(p) node-uses-sort(p))
    LetTuple(_, init, body) -> node-uses-sort(init) || node-uses-sort(body)
    EConstructor(_, cargs)  -> cargs.any(fn(a) node-uses-sort(a))
    Tuple(elems)            -> elems.any(fn(e) node-uses-sort(e))
    TupleIndex(t, _)        -> node-uses-sort(t)
    _                       -> False

// Check whether the program uses system clock functions (now_unix, now_iso, unix_to_iso)
// that require `import std/time/chrono` etc.
fun program-uses-time( p : program ) : div bool
  p.decls.any(fn(d) node-uses-time(d.body))

fun node-uses-time( n : node ) : div bool
  match n.expr
    Call(callee, args) ->
      val is-time-fn = match callee.expr
        Var("now_unix")    -> True
        Var("now_iso")     -> True
        Var("unix_to_iso") -> True
        _                  -> False
      is-time-fn || node-uses-time(callee) || args.any(fn(a) node-uses-time(a))
    Let(_, _, init, body) -> node-uses-time(init) || node-uses-time(body)
    VarDecl(_, _, init, body) -> node-uses-time(init) || node-uses-time(body)
    Assign(_, value)      -> node-uses-time(value)
    Fun(_, body)          -> node-uses-time(body)
    Binary(_, lhs, rhs)   -> node-uses-time(lhs) || node-uses-time(rhs)
    Unary(_, operand)     -> node-uses-time(operand)
    If(c, t, e)           -> node-uses-time(c) || node-uses-time(t) || node-uses-time(e)
    Block(stmts)          -> stmts.any(fn(s) node-uses-time(s))
    Match(scrut, arms)    -> node-uses-time(scrut) || arms.any(fn(a) node-uses-time(a.body) || a.guard.map(node-uses-time).default(False))
    Repeat(count, body)   -> node-uses-time(count) || node-uses-time(body)
    ForIn(_, s, e, body)  -> node-uses-time(s) || node-uses-time(e) || node-uses-time(body)
    ForEach(_, coll, body) -> node-uses-time(coll) || node-uses-time(body)
    While(cond, body)      -> node-uses-time(cond) || node-uses-time(body)
    Loop(body)             -> node-uses-time(body)
    StringInterp(parts)   -> parts.any(fn(p) node-uses-time(p))
    LetTuple(_, init, body) -> node-uses-time(init) || node-uses-time(body)
    EConstructor(_, cargs)  -> cargs.any(fn(a) node-uses-time(a))
    Tuple(elems)            -> elems.any(fn(e) node-uses-time(e))
    TupleIndex(t, _)        -> node-uses-time(t)
    _                       -> False

val assert-helper-code : string =
  "fun hc-assert( b : bool ) : exn ()\n" ++
  "  if !b then throw(\"assertion failed\")\n" ++
  "\n"

val show-maybe-helper-code : string =
  "fun hc-show-maybe(m, show-a)\n" ++
  "  match m\n" ++
  "    Nothing -> \"None\"\n" ++
  "    Just(x) -> \"Some(\" ++ show-a(x) ++ \")\"\n" ++
  "\n"

val show-result-helper-code : string =
  "fun hc-show-result(r, show-a, show-e)\n" ++
  "  match r\n" ++
  "    Right(x) -> \"Ok(\" ++ show-a(x) ++ \")\"\n" ++
  "    Left(e)  -> \"Err(\" ++ show-e(e) ++ \")\"\n" ++
  "\n"

// Emitted when the program uses input() — provides a flushing, EOF-safe stdin reader.
// Fixes two problems with the naive `print(p); readline()` approach:
//   1. stdout is buffered on macOS/Darwin: fflush() makes the prompt appear before blocking.
//   2. readline() throws exn on EOF: the match/try wrapper returns "" instead of crashing.
val readline-helper-code : string =
  "extern hica-fflush() : io ()\n" ++
  "  c inline \"(fflush(stdout),kk_Unit)\"\n" ++
  "\n" ++
  "fun hica-readline-prompt(prompt : string) : io string\n" ++
  "  print(prompt)\n" ++
  "  hica-fflush()\n" ++
  "  match try(readline)\n" ++
  "    Ok(s)    -> s\n" ++
  "    Error(_) -> \"\"\n" ++
  "\n"

val exit-helper-code : string =
  "extern hica-exit( code : int ) : a\n" ++
  "  c inline \"(exit(kk_integer_clamp32(#1, kk_context())), kk_box_null())\"\n" ++
  "\n"

// Emitted when the program calls get_env — bypasses Koka's lazy environ cache.
val get-env-helper-code : string =
  "extern hica-getenv-exists( key : string ) : io bool\n" ++
  "  c inline \"getenv(kk_string_cbuf_borrow(#1,NULL,kk_context())) != NULL\"\n" ++
  "\n" ++
  "extern hica-getenv-raw( key : string ) : io string\n" ++
  "  c inline \"kk_string_alloc_from_qutf8n((kk_ssize_t)strlen(getenv(kk_string_cbuf_borrow(#1,NULL,kk_context()))), getenv(kk_string_cbuf_borrow(#1,NULL,kk_context())), kk_context())\"\n" ++
  "\n" ++
  "fun hica-get-env( key : string ) : io maybe<string>\n" ++
  "  if hica-getenv-exists(key) then Just(hica-getenv-raw(key))\n" ++
  "  else Nothing\n" ++
  "\n"

val set-env-helper-code : string =
  "extern hica-set-env( name : string, value : string ) : io ()\n" ++
  "  c inline \"setenv(kk_string_cbuf_borrow(#1,NULL,kk_context()), kk_string_cbuf_borrow(#2,NULL,kk_context()), 1)\"\n" ++
  "\n" ++
  "extern hica-set-env-nooverwrite( name : string, value : string ) : io ()\n" ++
  "  c inline \"setenv(kk_string_cbuf_borrow(#1,NULL,kk_context()), kk_string_cbuf_borrow(#2,NULL,kk_context()), 0)\"\n" ++
  "\n"

// Check whether the program uses exit() — needs the C extern helper.
fun program-uses-exit( p : program ) : div bool
  p.decls.any(fn(d) node-uses-exit(d.body))

fun node-uses-exit( n : node ) : div bool
  match n.expr
    Call(callee, args) ->
      val is-exit-fn = match callee.expr
        Var("exit") -> True
        _           -> False
      is-exit-fn || node-uses-exit(callee) || args.any(fn(a) node-uses-exit(a))
    Let(_, _, init, body) -> node-uses-exit(init) || node-uses-exit(body)
    VarDecl(_, _, init, body) -> node-uses-exit(init) || node-uses-exit(body)
    Assign(_, value)      -> node-uses-exit(value)
    Fun(_, body)          -> node-uses-exit(body)
    Binary(_, lhs, rhs)   -> node-uses-exit(lhs) || node-uses-exit(rhs)
    Unary(_, operand)     -> node-uses-exit(operand)
    If(c, t, e)           -> node-uses-exit(c) || node-uses-exit(t) || node-uses-exit(e)
    Block(stmts)          -> stmts.any(fn(s) node-uses-exit(s))
    Match(scrut, arms)    -> node-uses-exit(scrut) || arms.any(fn(a) node-uses-exit(a.body) || a.guard.map(node-uses-exit).default(False))
    Repeat(count, body)   -> node-uses-exit(count) || node-uses-exit(body)
    ForIn(_, s, e, body)  -> node-uses-exit(s) || node-uses-exit(e) || node-uses-exit(body)
    ForEach(_, coll, body) -> node-uses-exit(coll) || node-uses-exit(body)
    While(cond, body)      -> node-uses-exit(cond) || node-uses-exit(body)
    Loop(body)             -> node-uses-exit(body)
    StringInterp(parts)   -> parts.any(fn(p) node-uses-exit(p))
    LetTuple(_, init, body) -> node-uses-exit(init) || node-uses-exit(body)
    EConstructor(_, cargs)  -> cargs.any(fn(a) node-uses-exit(a))
    Tuple(elems)            -> elems.any(fn(e) node-uses-exit(e))
    TupleIndex(t, _)        -> node-uses-exit(t)
    _                       -> False

// Check whether the program uses set_env — needs the C extern helper.
fun program-uses-set-env( p : program ) : div bool
  p.decls.any(fn(d) node-uses-set-env(d.body))

fun node-uses-set-env( n : node ) : div bool
  match n.expr
    Call(callee, args) ->
      val is-set-env-fn = match callee.expr
        Var("set_env") -> True
        Var("set_env_nooverwrite") -> True
        _              -> False
      is-set-env-fn || node-uses-set-env(callee) || args.any(fn(a) node-uses-set-env(a))
    Let(_, _, init, body)      -> node-uses-set-env(init) || node-uses-set-env(body)
    VarDecl(_, _, init, body)  -> node-uses-set-env(init) || node-uses-set-env(body)
    Assign(_, value)           -> node-uses-set-env(value)
    Fun(_, body)               -> node-uses-set-env(body)
    Binary(_, lhs, rhs)        -> node-uses-set-env(lhs) || node-uses-set-env(rhs)
    Unary(_, operand)          -> node-uses-set-env(operand)
    If(c, t, e)                -> node-uses-set-env(c) || node-uses-set-env(t) || node-uses-set-env(e)
    Block(stmts)               -> stmts.any(fn(s) node-uses-set-env(s))
    Match(scrut, arms)         -> node-uses-set-env(scrut) || arms.any(fn(a) node-uses-set-env(a.body) || a.guard.map(node-uses-set-env).default(False))
    Repeat(count, body)        -> node-uses-set-env(count) || node-uses-set-env(body)
    ForIn(_, s, e, body)       -> node-uses-set-env(s) || node-uses-set-env(e) || node-uses-set-env(body)
    ForEach(_, coll, body)     -> node-uses-set-env(coll) || node-uses-set-env(body)
    While(cond, body)          -> node-uses-set-env(cond) || node-uses-set-env(body)
    Loop(body)                 -> node-uses-set-env(body)
    StringInterp(parts)        -> parts.any(fn(p) node-uses-set-env(p))
    LetTuple(_, init, body)    -> node-uses-set-env(init) || node-uses-set-env(body)
    EConstructor(_, cargs)     -> cargs.any(fn(a) node-uses-set-env(a))
    Tuple(elems)               -> elems.any(fn(e) node-uses-set-env(e))
    TupleIndex(t, _)           -> node-uses-set-env(t)
    _                          -> False

val sort-helper-code : string =
  "fun hc-merge-with( xs, ys, cmp )\n" ++
  "  match xs\n" ++
  "    Nil -> ys\n" ++
  "    Cons(x, xr) -> match ys\n" ++
  "      Nil -> xs\n" ++
  "      Cons(y, yr) -> if cmp(x, y) then Cons(x, hc-merge-with(xr, ys, cmp)) else Cons(y, hc-merge-with(xs, yr, cmp))\n" ++
  "\n" ++
  "fun hc-sort-by( xs, cmp )\n" ++
  "  match xs\n" ++
  "    Nil -> Nil\n" ++
  "    Cons(_, Nil) -> xs\n" ++
  "    _ ->\n" ++
  "      val mid = xs.length / 2\n" ++
  "      hc-merge-with(hc-sort-by(xs.take(mid), cmp), hc-sort-by(xs.drop(mid), cmp), cmp)\n" ++
  "\n"

// ---------------------------------------------------------------------------
// Break / continue detection
// ---------------------------------------------------------------------------

// Check whether the program uses break or continue anywhere.
fun program-has-break( p : program ) : div bool
  p.decls.any(fn(d) node-has-brk(d.body))

fun program-has-continue( p : program ) : div bool
  p.decls.any(fn(d) node-has-cont(d.body))

// Deep search for Break — walks into nested loops.
fun node-has-brk( n : node ) : div bool
  match n.expr
    Break                 -> True
    Let(_, _, init, body) -> node-has-brk(init) || node-has-brk(body)
    VarDecl(_, _, init, body) -> node-has-brk(init) || node-has-brk(body)
    Assign(_, value)      -> node-has-brk(value)
    Fun(_, body)          -> node-has-brk(body)
    Call(callee, args)    -> node-has-brk(callee) || args.any(fn(a) node-has-brk(a))
    Binary(_, lhs, rhs)   -> node-has-brk(lhs) || node-has-brk(rhs)
    Unary(_, operand)     -> node-has-brk(operand)
    If(c, t, e)           -> node-has-brk(c) || node-has-brk(t) || node-has-brk(e)
    Block(stmts)          -> stmts.any(fn(s) node-has-brk(s))
    Match(scrut, arms)    -> node-has-brk(scrut) || arms.any(fn(a) node-has-brk(a.body))
    Repeat(_, body)       -> node-has-brk(body)
    ForIn(_, _, _, body)  -> node-has-brk(body)
    ForEach(_, _, body)   -> node-has-brk(body)
    While(_, body)        -> node-has-brk(body)
    Loop(body)            -> node-has-brk(body)
    LetTuple(_, init, body) -> node-has-brk(init) || node-has-brk(body)
    EConstructor(_, cargs)  -> cargs.any(fn(a) node-has-brk(a))
    _                     -> False

fun node-has-cont( n : node ) : div bool
  match n.expr
    Continue              -> True
    Let(_, _, init, body) -> node-has-cont(init) || node-has-cont(body)
    VarDecl(_, _, init, body) -> node-has-cont(init) || node-has-cont(body)
    Assign(_, value)      -> node-has-cont(value)
    Fun(_, body)          -> node-has-cont(body)
    Call(callee, args)    -> node-has-cont(callee) || args.any(fn(a) node-has-cont(a))
    Binary(_, lhs, rhs)   -> node-has-cont(lhs) || node-has-cont(rhs)
    Unary(_, operand)     -> node-has-cont(operand)
    If(c, t, e)           -> node-has-cont(c) || node-has-cont(t) || node-has-cont(e)
    Block(stmts)          -> stmts.any(fn(s) node-has-cont(s))
    Match(scrut, arms)    -> node-has-cont(scrut) || arms.any(fn(a) node-has-cont(a.body))
    Repeat(_, body)       -> node-has-cont(body)
    ForIn(_, _, _, body)  -> node-has-cont(body)
    ForEach(_, _, body)   -> node-has-cont(body)
    While(_, body)        -> node-has-cont(body)
    Loop(body)            -> node-has-cont(body)
    LetTuple(_, init, body) -> node-has-cont(init) || node-has-cont(body)
    EConstructor(_, cargs)  -> cargs.any(fn(a) node-has-cont(a))
    _                     -> False

// Check whether a loop body *directly* contains break/continue
// (stops at nested loop boundaries — those loops have their own handlers).
fun body-has-break( n : node ) : div bool
  match n.expr
    Break                 -> True
    // Stop at nested loop boundaries
    Repeat(_, _)          -> False
    ForIn(_, _, _, _)     -> False
    ForEach(_, _, _)      -> False
    While(_, _)           -> False
    Loop(_)               -> False
    // Recurse through everything else
    Let(_, _, init, body) -> body-has-break(init) || body-has-break(body)
    VarDecl(_, _, init, body) -> body-has-break(init) || body-has-break(body)
    Assign(_, value)      -> body-has-break(value)
    Fun(_, body)          -> body-has-break(body)
    Call(callee, args)    -> body-has-break(callee) || args.any(fn(a) body-has-break(a))
    Binary(_, lhs, rhs)   -> body-has-break(lhs) || body-has-break(rhs)
    Unary(_, operand)     -> body-has-break(operand)
    If(c, t, e)           -> body-has-break(c) || body-has-break(t) || body-has-break(e)
    Block(stmts)          -> stmts.any(fn(s) body-has-break(s))
    Match(scrut, arms)    -> body-has-break(scrut) || arms.any(fn(a) body-has-break(a.body))
    LetTuple(_, init, body) -> body-has-break(init) || body-has-break(body)
    EConstructor(_, cargs)  -> cargs.any(fn(a) body-has-break(a))
    _                     -> False

fun body-has-continue( n : node ) : div bool
  match n.expr
    Continue              -> True
    // Stop at nested loop boundaries
    Repeat(_, _)          -> False
    ForIn(_, _, _, _)     -> False
    ForEach(_, _, _)      -> False
    While(_, _)           -> False
    Loop(_)               -> False
    // Recurse through everything else
    Let(_, _, init, body) -> body-has-continue(init) || body-has-continue(body)
    VarDecl(_, _, init, body) -> body-has-continue(init) || body-has-continue(body)
    Assign(_, value)      -> body-has-continue(value)
    Fun(_, body)          -> body-has-continue(body)
    Call(callee, args)    -> body-has-continue(callee) || args.any(fn(a) body-has-continue(a))
    Binary(_, lhs, rhs)   -> body-has-continue(lhs) || body-has-continue(rhs)
    Unary(_, operand)     -> body-has-continue(operand)
    If(c, t, e)           -> body-has-continue(c) || body-has-continue(t) || body-has-continue(e)
    Block(stmts)          -> stmts.any(fn(s) body-has-continue(s))
    Match(scrut, arms)    -> body-has-continue(scrut) || arms.any(fn(a) body-has-continue(a.body))
    LetTuple(_, init, body) -> body-has-continue(init) || body-has-continue(body)
    EConstructor(_, cargs)  -> cargs.any(fn(a) body-has-continue(a))
    _                     -> False

// ---------------------------------------------------------------------------
// Try operator (?) detection
// ---------------------------------------------------------------------------

// Check if a node contains ETry on a result type (needs hica-early-result effect)
fun node-has-try-result( n : node ) : div bool
  match n.expr
    ETry(inner) -> match inner.typ
      Just(TResult(_, _)) -> True
      _ -> False
    Let(_, _, init, body) -> node-has-try-result(init) || node-has-try-result(body)
    VarDecl(_, _, init, body) -> node-has-try-result(init) || node-has-try-result(body)
    Assign(_, value)      -> node-has-try-result(value)
    Fun(_, _)             -> False  // nested functions handle their own ?
    Call(callee, args)    -> node-has-try-result(callee) || args.any(fn(a) node-has-try-result(a))
    Binary(_, lhs, rhs)   -> node-has-try-result(lhs) || node-has-try-result(rhs)
    Unary(_, operand)     -> node-has-try-result(operand)
    If(c, t, e)           -> node-has-try-result(c) || node-has-try-result(t) || node-has-try-result(e)
    Block(stmts)          -> stmts.any(fn(s) node-has-try-result(s))
    Match(scrut, arms)    -> node-has-try-result(scrut) || arms.any(fn(a) node-has-try-result(a.body))
    LetTuple(_, init, body) -> node-has-try-result(init) || node-has-try-result(body)
    _                     -> False

// Check if a node contains ETry on a maybe type (needs hica-early-maybe effect)
fun node-has-try-maybe( n : node ) : div bool
  match n.expr
    ETry(inner) -> match inner.typ
      Just(TMaybe(_)) -> True
      _ -> False
    Let(_, _, init, body) -> node-has-try-maybe(init) || node-has-try-maybe(body)
    VarDecl(_, _, init, body) -> node-has-try-maybe(init) || node-has-try-maybe(body)
    Assign(_, value)      -> node-has-try-maybe(value)
    Fun(_, _)             -> False  // nested functions handle their own ?
    Call(callee, args)    -> node-has-try-maybe(callee) || args.any(fn(a) node-has-try-maybe(a))
    Binary(_, lhs, rhs)   -> node-has-try-maybe(lhs) || node-has-try-maybe(rhs)
    Unary(_, operand)     -> node-has-try-maybe(operand)
    If(c, t, e)           -> node-has-try-maybe(c) || node-has-try-maybe(t) || node-has-try-maybe(e)
    Block(stmts)          -> stmts.any(fn(s) node-has-try-maybe(s))
    Match(scrut, arms)    -> node-has-try-maybe(scrut) || arms.any(fn(a) node-has-try-maybe(a.body))
    LetTuple(_, init, body) -> node-has-try-maybe(init) || node-has-try-maybe(body)
    _                     -> False

fun program-has-try-result( p : program ) : div bool
  p.decls.any(fn(d) node-has-try-result(d.body))

fun program-has-try-maybe( p : program ) : div bool
  p.decls.any(fn(d) node-has-try-maybe(d.body))

// Wrap loop code with break handler if the body uses break.
// Uses val _ = ... to scope the handler so it doesn't extend
// beyond the loop into subsequent statements.
fun wrap-break-handler( body : node, loop-code : string ) : div string
  if body-has-break(body) then
    // Use an IIFE to scope the handler and produce an expression (not a val binding).
    // This avoids "last statement must be expression" when the loop is the last item in a block.
    "(fn()\n" ++ indent-all("with handler\n  ctl hica-break() -> ()\n" ++ loop-code) ++ "\n)()"
  else
    loop-code

// ---------------------------------------------------------------------------
// Test program emission: generates a self-contained test runner
// ---------------------------------------------------------------------------

pub fun emit-test-program( p : program, mod-name : string = "main", imported-names : list<string> = [], extra-effectful : list<string> = [], extra-imports : list<string> = [] ) : div string
  val declared = p.decls.map(fn(d) d.name).filter(fn(n) n != "main") ++ imported-names
  val float-import = if program-has-float(p) || tests-have-float(p.tests) then "import std/num/float64\n\n" else ""
  val random-import = if program-uses-random(p) then "import std/num/random\nimport std/num/int32\n\n" else ""
  val bitwise-import = if !program-uses-random(p) && program-uses-bitwise(p) then "import std/num/int32\n\n" else ""
  val env-import = if program-uses-env(p) then "import std/os/env\n\n" else ""
  val file-import = if program-uses-file-io(p) then "import std/os/file\nimport std/os/path\n\n" else ""
  val exec-import = if program-uses-exec(p) then "import std/os/process\n\n" else ""
  val readline-import = if program-uses-input(p) then "import std/os/readline\n\n" else ""
  val readline-helper = if program-uses-input(p) then readline-helper-code else ""
  val time-import = if program-uses-time(p) then "import std/time/chrono\nimport std/time/utc\nimport std/time/time\nimport std/time/format\nimport std/num/ddouble\n\n" else ""
  val has-brk = program-has-break(p)
  val has-cont = program-has-continue(p)
  val has-try-r = program-has-try-result(p)
  val has-try-m = program-has-try-maybe(p)
  val break-effect = if has-brk then "effect hica-brk\n  ctl hica-break() : a\n\n" else ""
  val cont-effect = if has-cont then "effect hica-cont\n  ctl hica-continue() : a\n\n" else ""
  val try-result-effect = if has-try-r then "effect hica-early-result<a>\n  ctl hica-early-err(e : a) : b\n\n" else ""
  val try-maybe-effect = if has-try-m then "effect hica-early-maybe\n  ctl hica-early-none() : a\n\n" else ""
  val sort-helper = if program-uses-sort(p) then sort-helper-code else ""
  val assert-helper = assert-helper-code
  val show-maybe-helper = show-maybe-helper-code
  val show-result-helper = show-result-helper-code
  val exit-extern = "extern hica-exit( code : int ) : a\n  c inline \"(exit(kk_integer_clamp32(#1, kk_context())), kk_box_null())\"\n\n"
  val get-env-helper = if program-uses-get-env(p) then get-env-helper-code else ""
  val set-env-helper = if program-uses-set-env(p) then set-env-helper-code else ""
  val hica-imports = p.imports.map(fn(imp)
    val koka-mod = safe-module-name(imp.path.import-basename)
    val pub-str = if imp.is-pub then "pub " else ""
    pub-str ++ "import " ++ koka-mod ++ "\n"
  ).join("") ++ (if p.imports.is-nil then "" else "\n")
  // Koka treats repeated unqualified imports of a module as separate candidates,
  // making its names ambiguous. Deduplicate the transitive extern-module imports
  // against the module's own imports and against each other.
  val hica-mod-names = p.imports.map(fn(imp) safe-module-name(imp.path.import-basename))
  val extra-dedup = extra-imports.foldl([], fn(acc, m)
    if acc.any(fn(a) a == m) || hica-mod-names.any(fn(a) a == m) then acc else acc ++ [m]
  )
  val extra-kk-imports = extra-dedup.map(fn(m) "import " ++ m ++ "\n").join("") ++ (if extra-dedup.is-nil then "" else "\n")
  val struct-defs = p.structs.map(fn(sd) emit-struct-def(sd)).join("\n\n")
  val struct-sep = if p.structs.is-empty then "" else "\n\n"
  val type-defs = p.types.map(fn(td) emit-type-def(td, p.structs, p.types)).join("\n\n")
  val type-sep = if p.types.is-nil then "" else "\n\n"
  // Emit user functions (excluding main — tests replace main)
  val user-decls = p.decls.filter(fn(d) d.name != "main")
  val rec-names = compute-div-names(p.decls)
  val seed-result = user-decls.filter(fn(d) d.is-recursive && node-has-try-result(d.body)).map(fn(d) d.name)
  val seed-maybe  = user-decls.filter(fn(d) d.is-recursive && node-has-try-maybe(d.body)).map(fn(d) d.name)
  val try-rec-result-names = expand-try-rec-names(user-decls, seed-result)
  val try-rec-maybe-names  = expand-try-rec-names(user-decls, seed-maybe)
  val decls-code = user-decls.map(fn(d) emit-decl(d, declared, rec-names, extra-effectful = extra-effectful, try-rec-result-names = try-rec-result-names, try-rec-maybe-names = try-rec-maybe-names)).join("\n\n")
  val decls-sep = if user-decls.is-empty then "" else "\n\n"
  // Emit each test as a function
  val test-fns = p.tests.map-indexed(fn(i, t) emit-test-fn(i, t, declared)).join("\n\n")
  val test-sep = if p.tests.is-empty then "" else "\n\n"
  // Emit main that runs all tests
  val test-main = emit-test-main(p.tests)
  "// Generated by hica (test mode)\n" ++
  "module " ++ mod-name ++ "\n\n" ++
  float-import ++
  random-import ++
  bitwise-import ++
  env-import ++
  file-import ++
  exec-import ++
  readline-import ++
  time-import ++
  hica-imports ++
  extra-kk-imports ++
  exit-extern ++
  get-env-helper ++
  set-env-helper ++
  break-effect ++
  cont-effect ++
  try-result-effect ++
  try-maybe-effect ++
  sort-helper ++
  readline-helper ++
  assert-helper ++
  show-maybe-helper ++
  show-result-helper ++
  type-defs ++ type-sep ++
  struct-defs ++ struct-sep ++
  decls-code ++ decls-sep ++
  test-fns ++ test-sep ++
  test-main ++ "\n"

fun emit-test-fn( idx : int, t : test-decl, declared : list<string> ) : div string
  "fun hctest" ++ idx.show ++ "()\n" ++
  emit-body(t.body, declared).lines.map(fn(line) "  " ++ line).join("\n")

fun emit-test-main( tests : list<test-decl> ) : div string
  val total = tests.length
  val runner-lines = tests.map-indexed fn(i, t)
    val escaped-name = t.name.replace-all("\"", "\\\"")
    "  val r" ++ i.show ++ " = match try({ hctest" ++ i.show ++ "() })\n" ++
    "    Ok(_) ->\n" ++
    "      println(\"  \\x1b[32m\\u2713\\x1b[0m \" ++ \"" ++ escaped-name ++ "\")\n" ++
    "      True\n" ++
    "    Error(e) ->\n" ++
    "      println(\"  \\x1b[31m\\u2717\\x1b[0m \" ++ \"" ++ escaped-name ++ "\")\n" ++
    "      println(\"    \" ++ e.message)\n" ++
    "      False"
  val result-vars = tests.map-indexed(fn(i, _) "r" ++ i.show)
  val all-passed = result-vars.map(fn(v) v).join(" && ")
  "fun main()\n" ++
  "  println(\"\")\n" ++
  "  println(\"running " ++ total.show ++ " test(s)...\")\n" ++
  "  println(\"\")\n" ++
  runner-lines.join("\n") ++ "\n" ++
  "  println(\"\")\n" ++
  emit-test-summary(total, result-vars)

fun emit-test-summary( total : int, result-vars : list<string> ) : string
  if total == 0 then
    "  println(\"no tests found\")\n"
  else
    "  val passed = [" ++ result-vars.join(", ") ++ "].filter(fn(x) x).length\n" ++
    "  val failed = " ++ total.show ++ " - passed\n" ++
    "  if failed == 0 then\n" ++
    "    println(\"\\x1b[32m\" ++ passed.show ++ \" test(s) passed\\x1b[0m\")\n" ++
    "  else\n" ++
    "    println(\"\\x1b[31m\" ++ failed.show ++ \" test(s) failed\\x1b[0m, \" ++ passed.show ++ \" passed\")\n" ++
    "    hica-exit(1)\n"

fun tests-have-float( ts : list<test-decl> ) : div bool
  ts.any(fn(t) node-has-float(t.body))
