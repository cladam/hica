/*
 * hica – CLI end-to-end tests
 * 
 * This source file is part of the hica open source project
 * Copyright (C) 2026 Claes Adamsson <claes.adamsson@gmail.com>
 *
 * See https://github.com/cladam/hica/blob/main/LICENSE for license information
*/
import kunit
import std/os/env
import std/os/process

// ---------------------------------------------------------------------------
// Helper: run the hica binary and return its stdout (trimmed)
// ---------------------------------------------------------------------------

// The hica binary path is passed as the first CLI arg to this test runner,
// e.g.: koka -ilib/kunit -e tests/test-cli.kk -- .koka/.../src_main__main
fun get-hica-bin() : io string
  match get-args()
    Cons(bin, _) -> bin
    _            -> ".koka/v3.2.3/clang-debug-7c9b00/src_main__main"

fun hica( args : string ) : io string
  val bin = get-hica-bin()
  val cmd = bin ++ " " ++ args
  match run-system-read(cmd)
    Ok(output) -> output.trim
    Error(exn) -> "ERROR: " ++ exn.message

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

pub fun main() : io ()
  println(bold("CLI end-to-end tests"))
  println("")

  defaultKIntegrationHandler

    // --- Version ---

    itest("--version prints version string")
      val out = hica("--version")
      assert/is-true(out.contains("hica"))

    // --- Help ---

    itest("no args shows missing command error")
      val out = hica("")
      assert/is-true(out.contains("missing required argument"))
      assert/is-true(out.contains("--help"))

    itest("--help prints usage")
      val out = hica("--help")
      assert/is-true(out.contains("Usage:"))

    itest("help prints usage")
      val out = hica("help")
      assert/is-true(out.contains("Usage:"))

    itest("help build prints build help")
      val out = hica("help build")
      assert/is-true(out.contains("hica build"))
      assert/is-true(out.contains("FILE"))

    itest("help run prints run help")
      val out = hica("help run")
      assert/is-true(out.contains("hica run"))

    itest("help check prints check help")
      val out = hica("help check")
      assert/is-true(out.contains("hica check"))

    itest("help clean prints clean help")
      val out = hica("help clean")
      assert/is-true(out.contains("hica clean"))

    // --- Unknown command ---

    itest("unknown command shows error")
      val out = hica("frobnicate")
      assert/is-true(out.contains("error:"))
      assert/is-true(out.contains("frobnicate"))

    // --- Build ---

    itest("build compiles a .hc file")
      val out = hica("build examples/arrow.hc")
      assert/is-true(out.contains("compiled"))
      assert/is-true(out.contains("examples/arrow.kk"))

    itest("b is an alias for build")
      val out = hica("b examples/hello.hc")
      assert/is-true(out.contains("compiled"))

    itest("build without file shows error")
      val out = hica("build")
      assert/is-true(out.contains("error:"))
      assert/is-true(out.contains("missing file"))

    // --- Check ---

    itest("check validates a .hc file")
      val out = hica("check examples/arrow.hc")
      assert/is-true(out.contains("check:"))
      assert/is-true(out.contains("ok"))
      assert/is-true(out.contains("2 declarations"))

    itest("c is an alias for check")
      val out = hica("c examples/hello.hc")
      assert/is-true(out.contains("check:"))
      assert/is-true(out.contains("ok"))

    itest("check without file shows error")
      val out = hica("check")
      assert/is-true(out.contains("error:"))

    // --- Clean ---

    itest("clean removes build artifacts")
      // First build to ensure target/ exists
      hica("build examples/hello.hc")
      val out = hica("clean examples/hello.kk")
      assert/is-true(out.contains("removed"))

    itest("clean without an argument")
      val out = hica("clean")
      assert/is-true(out.contains("error: missing file argument"))

    // --- Aliases ---

    itest("help b resolves to build help")
      val out = hica("help b")
      assert/is-true(out.contains("hica build"))

    itest("help r resolves to run help")
      val out = hica("help r")
      assert/is-true(out.contains("hica run"))

    itest("help c resolves to check help")
      val out = hica("help c")
      assert/is-true(out.contains("hica check"))
