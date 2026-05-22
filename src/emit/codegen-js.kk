/*
 * hica – JavaScript code generation (playground target)
 * 
 * This source file is part of the hica open source project
 * Copyright (C) 2026 Claes Adamsson <claes.adamsson@gmail.com>
 *
 * See https://github.com/cladam/hica/blob/main/LICENSE for license information
 *
 * Emits self-contained JavaScript from a checked hica AST.
 * Designed for browser execution in the hica playground.
 * No Koka compiler needed at runtime — this bypasses the .kk stage entirely.
*/
module emit/codegen-js

import syntax/ast

// ---------------------------------------------------------------------------
// Public entry point
// ---------------------------------------------------------------------------

pub fun emit-js-program( p : program, mod-name : string = "main" ) : div string
  val struct-defs = p.structs.map(emit-js-struct).join("\n\n")
  val type-defs = p.types.map(emit-js-type-def).join("\n\n")
  val decls = p.decls.map(emit-js-decl).join("\n\n")
  val preamble = js-runtime-preamble()
  preamble ++ "\n" ++
  (if struct-defs.is-empty then "" else struct-defs ++ "\n\n") ++
  (if type-defs.is-empty then "" else type-defs ++ "\n\n") ++
  decls ++ "\n\n" ++
  "// Entry point\n" ++
  "if (typeof main === 'function') { const __r = main(); if (__r !== undefined && __r !== null) println(show(__r)); }\n"

// ---------------------------------------------------------------------------
// Runtime preamble: minimal helpers that mirror hica's prelude
// ---------------------------------------------------------------------------

pub fun js-runtime-preamble() : string
  "// hica playground runtime\n" ++
  "'use strict';\n\n" ++
  "const __hc_output = [];\n" ++
  "function println(s) { const line = String(s); __hc_output.push(line); if (typeof process !== 'undefined') process.stdout.write(line + '\\n'); }\n" ++
  "function print(s) { const t = String(s); __hc_output.push(t); if (typeof process !== 'undefined') process.stdout.write(t); }\n" ++
  "function __tuple(...args) { const t = [...args]; t.__tuple = true; return t; }\n" ++
  "function show(v) {\n" ++
  "  if (v === null || v === undefined) return 'Nothing';\n" ++
  "  if (typeof v === 'boolean') return v ? 'True' : 'False';\n" ++
  "  if (typeof v === 'string') return v;\n" ++
  "  if (typeof v === 'number') return Number.isInteger(v) ? String(v) : v.toPrecision(17).replace(/0+$/, '').replace(/\\\\.$/, '.0');\n" ++
  "  if (Array.isArray(v) && v.__tuple) return '(' + v.map(show_list_elem).join(',') + ')';\n" ++
  "  if (Array.isArray(v)) return '[' + v.map(show_list_elem).join(',') + ']';\n" ++
  "  if (typeof v === 'object' && v.__tag === 'Ok') return 'Right(' + show_list_elem(v.value) + ')';\n" ++
  "  if (typeof v === 'object' && v.__tag === 'Err') return 'Left(' + show_list_elem(v.value) + ')';\n" ++
  "  if (typeof v === 'object' && v.__tag) return v.__tag + (v.__args && v.__args.length > 0 ? '(' + v.__args.map(show).join(', ') + ')' : '');\n" ++
  "  if (typeof v === 'object' && v.__show) return v.__show();\n" ++
  "  if (typeof v === 'object') return JSON.stringify(v);\n" ++
  "  return String(v);\n" ++
  "}\n" ++
  "function show_maybe(v) { return v === null ? 'Nothing' : 'Just(' + show(v) + ')'; }\n" ++
  "function show_result(r) {\n" ++
  "  if (r && r.__tag === 'Ok') return 'Right(' + show_list_elem(r.value) + ')';\n" ++
  "  if (r && r.__tag === 'Err') return 'Left(' + show_list_elem(r.value) + ')';\n" ++
  "  return show(r);\n" ++
  "}\n" ++
  "function show_list_elem(v) {\n" ++
  "  if (typeof v === 'string' && v.length === 1) return \"'\" + v + \"'\";\n" ++
  "  if (typeof v === 'string') return '\"' + v + '\"';\n" ++
  "  return show(v);\n" ++
  "}\n" ++
  "function abs(n) { return Math.abs(n); }\n" ++
  "function min(a, b) { return Math.min(a, b); }\n" ++
  "function max(a, b) { return Math.max(a, b); }\n" ++
  "function str_length(s) { return s.length; }\n" ++
  "function contains(s, sub) { return s.includes(sub); }\n" ++
  "function split(s, sep) { return sep === '' ? [...s] : s.split(sep); }\n" ++
  "function join(xs, sep) { return xs.join(sep); }\n" ++
  "function trim(s) { return s.trim(); }\n" ++
  "function replace(s, old, nw) { return s.replaceAll(old, nw); }\n" ++
  "function to_upper(s) { return s.toUpperCase(); }\n" ++
  "function to_lower(s) { return s.toLowerCase(); }\n" ++
  "function parse_int(s) { const n = parseInt(s, 10); return isNaN(n) ? null : n; }\n" ++
  "function parse_float(s) { const n = parseFloat(s); return isNaN(n) ? null : n; }\n" ++
  "function to_int(s) { const n = parseInt(s, 10); return isNaN(n) ? -1 : n; }\n" ++
  "function enumerate(xs) { return xs.map((x, i) => __tuple(i, x)); }\n" ++
  "function head(xs) { return xs.length > 0 ? xs[0] : null; }\n" ++
  "function tail(xs) { return xs.slice(1); }\n" ++
  "function length(xs) { return xs.length; }\n" ++
  "function reverse(xs) { return [...xs].reverse(); }\n" ++
  "function sort(xs) { return [...xs].sort((a,b) => a < b ? -1 : a > b ? 1 : 0); }\n" ++
  "function map(xs, f) { return xs.map(f); }\n" ++
  "function filter(xs, f) { return xs.filter(f); }\n" ++
  "function fold(xs, init, f) { return xs.reduce((acc, x) => f(acc, x), init); }\n" ++
  "function foreach(xs, f) { xs.forEach(f); }\n" ++
  "function take(xs, n) { return xs.slice(0, n); }\n" ++
  "function drop(xs, n) { return xs.slice(n); }\n" ++
  "function zip(xs, ys) { return xs.map((x, i) => i < ys.length ? __tuple(x, ys[i]) : null).filter(p => p !== null); }\n" ++
  "function concat(xss) { return [].concat(...xss); }\n" ++
  "function cons(x, xs) { return [x, ...xs]; }\n" ++
  "function find(xs, f) { const r = xs.find(f); return r === undefined ? null : r; }\n" ++
  "function all(xs, f) { return xs.every(f); }\n" ++
  "function any(xs, f) { return xs.some(f); }\n" ++
  "function repeat(n, f) { for (let i = 0; i < n; i++) f(); }\n" ++
  "function random(lo, hi) { return Math.floor(Math.random() * (hi - lo + 1)) + lo; }\n" ++
  "function assert(cond, msg) { if (!cond) throw new Error('assertion failed: ' + (msg || '')); }\n" ++
  "\n// Maybe/Result helpers\n" ++
  "const None = null;\n" ++
  "function Some(v) { return v; }\n" ++
  "function is_some(v) { return v !== null; }\n" ++
  "function is_none(v) { return v === null; }\n" ++
  "function unwrap(v) { if (v === null) throw new Error('unwrap on None'); return v; }\n" ++
  "function unwrap_or(v, d) { return v !== null ? v : d; }\n" ++
  "function unwrap_maybe_or(v, d) { return v !== null ? v : d; }\n" ++
  "function map_maybe(m, f) { return m !== null ? Some(f(m)) : null; }\n" ++
  "function and_then(m, f) { return m !== null ? f(m) : null; }\n" ++
  "function or_else(m, f) { return m !== null ? m : f(); }\n" ++
  "function Ok(v) { return { __tag: 'Ok', value: v, __args: [v] }; }\n" ++
  "function Err(v) { return { __tag: 'Err', value: v, __args: [v] }; }\n" ++
  "function is_ok(r) { return r && r.__tag === 'Ok'; }\n" ++
  "function is_err(r) { return r && r.__tag === 'Err'; }\n" ++
  "function unwrap_result(r) { if (r.__tag === 'Ok') return r.value; throw new Error('unwrap on Err: ' + r.value); }\n" ++
  "function unwrap_result_or(r, d) { return r.__tag === 'Ok' ? r.value : d; }\n" ++
  "function map_result(r, f) { return r.__tag === 'Ok' ? Ok(f(r.value)) : r; }\n" ++
  "function and_then_result(r, f) { return r.__tag === 'Ok' ? f(r.value) : r; }\n" ++
  "function map_err(r, f) { return r.__tag === 'Err' ? Err(f(r.value)) : r; }\n" ++
  "\n// Prelude: string helpers\n" ++
  "function is_empty(s) { return s.length === 0; }\n" ++
  "function is_blank(s) { return s.trim().length === 0; }\n" ++
  "function words(s) { return s.split(' ').filter(w => w.length > 0); }\n" ++
  "function lines(s) { return s.split('\\n'); }\n" ++
  "function unwords(ws) { return ws.join(' '); }\n" ++
  "function unlines(ls) { return ls.join('\\n'); }\n" ++
  "function starts_with(s, pre) { return s.startsWith(pre); }\n" ++
  "function ends_with(s, suf) { return s.endsWith(suf); }\n" ++
  "function repeat_str(s, n) { return n <= 0 ? '' : s.repeat(n); }\n" ++
  "function pad_left(s, w, ch) { return repeat_str(ch, Math.max(0, w - s.length)) + s; }\n" ++
  "function pad_right(s, w, ch) { return s + repeat_str(ch, Math.max(0, w - s.length)); }\n" ++
  "function center(s, w, ch) { const t = Math.max(0, w - s.length); const l = Math.floor(t/2); return repeat_str(ch, l) + s + repeat_str(ch, t - l); }\n" ++
  "function index_of(s, sub) { const i = s.indexOf(sub); return i === -1 ? null : i; }\n" ++
  "\n// Prelude: operators\n" ++
  "function is_positive(n) { return n > 0; }\n" ++
  "function is_negative(n) { return n < 0; }\n" ++
  "function is_zero(n) { return n === 0; }\n" ++
  "function is_even(n) { return n % 2 === 0; }\n" ++
  "function is_odd(n) { return n % 2 !== 0; }\n" ++
  "function identity(x) { return x; }\n" ++
  "function not_(b) { return !b; }\n" ++
  "function to_float(n) { return n; }\n" ++
  "function show_fixed(f, prec) { return f.toFixed(prec); }\n" ++
  "\n// I/O (Node.js only — no-op in browser)\n" ++
  "function get_args() { return typeof process !== 'undefined' ? process.argv.slice(2) : []; }\n" ++
  "function read_file(path) { try { const fs = require('fs'); return fs.readFileSync(path, 'utf8'); } catch(e) { return null; } }\n" ++
  "function read_lines(path) { const s = read_file(path); return s !== null ? s.split('\\n') : []; }\n" ++
  "function write_file(path, content) { try { const fs = require('fs'); fs.writeFileSync(path, content); return true; } catch(e) { return false; } }\n" ++
  "function removeprefix(s, pre) { return s.startsWith(pre) ? s.slice(pre.length) : s; }\n" ++
  "function char_at(s, i) { return i >= 0 && i < s.length ? s[i] : null; }\n" ++
  "function substring(s, start, end) { return s.slice(start, end); }\n" ++
  "function to_string(v) { return show(v); }\n" ++
  "function chars(s) { return [...s]; }\n" ++
  "function char_to_string(c) { return c; }\n" ++
  "function ord(c) { return typeof c === 'string' ? c.charCodeAt(0) : c; }\n" ++
  "function chr(n) { return String.fromCharCode(n); }\n" ++
  "function is_digit(c) { const n = typeof c === 'string' ? c.charCodeAt(0) : c; return n >= 48 && n <= 57; }\n" ++
  "function is_upper(c) { const n = typeof c === 'string' ? c.charCodeAt(0) : c; return n >= 65 && n <= 90; }\n" ++
  "function is_lower(c) { const n = typeof c === 'string' ? c.charCodeAt(0) : c; return n >= 97 && n <= 122; }\n" ++
  "function is_alpha(c) { return is_upper(c) || is_lower(c); }\n" ++
  "function is_alnum(c) { return is_alpha(c) || is_digit(c); }\n" ++
  "function is_space(c) { const n = typeof c === 'string' ? c.charCodeAt(0) : c; return n === 32 || n === 9 || n === 10 || n === 13; }\n" ++
  "function is_punct(c) { const n = typeof c === 'string' ? c.charCodeAt(0) : c; return (n >= 33 && n <= 47) || (n >= 58 && n <= 64) || (n >= 91 && n <= 96) || (n >= 123 && n <= 126); }\n" ++
  "function all_digits(s) { return s.length > 0 && [...s].every(c => is_digit(c)); }\n" ++
  "function all_alpha(s) { return s.length > 0 && [...s].every(c => is_alpha(c)); }\n" ++
  "function all_upper(s) { return s.length > 0 && [...s].every(c => is_upper(c)); }\n" ++
  "function all_lower(s) { return s.length > 0 && [...s].every(c => is_lower(c)); }\n" ++
  "function all_alnum(s) { return s.length > 0 && [...s].every(c => is_alnum(c)); }\n" ++
  "\n"

// ---------------------------------------------------------------------------
// Struct emission → JS classes with named fields
// ---------------------------------------------------------------------------

pub fun emit-js-struct( sd : struct-def ) : div string
  val fields = sd.fields.map(fn((name, _)) name)
  val show-body = "'" ++ sd.name ++ "(' + " ++ fields.map(fn(f) "'" ++ f ++ ": ' + show(this." ++ f ++ ")").join(" + ', ' + ") ++ " + ')'"
  "function " ++ sd.name ++ "(" ++ fields.join(", ") ++ ") {\n" ++
  "  return { __struct: '" ++ sd.name ++ "', " ++ fields.map(fn(f) f ++ ": " ++ f).join(", ") ++ ", __show() { return " ++ show-body ++ "; } };\n" ++
  "}\n" ++
  "function " ++ sd.name.to-lower ++ "_show(p) {\n" ++
  "  return '" ++ sd.name ++ "(' + " ++ fields.map(fn(f) "'" ++ f ++ ": ' + show(p." ++ f ++ ")").join(" + ', ' + ") ++ " + ')';\n" ++
  "}"

// ---------------------------------------------------------------------------
// Enum/type emission → JS tagged objects
// ---------------------------------------------------------------------------

pub fun emit-js-type-def( td : type-def ) : div string
  td.variants.map(fn(vd)
    if vd.fields.is-nil then
      "const " ++ vd.name ++ " = Object.freeze({ __tag: '" ++ vd.name ++ "' });"
    else
      val fnames = vd.fields.map(fn((name, _)) name)
      "function " ++ vd.name ++ "(" ++ fnames.join(", ") ++ ") {\n" ++
      "  return { __tag: '" ++ vd.name ++ "', __args: [" ++ fnames.join(", ") ++ "], " ++ fnames.map(fn(f) f ++ ": " ++ f).join(", ") ++ " };\n" ++
      "}"
  ).join("\n")

// ---------------------------------------------------------------------------
// Function declaration emission
// ---------------------------------------------------------------------------

fun emit-js-decl( d : fun-decl ) : div string
  val params = d.params.join(", ")
  val body = emit-js-body(d.body)
  "function " ++ d.name ++ "(" ++ params ++ ") {\n" ++
  indent(body) ++ "\n" ++
  "}"

// ---------------------------------------------------------------------------
// Body & statement emission
// ---------------------------------------------------------------------------

pub fun emit-js-body( n : node ) : div string
  match n.expr
    Block(stmts) ->
      match stmts.reverse
        Cons(last, rest) ->
          val stmts-code = rest.reverse.map(emit-js-stmt).join("\n")
          val last-code = emit-js-return(last)
          if stmts-code.is-empty then last-code
          else stmts-code ++ "\n" ++ last-code
        Nil -> ""
    _ -> emit-js-return(n)

// Emit a node in return position: adds return to the tail expression
fun emit-js-return( n : node ) : div string
  match n.expr
    Let(name, _, init, body) ->
      "const " ++ name ++ " = " ++ emit-js-expr(init) ++ ";\n" ++ emit-js-return(body)
    VarDecl(name, _, init, body) ->
      "let " ++ name ++ " = " ++ emit-js-expr(init) ++ ";\n" ++ emit-js-return(body)
    LetTuple(names, init, body) ->
      "const [" ++ names.join(", ") ++ "] = " ++ emit-js-expr(init) ++ ";\n" ++ emit-js-return(body)
    While(_, _)     -> emit-js-stmt(n)
    ForIn(_, _, _, _)  -> emit-js-stmt(n)
    ForEach(_, _, _)   -> emit-js-stmt(n)
    Repeat(_, _)    -> emit-js-stmt(n)
    Loop(_)         -> emit-js-stmt(n)
    Break           -> "break;"
    Continue        -> "continue;"
    Assign(_, _)    -> emit-js-stmt(n)
    If(cond, then-e, else-e) ->
      "if (" ++ emit-js-expr(cond) ++ ") {\n" ++
      indent(emit-js-return(then-e)) ++ "\n} else {\n" ++
      indent(emit-js-return(else-e)) ++ "\n}"
    _ -> "return " ++ emit-js-expr(n) ++ ";"

// Emit body in statement context (no implicit return on last expr)
fun emit-js-stmts( n : node ) : div string
  match n.expr
    Block(stmts) -> stmts.map(emit-js-stmt).join("\n")
    _            -> emit-js-stmt(n)

fun emit-js-stmt( n : node ) : div string
  match n.expr
    Let(name, _, init, body) ->
      "const " ++ name ++ " = " ++ emit-js-expr(init) ++ ";\n" ++ emit-js-stmt(body)
    VarDecl(name, _, init, body) ->
      "let " ++ name ++ " = " ++ emit-js-expr(init) ++ ";\n" ++ emit-js-stmt(body)
    LetTuple(names, init, body) ->
      "const [" ++ names.join(", ") ++ "] = " ++ emit-js-expr(init) ++ ";\n" ++ emit-js-stmt(body)
    Assign(name, value) ->
      name ++ " = " ++ emit-js-expr(value) ++ ";"
    While(cond, body) ->
      "while (" ++ emit-js-expr(cond) ++ ") {\n" ++ indent(emit-js-stmts(body)) ++ "\n}"
    ForIn(name, start, end_, body) ->
      "for (let " ++ name ++ " = " ++ emit-js-expr(start) ++ "; " ++ name ++ " <= " ++ emit-js-expr(end_) ++ "; " ++ name ++ "++) {\n" ++ indent(emit-js-stmts(body)) ++ "\n}"
    ForEach(name, coll, body) ->
      "for (const " ++ name ++ " of " ++ emit-js-expr(coll) ++ ") {\n" ++ indent(emit-js-stmts(body)) ++ "\n}"
    Repeat(count, body) ->
      "for (let __i = 0; __i < " ++ emit-js-expr(count) ++ "; __i++) {\n" ++ indent(emit-js-stmts(body)) ++ "\n}"
    Loop(body) ->
      "while (true) {\n" ++ indent(emit-js-stmts(body)) ++ "\n}"
    Break -> "break;"
    Continue -> "continue;"
    _ -> emit-js-expr(n) ++ ";"

// ---------------------------------------------------------------------------
// Expression emission
// ---------------------------------------------------------------------------

pub fun emit-js-expr( n : node ) : div string
  match n.expr
    Literal(LitInt(i))      -> i.show
    Literal(LitFloat(f))    -> f
    Literal(LitBool(True))  -> "true"
    Literal(LitBool(False)) -> "false"
    Literal(LitString(s))   -> "\"" ++ s ++ "\""
    Literal(LitChar(c))     -> "'" ++ c ++ "'"
    Var("None")             -> "null"
    Var(name)               -> name

    Binary(op, l, r) ->
      match op
        In  -> emit-js-expr(r) ++ ".includes(" ++ emit-js-expr(l) ++ ")"
        Add ->
          match l.typ
            Just(TList(_)) -> emit-js-expr(l) ++ ".concat(" ++ emit-js-expr(r) ++ ")"
            _ -> "(" ++ emit-js-expr(l) ++ " + " ++ emit-js-expr(r) ++ ")"
        _   -> "(" ++ emit-js-expr(l) ++ " " ++ emit-js-binop(op) ++ " " ++ emit-js-expr(r) ++ ")"

    Unary(Neg, o) -> "(-" ++ emit-js-expr(o) ++ ")"
    Unary(Not, o) -> "(!" ++ emit-js-expr(o) ++ ")"

    Let(name, _, init, body) ->
      "(() => { const " ++ name ++ " = " ++ emit-js-expr(init) ++ "; return " ++ emit-js-expr(body) ++ "; })()"
    VarDecl(name, _, init, body) ->
      "(() => { let " ++ name ++ " = " ++ emit-js-expr(init) ++ "; return " ++ emit-js-expr(body) ++ "; })()"

    LetTuple(names, init, body) ->
      "(() => { const [" ++ names.join(", ") ++ "] = " ++ emit-js-expr(init) ++ "; return " ++ emit-js-expr(body) ++ "; })()"

    Fun(params, body) ->
      "((" ++ params.join(", ") ++ ") => {\n" ++ indent(emit-js-body(body)) ++ "\n})"

    Call(callee, args) ->
      val args-str = args.map(emit-js-expr).join(", ")
      match callee.expr
        Var("println") ->
          match args
            [arg] ->
              match arg.typ
                Just(TString) -> "println(" ++ emit-js-expr(arg) ++ ")"
                Just(TMaybe(_)) -> "println(show_maybe(" ++ emit-js-expr(arg) ++ "))"
                Just(TResult(_, _)) -> "println(show_result(" ++ emit-js-expr(arg) ++ "))"
                _             -> "println(show(" ++ emit-js-expr(arg) ++ "))"
            _ -> "println(" ++ args-str ++ ")"
        Var(fname) -> fname ++ "(" ++ args-str ++ ")"
        _          -> emit-js-expr(callee) ++ "(" ++ args-str ++ ")"

    If(cond, then-e, else-e) ->
      match then-e.expr
        Block(_) ->
          "(() => { if (" ++ emit-js-expr(cond) ++ ") {\n" ++
          indent(emit-js-body(then-e)) ++ "\n} else {\n" ++
          indent(emit-js-body(else-e)) ++ "\n}})()"
        _ ->
          "(" ++ emit-js-expr(cond) ++ " ? " ++ emit-js-expr(then-e) ++ " : " ++ emit-js-expr(else-e) ++ ")"

    Match(scrutinee, arms) ->
      emit-js-match(scrutinee, arms)

    Block(stmts) ->
      "(() => {\n" ++ indent(emit-js-body(n)) ++ "\n})()"

    Tuple(elems) ->
      "__tuple(" ++ elems.map(emit-js-expr).join(", ") ++ ")"

    TupleIndex(tup, idx) ->
      emit-js-expr(tup) ++ "[" ++ idx.show ++ "]"

    EList(elems) ->
      "[" ++ elems.map(emit-js-expr).join(", ") ++ "]"

    ListIndex(lst, idx) ->
      emit-js-expr(lst) ++ ".at(" ++ emit-js-expr(idx) ++ ")"

    ListSlice(lst, s, e) ->
      val start-str = match s
        Just(sn) -> emit-js-expr(sn)
        Nothing  -> "0"
      val end-str = match e
        Just(en) -> emit-js-expr(en)
        Nothing  -> "undefined"
      emit-js-expr(lst) ++ ".slice(" ++ start-str ++ ", " ++ end-str ++ ")"

    MapLit(entries) ->
      "[" ++ entries.map(fn((k, v)) "[" ++ emit-js-expr(k) ++ ", " ++ emit-js-expr(v) ++ "]").join(", ") ++ "]"

    StructLit(sname, fields) ->
      sname ++ "(" ++ fields.map(fn((_f, v)) emit-js-expr(v)).join(", ") ++ ")"

    FieldAccess(obj, field) ->
      emit-js-expr(obj) ++ "." ++ field

    StructUpdate(sname, base, fields, def-fields) ->
      // Rebuild via constructor to preserve __show
      val all-fields = def-fields.map fn(fname)
        match fields.find(fn((n, _)) n == fname)
          Just((_, v)) -> emit-js-expr(v)
          Nothing      -> emit-js-expr(base) ++ "." ++ fname
      sname ++ "(" ++ all-fields.join(", ") ++ ")"

    ESome(value) -> emit-js-expr(value)
    ENone        -> "null"
    EOk(value)   -> "Ok(" ++ emit-js-expr(value) ++ ")"
    EErr(value)  -> "Err(" ++ emit-js-expr(value) ++ ")"

    EConstructor(name, args) ->
      if args.is-nil then name
      else name ++ "(" ++ args.map(emit-js-expr).join(", ") ++ ")"

    StringInterp(parts) ->
      "`" ++ parts.map(fn(p)
        match p.expr
          Literal(LitString(s)) -> s
          _ ->
            match p.typ
              Just(TString) -> "${" ++ emit-js-expr(p) ++ "}"
              _             -> "${show(" ++ emit-js-expr(p) ++ ")}"
      ).join("") ++ "`"

    ETry(inner) ->
      // Simple null-check early return for playground
      "(() => { const __v = " ++ emit-js-expr(inner) ++ "; if (__v === null) return null; return __v; })()"

    _ -> "undefined /* TODO: " ++ n.expr.show ++ " */"

// ---------------------------------------------------------------------------
// Match → JS switch/if-else chain
// ---------------------------------------------------------------------------

fun emit-js-match( scrutinee : node, arms : list<match-arm> ) : div string
  val scrut = emit-js-expr(scrutinee)
  "(() => {\n" ++
  "  const __s = " ++ scrut ++ ";\n" ++
  arms.map(fn(arm) emit-js-arm("__s", arm)).join("") ++
  "  throw new Error('non-exhaustive match');\n" ++
  "})()"

fun emit-js-arm( scrut-var : string, arm : match-arm ) : div string
  val (cond, bindings) = emit-js-pattern-cond(scrut-var, arm.pattern)
  val body-code = emit-js-body(arm.body)
  match arm.guard
    Just(g) ->
      // Guard references bound variables → bind first, then check guard
      "  if (" ++ cond ++ ") {\n" ++
      (if bindings.is-empty then "" else indent(indent(bindings)) ++ "\n") ++
      "    if (" ++ emit-js-expr(g) ++ ") {\n" ++
      indent(indent(indent(body-code))) ++ "\n" ++
      "    }\n" ++
      "  }\n"
    Nothing ->
      "  if (" ++ cond ++ ") {\n" ++
      (if bindings.is-empty then "" else indent(indent(bindings)) ++ "\n") ++
      indent(indent(body-code)) ++ "\n" ++
      "  }\n"

fun emit-js-pattern-cond( v : string, pat : pattern ) : div (string, string)
  match pat
    PWild    -> ("true", "")
    PVar(n)  -> ("true", "const " ++ n ++ " = " ++ v ++ ";")
    PLit(LitInt(i))    -> (v ++ " === " ++ i.show, "")
    PLit(LitFloat(f))  -> (v ++ " === " ++ f, "")
    PLit(LitBool(b))   -> (v ++ " === " ++ b.show.to-lower, "")
    PLit(LitString(s)) -> (v ++ " === \"" ++ s ++ "\"", "")
    PLit(LitChar(c))   -> (v ++ " === '" ++ c ++ "'", "")
    PSome(inner) ->
      val (ic, ib) = emit-js-pattern-cond(v, inner)
      (v ++ " !== null && " ++ ic, ib)
    PNone -> (v ++ " === null", "")
    POk(inner) ->
      val (ic, ib) = emit-js-pattern-cond(v ++ ".value", inner)
      (v ++ " && " ++ v ++ ".__tag === 'Ok' && " ++ ic, ib)
    PErr(inner) ->
      val (ic, ib) = emit-js-pattern-cond(v ++ ".value", inner)
      (v ++ " && " ++ v ++ ".__tag === 'Err' && " ++ ic, ib)
    PConstructor(name, args) ->
      if args.is-nil then
        (v ++ " && " ++ v ++ ".__tag === '" ++ name ++ "'", "")
      else
        val conds = args.map-indexed(fn(i, ap)
          val field-v = v ++ ".__args[" ++ i.show ++ "]"
          emit-js-pattern-cond(field-v, ap)
        )
        val all-conds = [v ++ " && " ++ v ++ ".__tag === '" ++ name ++ "'"] ++ conds.map(fn((c, _)) c)
        val all-binds = conds.map(fn((_, b)) b).filter(fn(b) !b.is-empty)
        (all-conds.join(" && "), all-binds.join("\n"))
    PTuple(elems) ->
      val conds = elems.map-indexed(fn(i, ep)
        emit-js-pattern-cond(v ++ "[" ++ i.show ++ "]", ep)
      )
      val all-conds = conds.map(fn((c, _)) c).filter(fn(c) c != "true")
      val all-binds = conds.map(fn((_, b)) b).filter(fn(b) !b.is-empty)
      val cond = if all-conds.is-nil then "true" else all-conds.join(" && ")
      (cond, all-binds.join("\n"))
    PList(elems, rest) ->
      // Match fixed-length prefix with optional rest binding
      val len = elems.length
      val len-cond = match rest
        Nothing  -> v ++ ".length === " ++ len.show
        Just(_)  -> v ++ ".length >= " ++ len.show
      val elem-results = elems.map-indexed(fn(i, ep)
        emit-js-pattern-cond(v ++ "[" ++ i.show ++ "]", ep)
      )
      val elem-conds = elem-results.map(fn((c, _)) c).filter(fn(c) c != "true")
      val elem-binds = elem-results.map(fn((_, b)) b).filter(fn(b) !b.is-empty)
      val rest-bind = match rest
        Just(PVar(rn)) -> ["const " ++ rn ++ " = " ++ v ++ ".slice(" ++ len.show ++ ");"]
        Just(PWild)    -> []
        _              -> []
      val all-conds = [len-cond] ++ elem-conds
      val all-binds = elem-binds ++ rest-bind
      ("Array.isArray(" ++ v ++ ") && " ++ all-conds.join(" && "), all-binds.join("\n"))
    PStruct(_sname, fps, _defs) ->
      // Match struct fields by name
      val field-results = fps.map(fn((fname, fpat))
        emit-js-pattern-cond(v ++ "." ++ fname, fpat)
      )
      val field-conds = field-results.map(fn((c, _)) c).filter(fn(c) c != "true")
      val field-binds = field-results.map(fn((_, b)) b).filter(fn(b) !b.is-empty)
      val cond = if field-conds.is-nil then "true" else field-conds.join(" && ")
      (cond, field-binds.join("\n"))
    POr(alts) ->
      val alt-conds = alts.map(fn(a) emit-js-pattern-cond(v, a).fst)
      ("(" ++ alt-conds.join(" || ") ++ ")", "")
    PRange(lo, hi) ->
      ("(" ++ v ++ " >= " ++ lo.show ++ " && " ++ v ++ " <= " ++ hi.show ++ ")", "")
    _ -> ("true /* TODO pattern */", "")

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

fun emit-js-binop( op : binop ) : string
  match op
    Add -> "+"
    Sub -> "-"
    Mul -> "*"
    Div -> "/"
    Mod -> "%"
    Eq  -> "==="
    Neq -> "!=="
    Lt  -> "<"
    Gt  -> ">"
    Le  -> "<="
    Ge  -> ">="
    And -> "&&"
    Or  -> "||"
    In  -> "in" // handled specially above

fun is-expression( n : node ) : div bool
  match n.expr
    Let(_, _, _, _)    -> False
    VarDecl(_, _, _, _) -> False
    LetTuple(_, _, _)  -> False
    Assign(_, _)       -> False
    While(_, _)        -> False
    ForIn(_, _, _, _)  -> False
    ForEach(_, _, _)   -> False
    Repeat(_, _)       -> False
    Loop(_)            -> False
    Break              -> False
    Continue           -> False
    _                  -> True

pub fun indent( s : string ) : string
  s.lines.map(fn(l) "  " ++ l).join("\n")

fun indent-all( s : string ) : string
  s.lines.map(fn(l) "  " ++ l).join("\n")
