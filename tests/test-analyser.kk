/*
 * hica – analyser unit tests
 * 
 * This source file is part of the hica open source project
 * Copyright (C) 2026 Claes Adamsson <claes.adamsson@gmail.com>
 *
 * See https://github.com/cladam/hica/blob/main/LICENSE for license information
*/
import kunit
import syntax/ast
import syntax/lexer
import syntax/parser
import semantics/checker
import semantics/analyser
import transform/desugar
import diagnostics/diagnostics
import std/os/env

extern import
  c file "test-analyser-helper.c"

extern my-process-exit(code : int) : io ()
  c inline "my_process_exit(kk_integer_clamp32(#1,kk_context()))"

extern keep-alive(scores : a) : ()
  c inline "hica_keep_alive(#1, kk_context())"

fun get-analyser-scores(source: string) : <div,console> list<function-score>
  val tokens = lex(source)
  val prog = run-parser-program(tokens, source)
  val desugared = desugar-program(prog)
  val (typed-prog, _diags) = collect-diagnostics
    run-fresh
      check-program(desugared, 0)
  
  val scores = typed-prog.decls.map(fn(d) semantics/analyser/analyse-decl(d, []))
  keep-alive(scores)
  scores

pub fun main() : io ()
  println(bold("Analyser tests"))
  println("")
  defaultKIntegrationHandler
    // A function with a pure lambda to avoid lambda noise, the actual lambda noise is the `(x) => f(x)`
    itest("detects lambda noise")
      val source = "fun foo() { let f = (x) => bar(x); f(1) }"
      val scores = get-analyser-scores(source)
      match scores.head
        Just(func) ->
          if func.items.length != 1 then
            assert/is-true(False)
          else
            match func.items.head
              Just(item) -> assert/is-true(item.points == 3)
              Nothing -> assert/is-true(False)
        Nothing -> assert/is-true(False)

    itest("detects imperative loops")
      val source = "fun foo() { var i = 0; while i < 10 { i = i + 1 } }"
      val scores = get-analyser-scores(source)
      match scores.head
        Just(func) -> assert/is-true(func.items.length == 2) // 5 for VarDecl, 5 for While
        Nothing -> assert/is-true(False)
      
    itest("detects double wrapping")
      val source = "fun foo() : maybe<maybe<int>> => Some(Some(1))"
      val scores = get-analyser-scores(source)
      match scores.head
        Just(func) ->
          assert/is-true(func.items.length == 1)
          match func.items.head
            Just(item) -> assert/is-true(item.points == 6)
            Nothing -> assert/is-true(False)
        Nothing -> assert/is-true(False)

    itest("detects nested match on wrappers")
      val source = "fun foo(m: maybe<int>) : maybe<int> => match m { Some(x) => match Some(x) { Some(y) => Some(y), None => None }, None => None }"
      val scores = get-analyser-scores(source)
      match scores.head
        Just(func) ->
          assert/is-true(func.items.length == 1)
          match func.items.head
            Just(item) -> assert/is-true(item.points == 8)
            Nothing -> assert/is-true(False)
        Nothing -> assert/is-true(False)

  // Prevent mimalloc free-list corruption during tear-down of large ASTs
  my-process-exit(0)
