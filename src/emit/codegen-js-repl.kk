/*
 * hica – JavaScript code generation for REPL mode
 * 
 * This source file is part of the hica open source project
 * Copyright (C) 2026 Claes Adamsson <claes.adamsson@gmail.com>
 *
 * See https://github.com/cladam/hica/blob/main/LICENSE for license information
 *
 * Emits JavaScript snippets for incremental REPL evaluation.
 * Each snippet is sent to a persistent Node.js subprocess.
*/
module emit/codegen-js-repl

import syntax/ast
import emit/codegen-js

// ---------------------------------------------------------------------------
// Emit a REPL snippet: either a declaration (side-effectful define)
// or an expression (evaluate and print result)
// ---------------------------------------------------------------------------

// Emit a function declaration for the REPL — just define it globally
pub fun emit-js-repl-decl( d : fun-decl ) : div string
  val params = d.params.join(", ")
  val body = emit-js-body(d.body)
  "function " ++ d.name ++ "(" ++ params ++ ") {\n" ++
  indent(body) ++ "\n" ++
  "}"

// Emit a struct definition for the REPL
pub fun emit-js-repl-struct( sd : struct-def ) : div string
  emit-js-struct(sd)

// Emit a type/enum definition for the REPL
pub fun emit-js-repl-type( td : type-def ) : div string
  emit-js-type-def(td)

// Emit an expression, evaluate it, print the result, and assign to _
pub fun emit-js-repl-expr( n : node ) : div string
  val code = emit-js-expr(n)
  "const __result = " ++ code ++ ";\n" ++
  "if (__result !== undefined && __result !== null) { println(show(__result)); _ = __result; }\n"

// Emit the preamble — includes _ variable for last result
pub fun emit-js-repl-preamble() : string
  js-runtime-preamble() ++
  "var _ = undefined;\n"

// Wrap a let-binding as a global var definition in the REPL
pub fun emit-js-repl-let( name : string, init : node ) : div string
  "var " ++ name ++ " = " ++ emit-js-expr(init) ++ ";\n" ++
  "if (" ++ name ++ " !== undefined && " ++ name ++ " !== null) { println(show(" ++ name ++ ")); _ = " ++ name ++ "; }\n"
