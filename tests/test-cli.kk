/*
 * hica – CLI end-to-end tests
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
import kunit
import std/os/env
import std/os/process

// ---------------------------------------------------------------------------
// Helper: run the hica binary and return its stdout (trimmed)
// ---------------------------------------------------------------------------

// The hica binary path is passed as the first CLI arg to this test runner,
// e.g.: koka -e tests/test-cli.kk -- .koka/.../src_main__main
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
      assert/is-true(out.contains("(koka)"))

    itest("-V is an alias for --version")
      val out = hica("-V")
      assert/is-true(out.contains("hica"))
      assert/is-true(out.contains("(koka)"))

    // --- Help ---

    itest("no args prints usage")
      val out = hica("")
      assert/is-true(out.contains("Usage:"))
      assert/is-true(out.contains("Commands:"))

    itest("--help prints usage")
      val out = hica("--help")
      assert/is-true(out.contains("Usage:"))

    itest("-h prints usage")
      val out = hica("-h")
      assert/is-true(out.contains("Usage:"))

    itest("help prints usage")
      val out = hica("help")
      assert/is-true(out.contains("Usage:"))

    itest("help build prints build help")
      val out = hica("help build")
      assert/is-true(out.contains("hica build"))
      assert/is-true(out.contains("<FILE>"))

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
      assert/is-true(out.contains("target/main.kk"))

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

    itest("clean removes target directory")
      // First build to ensure target/ exists
      hica("build examples/hello.hc")
      val out = hica("clean")
      assert/is-true(out.contains("removed"))

    itest("clean when nothing to clean")
      // target/ was just removed
      val out = hica("clean")
      assert/is-true(out.contains("nothing to clean"))

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
