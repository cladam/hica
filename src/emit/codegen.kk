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
  "linear", "value", "reference", "named", "scoped"]

pub fun safe-module-name( name : string ) : string
  if koka-keywords.any(fn(k) k == name) then "hc-" ++ name
  else match name.list
    Cons(c, _) | c.is-digit -> "hc" ++ name
    _                       -> name

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
    TVar(_)     -> ""  // unresolved — omit annotation

// ---------------------------------------------------------------------------
// Struct definition emission
// ---------------------------------------------------------------------------

// Convert a struct name to Koka's lowercase type name: Point -> point
fun struct-type-name( name : string ) : string
  name.to-lower

fun emit-struct-def( sd : struct-def ) : div string
  val tname = sd.name.struct-type-name
  val struct-str = "struct " ++ tname ++ "\n" ++
    sd.fields.map(fn((fname, ftype)) "  " ++ fname ++ " : " ++ emit-type(ftype)).join("\n")
  // Emit a show function for the struct
  val show-parts = sd.fields.map fn((fname, ftype))
    "\"" ++ fname ++ ": \" ++ " ++ emit-show-call(ftype, "p." ++ fname)
  // Recursive structs need the `div` effect on show
  val is-rec = sd.fields.any(fn((_, ft)) ft.references-struct(sd.name))
  val effect-ann = if is-rec then " : div string" else " : string"
  val show-fn = "fun " ++ tname ++ "/show(p : " ++ tname ++ ")" ++ effect-ann ++ "\n" ++
    "  \"" ++ sd.name ++ "(\" ++ " ++ show-parts.join(" ++ \", \" ++ ") ++ " ++ \")\""
  struct-str ++ "\n\n" ++ show-fn

// Check if a type references a struct by name (for recursion detection)
fun references-struct( t : hica-type, name : string ) : div bool
  match t
    TStruct(sn) -> sn == name
    TMaybe(inner) -> inner.references-struct(name)
    TList(inner) -> inner.references-struct(name)
    TTuple(ts) -> ts.any(fn(tt) tt.references-struct(name))
    TFun(params, ret) -> params.any(fn(p) p.references-struct(name)) || ret.references-struct(name)
    _ -> False

// Emit a show call for a specific type
fun emit-show-call( t : hica-type, expr-str : string ) : div string
  match t
    TInt    -> expr-str ++ ".show"
    TFloat  -> expr-str ++ ".show"
    TBool   -> expr-str ++ ".show"
    TChar   -> expr-str ++ ".show"
    TString -> expr-str
    TStruct(sn) -> sn.struct-type-name ++ "/show(" ++ expr-str ++ ")"
    _       -> expr-str ++ ".show"

// ---------------------------------------------------------------------------
// Program-level emission: generates a complete .kk module
// ---------------------------------------------------------------------------

pub fun emit-program( p : program, mod-name : string = "main" ) : div string
  val declared = p.decls.map(fn(d) d.name).filter(fn(n) n != "main")
  val float-import = if program-has-float(p) then "import std/num/float64\n\n" else ""
  val env-import = if program-uses-env(p) then "import std/os/env\n\n" else ""
  val struct-defs = p.structs.map(fn(sd) emit-struct-def(sd)).join("\n\n")
  val struct-sep = if p.structs.is-empty then "" else "\n\n"
  "// Generated by hica\n" ++
  "module " ++ mod-name ++ "\n\n" ++
  float-import ++
  env-import ++
  struct-defs ++ struct-sep ++
  p.decls.map(fn(d) emit-decl(d, declared)).join("\n\n") ++ "\n"

fun emit-decl( d : fun-decl, declared : list<string> ) : div string
  val params-str = emit-typed-params(d.params, d.param-types, declared)
  // Omit return type annotation for recursive functions — let Koka infer `div`
  // Omit function-typed returns — Koka's parser confuses `(a) -> b` with the
  // function's own signature, so we let Koka infer it.
  // Use ret-ann (user-written) rather than ret-type (inferred) so that Koka
  // can freely infer effects for functions that call divergent helpers.
  val ret-ann = if d.is-recursive then "" else match d.ret-ann
    Just(TFun(_, _)) -> ""
    Just(t) ->
      val ts = emit-type(t)
      if ts == "" then "" else " : " ++ ts
    Nothing -> ""
  "fun " ++ marshal-name(d.name, declared) ++ "(" ++ params-str ++ ")" ++ ret-ann ++ "\n" ++
  emit-body(d.body, declared).lines.map(fn(line) "  " ++ line).join("\n")

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
      "val " ++ marshal-name(name, declared) ++ " = " ++ emit-expr(init, declared) ++ "\n  " ++ emit-expr(body, declared)
    VarDecl(name, _, init, body) ->
      "var " ++ marshal-name(name, declared) ++ " := " ++ emit-expr(init, declared) ++ "\n  " ++ emit-expr(body, declared)
    Assign(name, value) ->
      marshal-name(name, declared) ++ " := " ++ emit-expr(value, declared)
    Fun(params, body) ->
      "fn(" ++ params.map(fn(p) marshal-name(p, declared)).join(", ") ++ ") " ++ emit-expr(body, declared)
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
        _ ->
          val callee-code = match callee.expr
            Var("fold")   -> "foldl"
            Var("length") -> "list/length"
            Var("cons")   -> "Cons"
            Var("show")   -> "show"
            _             -> emit-expr(callee, declared)
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
        val pat-str = emit-pattern(a.pattern, declared)
        val guard-str = match a.guard
          Just(g) -> " | " ++ emit-expr(g, declared)
          Nothing -> ""
        "  " ++ pat-str ++ guard-str ++ " ->\n    " ++ emit-expr(a.body, declared).replace-all("\n", "\n    ")
      ).join("\n")
    Repeat(count, body) ->
      "repeat(" ++ emit-expr(count, declared) ++ ")\n" ++
      body.expr.repeat-body(declared)
    ForIn(name, start-e, end-e, body) ->
      "for(" ++ emit-expr(start-e, declared) ++ ", " ++ emit-expr(end-e, declared) ++ ") fn(" ++ marshal-name(name, declared) ++ ")\n" ++
      body.expr.repeat-body(declared)
    ForEach(name, coll, body) ->
      emit-expr(coll, declared) ++ ".foreach fn(" ++ marshal-name(name, declared) ++ ")\n" ++
      body.expr.repeat-body(declared)
    While(cond, body) ->
      "while { " ++ emit-expr(cond, declared) ++ " }\n" ++
      body.expr.repeat-body(declared)
    StringInterp(parts) ->
      val emitted = parts.map(fn(p) emit-interp-part(p, declared))
      "(" ++ emitted.join(" ++ ") ++ ")"
    Tuple(elems) ->
      "(" ++ elems.map(fn(e) emit-expr(e, declared)).join(", ") ++ ")"
    EList(elems) ->
      "[" ++ elems.map(fn(e) emit-expr(e, declared)).join(", ") ++ "]"
    ESome(value) ->
      "Just(" ++ emit-expr(value, declared) ++ ")"
    ENone ->
      "Nothing"
    EOk(value) ->
      "Right(" ++ emit-expr(value, declared) ++ ")"
    EErr(value) ->
      "Left(" ++ emit-expr(value, declared) ++ ")"
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
      "val (" ++ names.map(fn(nm) marshal-name(nm, declared)).join(", ") ++ ") = " ++ emit-expr(init, declared) ++ "\n  " ++ emit-expr(body, declared)
    StructLit(sname, fields) ->
      sname ++ "(" ++ fields.map(fn((_, v)) emit-expr(v, declared)).join(", ") ++ ")"
    FieldAccess(obj, fname) ->
      emit-expr(obj, declared) ++ "." ++ fname

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

// Indent all lines of a string by 2 spaces.
fun indent-all( s : string ) : string
  s.split("\n").map(fn(line) "  " ++ line).join("\n")

// Map a 0-based tuple index to Koka's named accessor.
fun tuple-field-name( idx : int ) : string
  match idx
    0 -> "fst"
    1 -> "snd"
    2 -> "thd"
    n -> "field" ++ (n + 1).show

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
    Block(_)            -> True
    _                   -> False

// Emit an if-branch as an indented block.
fun emit-branch( n : node, declared : list<string> ) : div string
  match n.expr
    Block(stmts) -> stmts.map(fn(s) indent-all(emit-stmt(s, declared))).join("\n")
    _            -> indent-all(emit-stmt(n, declared))

fun program-has-float( p : program ) : div bool
  p.decls.any(fn(d) node-has-float(d.body))

fun is-parse-float( e : expr ) : bool
  match e
    Var("parse_float") -> True
    _                  -> False

fun node-has-float( n : node ) : div bool
  match n.expr
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
    StringInterp(parts)   -> parts.any(fn(p) node-uses-env(p))
    LetTuple(_, init, body) -> node-uses-env(init) || node-uses-env(body)
    _                     -> False
