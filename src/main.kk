/*
 * hica – compiler entry point
 * Copyright (C) 2026 Claes Adamsson <claes.adamsson@gmail.com>
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE 
 * SOFTWARE.
*/
module main

import syntax/ast
import syntax/lexer
import syntax/parser
import semantics/checker
import emit/codegen

fun main()
  val source = "fun double(x) => x * 2\n\nfun main() {\n  let result = double(21);\n  result\n}"
  println("hica compiler v0.1.0\n")
  println("source:")
  println(source)

  // Lex
  val tokens = lex(source)

  // Parse as program
  val prog = run-parser-program(tokens)
  println("\nAST:")
  println(prog.show)

  // Emit Koka
  val koka-code = emit-program(prog)
  println("\n--- Koka output ---")
  println(koka-code)
