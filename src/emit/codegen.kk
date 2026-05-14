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

fun emit-struct-def( sd : struct-def ) : div string
  val tname = sd.name.struct-type-name
  val pub-str = if sd.is-pub then "pub " else ""
  val struct-str = pub-str ++ "struct " ++ tname ++ "\n" ++
    sd.fields.map(fn((fname, ftype)) "  " ++ fname ++ " : " ++ emit-type(ftype)).join("\n")
  // Emit a show function for the struct
  val show-parts = sd.fields.map fn((fname, ftype))
    "\"" ++ fname ++ ": \" ++ " ++ emit-show-call(ftype, "p." ++ fname)
  // Recursive structs need the `div` effect on show
  val is-rec = sd.fields.any(fn((_, ft)) ft.references-struct(sd.name))
  val effect-ann = if is-rec then " : div string" else " : string"
  val show-fn = pub-str ++ "fun " ++ tname ++ "/show(p : " ++ tname ++ ")" ++ effect-ann ++ "\n" ++
    "  \"" ++ sd.name ++ "(\" ++ " ++ show-parts.join(" ++ \", \" ++ ") ++ " ++ \")\""
  struct-str ++ "\n\n" ++ show-fn

// ---------------------------------------------------------------------------
// Type (enum) definition emission
// ---------------------------------------------------------------------------

fun emit-type-def( td : type-def, structs : list<struct-def> ) : div string
  val tname = td.name.to-lower
  val pub-str = if td.is-pub then "pub " else ""
  val type-str = pub-str ++ "type " ++ tname ++ "\n" ++
    td.variants.map(fn(vd)
      if vd.fields.is-nil then "  " ++ vd.name
      else "  " ++ vd.name ++ "(" ++ vd.fields.map(fn((fname, ftype)) fname ++ " : " ++ emit-type(ftype)).join(", ") ++ ")"
    ).join("\n")
  // Emit a show function for the type
  val is-rec = td.variants.any(fn(vd) vd.fields.any(fn((_, ft)) ft.references-type(td.name)))
  val refs-rec-struct = td.variants.any(fn(vd) vd.fields.any(fn((_, ft)) ft.references-recursive-struct(structs)))
  val effect-ann = if is-rec || refs-rec-struct then " : div string" else " : string"
  val show-arms = td.variants.map fn(vd)
    if vd.fields.is-nil then
      "    " ++ vd.name ++ " -> \"" ++ vd.name ++ "\""
    elif vd.fields.length == 1 then
      match vd.fields
        Cons((fname, ftype), _) ->
          "    " ++ vd.name ++ "(" ++ fname ++ ") -> \"" ++ vd.name ++ "(\" ++ " ++ emit-show-call(ftype, fname) ++ " ++ \")\""
        _ -> ""
    else
      val param-names = vd.fields.map(fn((fname, _)) fname)
      val show-parts = vd.fields.map(fn((fname, ftype)) emit-show-call(ftype, fname))
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
    _       -> expr-str ++ ".show"

// ---------------------------------------------------------------------------
// Program-level emission: generates a complete .kk module
// ---------------------------------------------------------------------------

pub fun emit-program( p : program, mod-name : string = "main", imported-names : list<string> = [] ) : div string
  val declared = p.decls.map(fn(d) d.name).filter(fn(n) n != "main") ++ imported-names
  val float-import = if program-has-float(p) then "import std/num/float64\n\n" else ""
  val random-import = if program-uses-random(p) then "import std/num/random\nimport std/num/int32\n\n" else ""
  val bitwise-import = if !program-uses-random(p) && program-uses-bitwise(p) then "import std/num/int32\n\n" else ""
  val env-import = if program-uses-env(p) then "import std/os/env\n\n" else ""
  val file-import = if program-uses-file-io(p) then "import std/os/file\nimport std/os/path\n\n" else ""
  val readline-import = if program-uses-input(p) then "import std/os/readline\n\n" else ""
  val hica-imports = p.imports.map(fn(imp)
    val koka-mod = safe-module-name(imp.path.import-basename)
    val pub-str = if imp.is-pub then "pub " else ""
    pub-str ++ "import " ++ koka-mod ++ "\n"
  ).join("") ++ (if p.imports.is-nil then "" else "\n")
  val has-brk = program-has-break(p)
  val has-cont = program-has-continue(p)
  val has-try-r = program-has-try-result(p)
  val has-try-m = program-has-try-maybe(p)
  val break-effect = if has-brk then "effect hica-brk\n  ctl hica-break() : a\n\n" else ""
  val cont-effect = if has-cont then "effect hica-cont\n  ctl hica-continue() : a\n\n" else ""
  val try-result-effect = if has-try-r then "effect hica-early-result\n  ctl hica-early-err(e : a) : b\n\n" else ""
  val try-maybe-effect = if has-try-m then "effect hica-early-maybe\n  ctl hica-early-none() : a\n\n" else ""
  val sort-helper = if program-uses-sort(p) then sort-helper-code else ""
  val type-defs = p.types.map(fn(td) emit-type-def(td, p.structs)).join("\n\n")
  val type-sep = if p.types.is-nil then "" else "\n\n"
  val struct-defs = p.structs.map(fn(sd) emit-struct-def(sd)).join("\n\n")
  val struct-sep = if p.structs.is-empty then "" else "\n\n"
  val rec-names = p.decls.filter(fn(d) d.is-recursive).map(fn(d) d.name)
  "// Generated by hica\n" ++
  "module " ++ mod-name ++ "\n\n" ++
  float-import ++
  random-import ++
  bitwise-import ++
  env-import ++
  file-import ++
  readline-import ++
  hica-imports ++
  break-effect ++
  cont-effect ++
  try-result-effect ++
  try-maybe-effect ++
  sort-helper ++
  type-defs ++ type-sep ++
  struct-defs ++ struct-sep ++
  p.decls.map(fn(d) emit-decl(d, declared, rec-names)).join("\n\n") ++ "\n"

fun emit-decl( d : fun-decl, declared : list<string>, rec-names : list<string> = [] ) : div string
  val params-str = emit-typed-params(d.params, d.param-types, declared)
  val has-try-result = node-has-try-result(d.body)
  val has-try-maybe  = node-has-try-maybe(d.body)
  val needs-div = d.is-recursive || (!rec-names.is-nil && body-calls-any(d.body, rec-names))
  val ret-ann = match d.ret-ann
    Just(TFun(_, _)) -> ""
    Just(t) ->
      val ts = emit-type(t)
      if ts == "" then ""
      elif needs-div then " : div " ++ ts
      else " : " ++ ts
    Nothing -> ""
  val pub-prefix = if d.is-pub then "pub " else ""
  val body-code = emit-body(d.body, declared).lines.map(fn(line) "  " ++ line).join("\n")
  val wrapped-body = if has-try-result then
    "  with handler\n    ctl hica-early-err(e) -> Left(e)\n" ++ body-code
  elif has-try-maybe then
    "  with handler\n    ctl hica-early-none() -> Nothing\n" ++ body-code
  else body-code
  pub-prefix ++ "fun " ++ marshal-name(d.name, declared) ++ "(" ++ params-str ++ ")" ++ ret-ann ++ "\n" ++
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
      "val " ++ marshal-name(name, declared) ++ " = " ++ emit-expr(init, declared) ++ "\n" ++ emit-body-wrap-last(wrapper, body, declared)
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
      "val " ++ marshal-name(name, declared) ++ ann ++ " = " ++ emit-expr(init, declared) ++ "\n" ++ emit-stmt(body, declared)
    VarDecl(name, _, init, body) ->
      val ann = match init.typ
        Just(t) ->
          val ts = emit-type(t)
          if ts == "" then "" else " : " ++ ts
        Nothing -> ""
      "var " ++ marshal-name(name, declared) ++ ann ++ " := " ++ emit-expr(init, declared) ++ "\n" ++ emit-stmt(body, declared)
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
// Expression emission
// ---------------------------------------------------------------------------

fun emit-expr( n : node, declared : list<string> ) : div string
  match n.expr
    Literal(LitInt(i))      -> i.show
    Literal(LitFloat(f))    -> f
    Literal(LitBool(True))  -> "True"
    Literal(LitBool(False)) -> "False"
    Literal(LitString(s))   -> "\"" ++ s ++ "\""
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
          "(" ++ emit-expr(l, declared) ++ " " ++ op-str ++ " " ++ emit-expr(r, declared) ++ ")"
    Unary(Neg, o)           -> "(0 - " ++ emit-expr(o, declared) ++ ")"
    Unary(Not, o)           -> "!(" ++ emit-expr(o, declared) ++ ")"
    Let(name, _, init, body) ->
      "val " ++ marshal-name(name, declared) ++ " = " ++ emit-expr(init, declared) ++ "\n" ++ emit-expr(body, declared)
    VarDecl(name, _, init, body) ->
      "var " ++ marshal-name(name, declared) ++ " := " ++ emit-expr(init, declared) ++ "\n" ++ emit-expr(body, declared)
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
            Just(TChar)   -> "println(" ++ emit-expr(arg, declared) ++ ".show)"
            Just(TMaybe(_)) -> "println(" ++ emit-expr(arg, declared) ++ ".show)"
            Just(TResult(_, _)) -> "println(" ++ emit-expr(arg, declared) ++ ".show)"
            Just(TStruct(sn))  -> "println(" ++ sn.struct-type-name ++ "/show(" ++ emit-expr(arg, declared) ++ "))"
            Just(TEnum(en))    -> "println(" ++ en.to-lower ++ "/show(" ++ emit-expr(arg, declared) ++ "))"
            _             -> "println(" ++ emit-expr(arg, declared) ++ ".show)"
        (Var("enumerate"), [arg]) ->
          emit-expr(arg, declared) ++ ".map-indexed(fn(hc__i, hc__x) (hc__i, hc__x))"
        // --- String utilities ---
        (Var("str_length"), [s]) ->
          emit-expr(s, declared) ++ ".count"
        (Var("contains"), [s, sub]) ->
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
          emit-expr(s, declared) ++ ".split(" ++ emit-expr(sep, declared) ++ ")"
        (Var("replace"), [s, old, new_]) ->
          emit-expr(s, declared) ++ ".replace-all(" ++ emit-expr(old, declared) ++ ", " ++ emit-expr(new_, declared) ++ ")"
        (Var("join"), [xs, sep]) ->
          emit-expr(xs, declared) ++ ".join(" ++ emit-expr(sep, declared) ++ ")"
        (Var("index_of"), [s, sub]) ->
          "(match " ++ emit-expr(s, declared) ++ ".find(" ++ emit-expr(sub, declared) ++ ") { Just(hc__ss) -> Just(hc__ss.before.count); Nothing -> Nothing })"
        (Var("to_int"), [s]) ->
          "(match " ++ emit-expr(s, declared) ++ ".parse-int { Just(hc__n) -> hc__n; Nothing -> -1 })"
        (Var("parse_int"), [s]) ->
          emit-expr(s, declared) ++ ".parse-int"
        (Var("parse_float"), [s]) ->
          emit-expr(s, declared) ++ ".parse-float64"

        // Environment helpers
        (Var("get_args"), []) ->
          "get-args()"
        (Var("get_env"), [key]) ->
          "get-env-value(" ++ emit-expr(key, declared) ++ ")"
        (Var("eprintln"), [arg]) ->
          match arg.typ
            Just(TString) -> "trace(" ++ emit-expr(arg, declared) ++ ")"
            _             -> "trace(" ++ emit-expr(arg, declared) ++ ".show)"

        // User input
        (Var("input"), [prompt]) ->
          "{ val _ = print(" ++ emit-expr(prompt, declared) ++ "); readline() }"

        // File I/O
        (Var("read_file"), [p]) ->
          "(match try({ read-text-file(" ++ emit-expr(p, declared) ++ ".path) }) { Ok(hc__c) -> Right(hc__c); Error(hc__e) -> Left(hc__e.message) })"
        (Var("write_file"), [p, content]) ->
          "write-text-file(" ++ emit-expr(p, declared) ++ ".path, " ++ emit-expr(content, declared) ++ ")"

        // Random numbers — hica random(min, max) is inclusive on both ends
        (Var("random"), [lo, hi]) ->
          "srandom-int32-range(" ++ emit-expr(lo, declared) ++ ".int32, (" ++ emit-expr(hi, declared) ++ " + 1).int32).int"

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
              "(match " ++ emit-expr(r, declared) ++ " { Right(" ++ pn ++ ") -> Right(" ++ emit-expr(body, declared) ++ "); Left(hc__e) -> Left(hc__e) })"
            _ ->
              "(match " ++ emit-expr(r, declared) ++ " { Right(hc__v) -> Right((" ++ emit-expr(f, declared) ++ ")(hc__v)); Left(hc__e) -> Left(hc__e) })"
        (Var("map_err"), [r, f]) ->
          match f.expr
            Fun(Cons(p, Nil), body) ->
              val pn = marshal-name(p, declared)
              "(match " ++ emit-expr(r, declared) ++ " { Right(hc__v) -> Right(hc__v); Left(" ++ pn ++ ") -> Left(" ++ emit-expr(body, declared) ++ ") })"
            _ ->
              "(match " ++ emit-expr(r, declared) ++ " { Right(hc__v) -> Right(hc__v); Left(hc__e) -> Left((" ++ emit-expr(f, declared) ++ ")(hc__e)) })"
        (Var("and_then_result"), [r, f]) ->
          match f.expr
            Fun(Cons(p, Nil), body) ->
              val pn = marshal-name(p, declared)
              "(match " ++ emit-expr(r, declared) ++ " { Right(" ++ pn ++ ") -> " ++ emit-expr(body, declared) ++ "; Left(hc__e) -> Left(hc__e) })"
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

        // Test assertions
        (Var("assert"), [cond]) ->
          "(if !(" ++ emit-expr(cond, declared) ++ ") then throw(\"assertion failed\") else ())"
        (Var("assert_true"), [cond]) ->
          "(if !(" ++ emit-expr(cond, declared) ++ ") then throw(\"expected true but got false\") else ())"
        (Var("assert_false"), [cond]) ->
          "(if (" ++ emit-expr(cond, declared) ++ ") then throw(\"expected false but got true\") else ())"
        (Var("assert_eq"), [expected, actual]) ->
          val e-code = emit-expr(expected, declared)
          val a-code = emit-expr(actual, declared)
          "(if (" ++ e-code ++ ") != (" ++ a-code ++ ") then throw(\"expected \" ++ (" ++ e-code ++ ").show ++ \" but got \" ++ (" ++ a-code ++ ").show) else ())"
        (Var("assert_ne"), [expected, actual]) ->
          val e-code = emit-expr(expected, declared)
          val a-code = emit-expr(actual, declared)
          "(if (" ++ e-code ++ ") == (" ++ a-code ++ ") then throw(\"expected values to differ but both are \" ++ (" ++ e-code ++ ").show) else ())"
        (Var("assert_contains"), [lst, elem]) ->
          val l-code = emit-expr(lst, declared)
          val e-code = emit-expr(elem, declared)
          "(if !(" ++ l-code ++ ".any(fn(hc__el) hc__el == " ++ e-code ++ ")) then throw(\"expected list to contain \" ++ (" ++ e-code ++ ").show) else ())"
        (Var("assert_empty"), [lst]) ->
          val l-code = emit-expr(lst, declared)
          "(if !(" ++ l-code ++ ".is-nil) then throw(\"expected empty list but got \" ++ (" ++ l-code ++ ").length.show ++ \" element(s)\") else ())"
        (Var("assert_not_empty"), [lst]) ->
          val l-code = emit-expr(lst, declared)
          "(if (" ++ l-code ++ ".is-nil) then throw(\"expected non-empty list but got []\") else ())"

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
          emit-expr(xs, declared) ++ ".flatmap(" ++ emit-expr(f, declared) ++ ")"
        (Var("sort_by"), [xs, f]) ->
          "hc-sort-by(" ++ emit-expr(xs, declared) ++ ", " ++ emit-expr(f, declared) ++ ")"

        // Float math
        (Var("sqrt"), [x]) ->
          "sqrt(" ++ emit-expr(x, declared) ++ ")"
        (Var("floor"), [x]) ->
          "floor(" ++ emit-expr(x, declared) ++ ").int"
        (Var("ceil"), [x]) ->
          "ceiling(" ++ emit-expr(x, declared) ++ ").int"
        (Var("round"), [x]) ->
          "round(" ++ emit-expr(x, declared) ++ ").int"
        (Var("to_float"), [n]) ->
          emit-expr(n, declared) ++ ".float64"

        // Char/string conversions
        (Var("chars"), [s]) ->
          emit-expr(s, declared) ++ ".list"
        (Var("from_chars"), [cs]) ->
          emit-expr(cs, declared) ++ ".string"

        _ ->
          val callee-code = match callee.expr
            Var("fold")   -> "foldl"
            Var("length") -> "list/length"
            Var("cons")   -> "Cons"
            Var("show")   -> "show"
            _             -> emit-expr(callee, declared)
          // Use trailing lambda syntax when the last argument is a multiline lambda
          match args.reverse
            Cons(last, rest) | last.expr.is-fun-multiline ->
              val init-args = rest.reverse.map(fn(a) emit-expr(a, declared))
              val trailing = emit-expr(last, declared)
              if init-args.is-nil then
                callee-code ++ " " ++ trailing
              else
                callee-code ++ "(" ++ init-args.join(", ") ++ ") " ++ trailing
            _ ->
              callee-code ++ "(" ++ args.map(fn(a) emit-expr(a, declared)).join(", ") ++ ")"
    If(cond, then-e, else-e) ->
      match else-e.expr
        Block([]) ->
          // No else branch — emit statement-level if
          "if " ++ emit-expr(cond, declared) ++ " then\n" ++
          emit-branch(then-e, declared)
        _ ->
          if then-e.expr.needs-block || else-e.expr.needs-block then
            "if " ++ emit-expr(cond, declared) ++ " then\n" ++
            emit-branch(then-e, declared) ++ "\n" ++
            "else\n" ++
            emit-branch(else-e, declared)
          else
            "if " ++ emit-expr(cond, declared) ++ " then " ++ emit-expr(then-e, declared) ++ " else " ++ emit-expr(else-e, declared)
    Block(stmts) ->
      stmts.map(fn(s) emit-expr(s, declared)).join("\n")
    Match(scrut, arms) ->
      val expanded = arms.flatmap(fn(a) expand-or-arm(a))
      "match " ++ emit-expr(scrut, declared) ++ "\n" ++
      expanded.map(fn(a)
        val (pat-str, guard-str) = match a.pattern
          _ ->
            val gs = match a.guard
              Just(g) -> " | " ++ emit-expr(g, declared)
              Nothing -> ""
            (emit-pattern(a.pattern, declared), gs)
        "  " ++ pat-str ++ guard-str ++ " ->\n    " ++ emit-expr(a.body, declared).replace-all("\n", "\n    ")
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
      // Emit: { val hc__base = <base>; Name(field-or-override, ...) }
      val base-code = emit-expr(base, declared)
      val args = def-fields.map fn(fname)
        match overrides.find(fn((nm, _)) nm == fname)
          Just((_, fval)) -> emit-expr(fval, declared)
          Nothing -> "hc__base." ++ fname
      "{ val hc__base = " ++ base-code ++ "; " ++ sname ++ "(" ++ args.join(", ") ++ ") }"
    FieldAccess(obj, fname) ->
      val obj-is-struct = match obj.typ
        Just(TStruct(_)) -> True
        _                -> False
      val emitted-name = if obj-is-struct then fname else marshal-name(fname, declared)
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
        Just(TChar)   -> "char/show(" ++ inner ++ ")"
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

// Check if an expression produces multiple lines (needs indented block in lambda body)
fun is-multiline( e : expr ) : bool
  match e
    Let(_, _, _, _)     -> True
    VarDecl(_, _, _, _) -> True
    LetTuple(_, _, _)   -> True
    Block(Cons(s, Nil)) -> match s.expr
      Let(_, _, _, _)     -> True
      VarDecl(_, _, _, _) -> True
      LetTuple(_, _, _)   -> True
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
    Block(stmts) -> stmts.map(fn(s) indent-all(emit-stmt(s, declared))).join("\n")
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

// Check whether the program uses environment functions (get_args, get_env)
// that require `import std/os/env`.
fun program-uses-env( p : program ) : div bool
  p.decls.any(fn(d) node-uses-env(d.body))

fun node-uses-env( n : node ) : div bool
  match n.expr
    Call(callee, args) ->
      val is-env-fn = match callee.expr
        Var("get_args") -> True
        Var("get_env")  -> True
        _               -> False
      is-env-fn || node-uses-env(callee) || args.any(fn(a) node-uses-env(a))
    Let(_, _, init, body) -> node-uses-env(init) || node-uses-env(body)
    VarDecl(_, _, init, body) -> node-uses-env(init) || node-uses-env(body)
    Assign(_, value)      -> node-uses-env(value)
    Fun(_, body)          -> node-uses-env(body)
    Binary(_, lhs, rhs)   -> node-uses-env(lhs) || node-uses-env(rhs)
    Unary(_, operand)     -> node-uses-env(operand)
    If(c, t, e)           -> node-uses-env(c) || node-uses-env(t) || node-uses-env(e)
    Block(stmts)          -> stmts.any(fn(s) node-uses-env(s))
    Match(scrut, arms)    -> node-uses-env(scrut) || arms.any(fn(a) node-uses-env(a.body) || a.guard.map(node-uses-env).default(False))
    Repeat(count, body)   -> node-uses-env(count) || node-uses-env(body)
    ForIn(_, s, e, body)  -> node-uses-env(s) || node-uses-env(e) || node-uses-env(body)
    ForEach(_, coll, body) -> node-uses-env(coll) || node-uses-env(body)
    While(cond, body)      -> node-uses-env(cond) || node-uses-env(body)
    Loop(body)             -> node-uses-env(body)
    StringInterp(parts)   -> parts.any(fn(p) node-uses-env(p))
    LetTuple(_, init, body) -> node-uses-env(init) || node-uses-env(body)
    EConstructor(_, cargs)  -> cargs.any(fn(a) node-uses-env(a))
    _                     -> False

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
    _                     -> False

// Check whether the program uses the input() function
// that requires `import std/os/readline`.
fun program-uses-random( p : program ) : div bool
  p.decls.any(fn(d) node-uses-random(d.body))

fun node-uses-random( n : node ) : div bool
  match n.expr
    Call(callee, args) ->
      val is-random-fn = match callee.expr
        Var("random") -> True
        _             -> False
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
    _                     -> False

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
    _                     -> False

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
    LetTuple(_, init, body) -> node-uses-input(init) || node-uses-input(body)
    EConstructor(_, cargs)  -> cargs.any(fn(a) node-uses-input(a))
    _                     -> False

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
    _                     -> False

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
    "val _ =\n" ++ indent-all("with handler\n  ctl hica-break() -> ()\n" ++ loop-code)
  else
    loop-code

// ---------------------------------------------------------------------------
// Test program emission: generates a self-contained test runner
// ---------------------------------------------------------------------------

pub fun emit-test-program( p : program, mod-name : string = "main", imported-names : list<string> = [] ) : div string
  val declared = p.decls.map(fn(d) d.name).filter(fn(n) n != "main") ++ imported-names
  val float-import = if program-has-float(p) || tests-have-float(p.tests) then "import std/num/float64\n\n" else ""
  val random-import = if program-uses-random(p) then "import std/num/random\nimport std/num/int32\n\n" else ""
  val bitwise-import = if !program-uses-random(p) && program-uses-bitwise(p) then "import std/num/int32\n\n" else ""
  val env-import = if program-uses-env(p) then "import std/os/env\n\n" else ""
  val file-import = if program-uses-file-io(p) then "import std/os/file\nimport std/os/path\n\n" else ""
  val readline-import = if program-uses-input(p) then "import std/os/readline\n\n" else ""
  val has-brk = program-has-break(p)
  val has-cont = program-has-continue(p)
  val has-try-r = program-has-try-result(p)
  val has-try-m = program-has-try-maybe(p)
  val break-effect = if has-brk then "effect hica-brk\n  ctl hica-break() : a\n\n" else ""
  val cont-effect = if has-cont then "effect hica-cont\n  ctl hica-continue() : a\n\n" else ""
  val try-result-effect = if has-try-r then "effect hica-early-result\n  ctl hica-early-err(e : a) : b\n\n" else ""
  val try-maybe-effect = if has-try-m then "effect hica-early-maybe\n  ctl hica-early-none() : a\n\n" else ""
  val sort-helper = if program-uses-sort(p) then sort-helper-code else ""
  val exit-extern = "extern hica-exit( code : int ) : a\n  c inline \"(exit(kk_integer_clamp32(#1, kk_context())), kk_box_null())\"\n\n"
  val hica-imports = p.imports.map(fn(imp)
    val koka-mod = safe-module-name(imp.path.import-basename)
    val pub-str = if imp.is-pub then "pub " else ""
    pub-str ++ "import " ++ koka-mod ++ "\n"
  ).join("") ++ (if p.imports.is-nil then "" else "\n")
  val struct-defs = p.structs.map(fn(sd) emit-struct-def(sd)).join("\n\n")
  val struct-sep = if p.structs.is-empty then "" else "\n\n"
  val type-defs = p.types.map(fn(td) emit-type-def(td, p.structs)).join("\n\n")
  val type-sep = if p.types.is-nil then "" else "\n\n"
  // Emit user functions (excluding main — tests replace main)
  val user-decls = p.decls.filter(fn(d) d.name != "main")
  val rec-names = p.decls.filter(fn(d) d.is-recursive).map(fn(d) d.name)
  val decls-code = user-decls.map(fn(d) emit-decl(d, declared, rec-names)).join("\n\n")
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
  readline-import ++
  hica-imports ++
  exit-extern ++
  break-effect ++
  cont-effect ++
  try-result-effect ++
  try-maybe-effect ++
  sort-helper ++
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
