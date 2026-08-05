module semantics/docgen

import std/os/path
import std/os/dir
import std/os/file
import syntax/ast
import semantics/analyser

// Known effectful functions
val console-fns = ["println", "eprintln"]
val fsys-fns    = ["read_file", "write_file", "read_lines", "write_lines"]
val io-fns      = ["input", "get_args", "get_env", "set_env", "set_env_nooverwrite"]

// Walks a node to determine if it has certain effect triggers
fun walk-node-effects( n : node, extra-effectful : list<string> ) : div (bool, bool, bool) // (has-io, has-console, has-loop)
  match n.expr
    Call(callee, args) ->
      val (callee-io, callee-con, callee-loop) = walk-node-effects(callee, extra-effectful)
      var cur-io := callee-io
      var cur-con := callee-con
      match callee.expr
        Var(name) ->
          if io-fns.any(fn(f) f == name) || fsys-fns.any(fn(f) f == name) || extra-effectful.any(fn(f) f == name) then
            cur-io := True
          if console-fns.any(fn(f) f == name) then
            cur-con := True
        _ -> ()
      args.foldl((cur-io, cur-con, callee-loop)) fn((io, con-eff, lp), arg)
        val (aio, acon, alp) = walk-node-effects(arg, extra-effectful)
        (io || aio, con-eff || acon, lp || alp)
    Let(_, _, init, body) ->
      val (iio, icon, ilp) = walk-node-effects(init, extra-effectful)
      val (bio, bcon, blp) = walk-node-effects(body, extra-effectful)
      (iio || bio, icon || bcon, ilp || blp)
    VarDecl(_, _, init, body) ->
      val (iio, icon, ilp) = walk-node-effects(init, extra-effectful)
      val (bio, bcon, blp) = walk-node-effects(body, extra-effectful)
      (iio || bio, icon || bcon, ilp || blp)
    Assign(_, v) -> walk-node-effects(v, extra-effectful)
    Fun(_, body) -> walk-node-effects(body, extra-effectful)
    Binary(_, lhs, rhs) ->
      val (lio, lcon, llp) = walk-node-effects(lhs, extra-effectful)
      val (rio, rcon, rlp) = walk-node-effects(rhs, extra-effectful)
      (lio || rio, lcon || rcon, llp || rlp)
    Unary(_, operand) -> walk-node-effects(operand, extra-effectful)
    If(cond, then-e, else-e) ->
      val (cio, ccon, clp) = walk-node-effects(cond, extra-effectful)
      val (tio, tcon, tlp) = walk-node-effects(then-e, extra-effectful)
      val (eio, econ, elp) = walk-node-effects(else-e, extra-effectful)
      (cio || tio || eio, ccon || tcon || econ, clp || tlp || elp)
    Block(stmts) ->
      stmts.foldl((False, False, False)) fn((io, con-eff, lp), s)
        val (sio, scon, slp) = walk-node-effects(s, extra-effectful)
        (io || sio, con-eff || scon, lp || slp)
    Match(scrut, arms) ->
      val (sio, scon, slp) = walk-node-effects(scrut, extra-effectful)
      arms.foldl((sio, scon, slp)) fn((io, con-eff, lp), arm)
        val (aio, acon, alp) = walk-node-effects(arm.body, extra-effectful)
        val (gio, gcon, glp) = match arm.guard
          Just(g) -> walk-node-effects(g, extra-effectful)
          Nothing -> (False, False, False)
        (io || aio || gio, con-eff || acon || gcon, lp || alp || glp)
    Repeat(count, body) ->
      val (cio, ccon, clp) = walk-node-effects(count, extra-effectful)
      val (bio, bcon, blp) = walk-node-effects(body, extra-effectful)
      (cio || bio, ccon || bcon, clp || blp)
    ForIn(_, start-e, end-e, body) ->
      val (sio, scon, slp) = walk-node-effects(start-e, extra-effectful)
      val (eio, econ, elp) = walk-node-effects(end-e, extra-effectful)
      val (bio, bcon, blp) = walk-node-effects(body, extra-effectful)
      (sio || eio || bio, scon || econ || bcon, True || slp || elp || blp)
    ForEach(_, coll, body) ->
      val (cio, ccon, clp) = walk-node-effects(coll, extra-effectful)
      val (bio, bcon, blp) = walk-node-effects(body, extra-effectful)
      (cio || bio, ccon || bcon, True || clp || blp)
    While(cond, body) ->
      val (cio, ccon, clp) = walk-node-effects(cond, extra-effectful)
      val (bio, bcon, blp) = walk-node-effects(body, extra-effectful)
      (cio || bio, ccon || bcon, True || clp || blp)
    Loop(body) ->
      val (bio, bcon, blp) = walk-node-effects(body, extra-effectful)
      (bio, bcon, True || blp)
    StringInterp(parts) ->
      parts.foldl((False, False, False)) fn((io, con-eff, lp), p)
        val (pio, pcon, plp) = walk-node-effects(p, extra-effectful)
        (io || pio, con-eff || pcon, lp || plp)
    Tuple(elems) ->
      elems.foldl((False, False, False)) fn((io, con-eff, lp), e)
        val (eio, econ, elp) = walk-node-effects(e, extra-effectful)
        (io || eio, con-eff || econ, lp || elp)
    EList(elems) ->
      elems.foldl((False, False, False)) fn((io, con-eff, lp), e)
        val (eio, econ, elp) = walk-node-effects(e, extra-effectful)
        (io || eio, con-eff || econ, lp || elp)
    ListIndex(lst, idx) ->
      val (lio, lcon, llp) = walk-node-effects(lst, extra-effectful)
      val (iio, icon, ilp) = walk-node-effects(idx, extra-effectful)
      (lio || iio, lcon || icon, llp || ilp)
    ListSlice(lst, s, e) ->
      val (lio, lcon, llp) = walk-node-effects(lst, extra-effectful)
      val (sio, scon, slp) = match s { Just(x) -> walk-node-effects(x, extra-effectful); Nothing -> (False, False, False) }
      val (eio, econ, elp) = match e { Just(x) -> walk-node-effects(x, extra-effectful); Nothing -> (False, False, False) }
      (lio || sio || eio, lcon || scon || econ, llp || slp || elp)
    TupleIndex(tup, _) -> walk-node-effects(tup, extra-effectful)
    LetTuple(_, init, body) ->
      val (iio, icon, ilp) = walk-node-effects(init, extra-effectful)
      val (bio, bcon, blp) = walk-node-effects(body, extra-effectful)
      (iio || bio, icon || bcon, ilp || blp)
    ESome(v) -> walk-node-effects(v, extra-effectful)
    EOk(v) -> walk-node-effects(v, extra-effectful)
    EErr(v) -> walk-node-effects(v, extra-effectful)
    FieldAccess(o, _) -> walk-node-effects(o, extra-effectful)
    StructLit(_, fields) ->
      fields.foldl((False, False, False)) fn((io, con-eff, lp), (_, v))
        val (vio, vcon, vlp) = walk-node-effects(v, extra-effectful)
        (io || vio, con-eff || vcon, lp || vlp)
    _ -> (False, False, False)

fun format-decl-signature( decl : fun-decl ) : div string
  fun format-params(ps: list<string>, ts: list<hica-type>) : div string
    match (ps, ts)
      (Cons(p, prs), Cons(t, trs)) ->
        val rest = format-params(prs, trs)
        val sep = if rest.is-empty then "" else ", "
        p ++ ": " ++ t.show ++ sep ++ rest
      _ -> ""

  val ret-str = match decl.ret-type
    Just(t) -> " : " ++ t.show
    Nothing -> ""
  "fun " ++ decl.name ++ "(" ++ format-params(decl.params, decl.param-types) ++ ")" ++ ret-str

fun resolve-line-num( source : string, start-pos : int ) : int
  source.list.take(start-pos).filter(fn(c) c == '\n').length + 1

// ARCHITECTURE.md
pub fun generate-architecture-md( prog : program, source : string, file : string ) : div string
  val public-decls = prog.decls.filter(is-pub)
  val public-structs = prog.structs.filter(is-pub)
  val public-types = prog.types.filter(is-pub)
  
  var md := "# Project Architecture & Export Directory: `" ++ file.path.basename ++ "`\n\n"
  
  md := md ++ "## Module Overview\n"
  md := md ++ "- **Source File:** `" ++ file ++ "`\n"
  if !prog.imports.is-nil then
    md := md ++ "## Dependencies\n"
    prog.imports.foreach fn(imp)
      val pub-str = if imp.is-pub then " (re-exported)" else ""
      val ext-str = if imp.is-extern then " (extern)" else ""
      md := md ++ "- `" ++ imp.path ++ "`" ++ pub-str ++ ext-str ++ "\n"
    md := md ++ "\n"

  if !public-decls.is-nil || !public-structs.is-nil || !public-types.is-nil then
    md := md ++ "## Public API Catalog\n\n"
    if !public-decls.is-nil then
      md := md ++ "### Public Functions\n\n"
      md := md ++ "| Function | Signature | Description |\n"
      md := md ++ "| --- | --- | --- |\n"
      public-decls.foreach fn(d)
        val sig = format-decl-signature(d)
        val doc-str = d.doc.default("*(No documentation provided)*")
        md := md ++ "| `" ++ d.name ++ "` | `" ++ sig ++ "` | " ++ doc-str.replace-all("\n", " ") ++ " |\n"
      md := md ++ "\n"

    if !public-structs.is-nil then
      md := md ++ "### Public Structs\n\n"
      public-structs.foreach fn(s)
        val doc-str = s.doc.default("*(No documentation provided)*")
        md := md ++ "- **`" ++ s.name ++ "`**: " ++ doc-str ++ "\n"
      md := md ++ "\n"

    if !public-types.is-nil then
      md := md ++ "### Public Enums / ADTs\n\n"
      public-types.foreach fn(t)
        val doc-str = t.doc.default("*(No documentation provided)*")
        md := md ++ "- **`" ++ t.name ++ "`**: " ++ doc-str ++ "\n"
      md := md ++ "\n"
  else
    md := md ++ "*(No public API exported)*\n"
    
  md

// MODELS.md
pub fun generate-models-md( prog : program ) : div string
  var md := "# Domain Data Models & Type Dictionary\n\n"
  
  if prog.structs.is-nil && prog.types.is-nil then
    md := md ++ "*(No structs or enums defined in this module)*\n"
  else
    if !prog.structs.is-nil then
      md := md ++ "## Structs (Data Models)\n\n"
      prog.structs.foreach fn(s)
        val pub-str = if s.is-pub then " `pub`" else ""
        md := md ++ "### Struct `" ++ s.name ++ "`" ++ pub-str ++ "\n"
        if !s.doc.is-nothing then
          md := md ++ s.doc.default("") ++ "\n\n"
        md := md ++ "| Field | Type | Description |\n"
        md := md ++ "| --- | --- | --- |\n"
        s.fields.foreach fn((f, t))
          md := md ++ "| `" ++ f ++ "` | `" ++ t.show ++ "` | *(Field)* |\n"
        md := md ++ "\n"
        
    if !prog.types.is-nil then
      md := md ++ "## Algebraic Data Types (Enums)\n\n"
      prog.types.foreach fn(t)
        val pub-str = if t.is-pub then " `pub`" else ""
        md := md ++ "### Type `" ++ t.name ++ "`" ++ pub-str ++ "\n"
        if !t.doc.is-nothing then
          md := md ++ t.doc.default("") ++ "\n\n"
        md := md ++ "#### Variants\n"
        t.variants.foreach fn(v)
          val fields-str = if v.fields.is-nil then "" else "(" ++ v.fields.map(fn((f, fty)) f ++ ": " ++ fty.show).join(", ") ++ ")"
          md := md ++ "- `" ++ v.name ++ fields-str ++ "`\n"
        md := md ++ "\n"
        
  md

// EFFECTS.md
pub fun generate-effects-md( prog : program, extra-effectful : list<string> ) : div string
  var md := "# Purity and Side Effects Tracking Matrix\n\n"
  
  md := md ++ "| Function | Signature | Purity Status | Detected Effect Dependencies |\n"
  md := md ++ "| --- | --- | --- | --- |\n"
  
  prog.decls.foreach fn(d)
    val (has-io, has-con, has-loop) = walk-node-effects(d.body, extra-effectful)
    val is-divergent = d.is-recursive || has-loop
    
    val effects = []
      ++ (if has-io then ["I/O & FileSystem"] else [])
      ++ (if has-con then ["Console"] else [])
      ++ (if is-divergent then ["Divergent (recursion/loop)"] else [])
    
    val (status, eff-deps) = if effects.is-nil then
      ("✅ Pure", "None")
    else
      ("⚡ Impure", effects.join(", "))
      
    val sig = format-decl-signature(d)
    md := md ++ "| `" ++ d.name ++ "` | `" ++ sig ++ "` | " ++ status ++ " | " ++ eff-deps ++ " |\n"
    
  md

// HEALTH.md
pub fun generate-health-md( prog : program, source : string, file : string, extra-effectful : list<string> ) : div string
  val scores = prog.decls.map(fn(d) analyse-decl(d, extra-effectful))
  val total = scores.map(fn(s) s.items.map(points).sum).sum
  
  // Reuse existing analyser formatting for HEALTH.md
  format-markdown(file, source, scores, total, prog.decls.length, 10)

// ROUTER.md
pub fun generate-router-md( prog : program, source : string, file : string, out-dir : string ) : div string
  var md := "# Router Map & Symbolic Index\n\n"
  
  md := md ++ "This index maps symbol names to their original file ranges, for tool and human reference.\n\n"

  // build a relative prefix so links resolve from within out-dir back to the repo root
  val segs = out-dir.split("/").filter(fn(s) !s.is-empty)
  val rel-prefix = segs.foldl("", fn(acc, _seg) acc ++ "../")
  
  prog.decls.foreach fn(d)
    val line = resolve-line-num(source, d.span.start)
    val desc = match d.doc { Just(x) -> " — " ++ x.replace-all("\n", " "); Nothing -> "" }
    md := md ++ "- [`" ++ d.name ++ "`](" ++ rel-prefix ++ file ++ "#L" ++ line.show ++ ")" ++ desc ++ "\n"
    
  md

// Main Entry Point to generate all documentation
pub fun generate-all-docs( prog : program, source : string, file : string, out-dir : string, extra-effectful : list<string> ) : io ()
  val out-path = out-dir.path
  ensure-dir(out-path)

  println("[docgen] Generating index.md...")
  val arch-md    = generate-architecture-md(prog, source, file)
  val models-md  = generate-models-md(prog)
  val effects-md = generate-effects-md(prog, extra-effectful)
  val health-md  = generate-health-md(prog, source, file, extra-effectful)
  val router-md  = generate-router-md(prog, source, file, out-dir)

  val index-md = arch-md ++ "\n---\n\n" ++ models-md ++ "\n---\n\n" ++ effects-md ++ "\n---\n\n" ++ health-md ++ "\n---\n\n" ++ router-md

  write-text-file(out-path / "index.md".path, index-md)
  println("Documentation generated in `" ++ out-dir ++ "/index.md`.")

// Drift Check Algorithm
pub fun check-all-docs( prog : program, source : string, file : string, out-dir : string, extra-effectful : list<string> ) : io bool
  val out-path = out-dir.path

  val arch-md    = generate-architecture-md(prog, source, file)
  val models-md  = generate-models-md(prog)
  val effects-md = generate-effects-md(prog, extra-effectful)
  val health-md  = generate-health-md(prog, source, file, extra-effectful)
  val router-md  = generate-router-md(prog, source, file, out-dir)

  val index-gen = arch-md ++ "\n---\n\n" ++ models-md ++ "\n---\n\n" ++ effects-md ++ "\n---\n\n" ++ health-md ++ "\n---\n\n" ++ router-md

  val fpath = out-path / "index.md".path
  if !is-file(fpath) then
    println("Drift Check Fail: `" ++ fpath.string ++ "` does not exist.")
    False
  else
    val disc-content = read-text-file(fpath)
    if disc-content != index-gen then
      println("Drift Check Fail: `" ++ fpath.string ++ "` has out-of-sync content.")
      False
    else
      println("Documentation is up to date.")
      True
