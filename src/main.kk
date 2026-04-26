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

import std/os/env
import std/os/dir
import std/os/file
import std/os/path
import std/os/process

import syntax/ast
import syntax/lexer
import syntax/parser
import semantics/checker
import emit/codegen

val version = "0.1.0"

fun main()
  val args = get-args()
  match args
    Cons("build", rest) -> cmd-build(rest)
    Cons("run", rest)   -> cmd-run(rest)
    Cons("help", _)     -> print-usage()
    Cons(other, _)      -> 
      println("error: unknown command '" ++ other ++ "'\n")
      print-usage()
    Nil                 -> print-usage()

// ---------------------------------------------------------------------------
// Commands
// ---------------------------------------------------------------------------

fun cmd-build( args : list<string> )
  match args
    Cons(file, _) -> build(file)
    Nil ->
      println("error: missing file argument")
      println("usage: hica build <file.hc>")

fun cmd-run( args : list<string> )
  match args
    Cons(file, _) ->
      build(file)
      run-koka()
    Nil ->
      println("error: missing file argument")
      println("usage: hica run <file.hc>")

// ---------------------------------------------------------------------------
// Build pipeline: read .hc → lex → parse → emit → write .kk
// ---------------------------------------------------------------------------

fun build( file : string )
  val source = read-text-file(file.path)
  val tokens = lex(source)
  val prog   = run-parser-program(tokens)
  val koka-code = emit-program(prog)
  val target-dir = "target".path
  ensure-dir(target-dir)
  val out-file = target-dir / "main.kk".path
  write-text-file(out-file, koka-code)
  println("compiled " ++ file ++ " -> " ++ out-file.show)

// ---------------------------------------------------------------------------
// Run: invoke koka on the generated file
// ---------------------------------------------------------------------------

fun run-koka()
  val exit-code = run-system("koka -e target/main.kk")
  if exit-code != 0 then
    println("error: koka failed with exit code " ++ exit-code.show)

// ---------------------------------------------------------------------------
// Help
// ---------------------------------------------------------------------------

fun print-usage()
  println("hica v" ++ version ++ " (koka)\n")
  println("Usage: hica <command>\n")
  println("Commands:")
  println("    build      Compile a .hc file to Koka")
  println("    run        Compile and run a .hc file")
  println("    help       Print this message")
  println("")
  println("Hint: Run hica help <command> to learn more about a command.")
