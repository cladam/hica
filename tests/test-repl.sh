#!/usr/bin/env bash
set -uo pipefail

# test-repl.sh — Choreography tests for the hica REPL
#
# Pipes sequences of commands to `hica repl` from a user's perspective,
# validating startup, expressions, bindings, definitions, commands, and errors.
#
# Usage: ./tests/test-repl.sh [path/to/hica]
#
# Requires: node (for the JS runtime the REPL uses)

HICA="${1:-./hica}"
PASS=0
FAIL=0
SKIP=0
FAILURES=""

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Run the REPL with piped input; stdin-not-a-tty disables rlwrap automatically
repl() {
  printf "%s\n" "$1" | "$HICA" repl 2>&1
}

# Run the REPL with a multi-line heredoc
repl_lines() {
  "$HICA" repl 2>&1 <<'INPUT'
__REPLACED__
INPUT
}

# Check that output contains a fixed string
check() {
  local name="$1"
  local output="$2"
  local pattern="$3"
  if printf "%s" "$output" | grep -qF "$pattern"; then
    echo "  PASS  $name"
    ((PASS++))
  else
    echo "  FAIL  $name"
    echo "        expected: $pattern"
    echo "        got:      $(printf "%s" "$output" | head -5)"
    FAILURES="$FAILURES\n  $name"
    ((FAIL++))
  fi
}

# Check that output does NOT contain a fixed string
check_absent() {
  local name="$1"
  local output="$2"
  local pattern="$3"
  if ! printf "%s" "$output" | grep -qF "$pattern"; then
    echo "  PASS  $name"
    ((PASS++))
  else
    echo "  FAIL  $name (unexpected: $pattern)"
    FAILURES="$FAILURES\n  $name"
    ((FAIL++))
  fi
}

# Run multi-line REPL session from a string (newline-delimited)
repl_multi() {
  printf "%s\n" "$1" | "$HICA" repl 2>&1
}

echo "=== REPL Choreography Tests ==="
echo ""

# Check node is available (REPL uses it for JS eval)
if ! command -v node >/dev/null 2>&1; then
  echo "  SKIP  all tests (node not found — REPL requires Node.js)"
  exit 0
fi

# Check hica binary exists
if [[ ! -f "$HICA" && ! -x "$(command -v "$HICA" 2>/dev/null)" ]]; then
  echo "  ERROR  hica binary not found: $HICA"
  exit 1
fi

# ---------------------------------------------------------------------------
# Startup banner
# ---------------------------------------------------------------------------

echo "--- Startup ---"
out=$(repl "")
check "banner: shows hica"         "$out" "hica"
check "banner: shows REPL"         "$out" "REPL"
check "banner: shows Ctrl-D hint"  "$out" "Ctrl-D"
check "banner: shows prompt"       "$out" "hica=>"
echo ""

# ---------------------------------------------------------------------------
# Arithmetic expressions
# ---------------------------------------------------------------------------

echo "--- Arithmetic ---"
out=$(repl "1 + 2")
check "1 + 2 = 3" "$out" "3"

out=$(repl "10 * 10")
check "10 * 10 = 100" "$out" "100"

out=$(repl "7 - 3")
check "7 - 3 = 4" "$out" "4"

out=$(repl "10 / 2")
check "10 / 2 = 5" "$out" "5"

out=$(repl "10 % 3")
check "10 % 3 = 1" "$out" "1"
echo ""

# ---------------------------------------------------------------------------
# String expressions
# ---------------------------------------------------------------------------

echo "--- Strings ---"
out=$(printf '%s\n' '"hello" + " world"' | "$HICA" repl 2>&1)
check "string concat" "$out" "hello world"

out=$(printf '%s\n' 'str_length("foo")' | "$HICA" repl 2>&1)
check "string length" "$out" "3"
echo ""

# ---------------------------------------------------------------------------
# Boolean & comparison
# ---------------------------------------------------------------------------

echo "--- Booleans ---"
out=$(repl "2 > 1")
check "2 > 1 = true" "$out" "True"

out=$(repl "1 > 2")
check "1 > 2 = false" "$out" "False"

out=$(repl "3 == 3")
check "3 == 3 = true" "$out" "True"
echo ""

# ---------------------------------------------------------------------------
# List expressions
# ---------------------------------------------------------------------------

echo "--- Lists ---"
out=$(repl "[1, 2, 3] |> length")
check "list length = 3" "$out" "3"

out=$(printf '%s\n' 'map([1, 2, 3], (x) => x * x)' | "$HICA" repl 2>&1)
check "list map squares" "$out" "[1,4,9]"
echo ""

# ---------------------------------------------------------------------------
# Let bindings — persist across lines
# ---------------------------------------------------------------------------

echo "--- Let bindings ---"
out=$(repl "let x = 42")
check "let x = 42: prints value" "$out" "42"

out=$(printf "let x = 10\nlet y = 20\nx + y\n" | "$HICA" repl 2>&1)
check "let bindings persist: x + y = 30" "$out" "30"

out=$(printf "let name = \"alice\"\nstr_length(name)\n" | "$HICA" repl 2>&1)
check "let string binding persists" "$out" "5"
echo ""

# ---------------------------------------------------------------------------
# _ last-result variable
# ---------------------------------------------------------------------------

echo "--- _ last result ---"
out=$(printf "6 * 7\n_ + 1\n" | "$HICA" repl 2>&1)
check "_ captures 42" "$out" "42"
check "_ + 1 = 43"   "$out" "43"

out=$(printf "100\n_ * 2\n_ + 5\n" | "$HICA" repl 2>&1)
check "_ chains: 100 → 200 → 205" "$out" "205"
echo ""

# ---------------------------------------------------------------------------
# Function definitions and calls
# ---------------------------------------------------------------------------

echo "--- Functions ---"
out=$(printf "fun square(n: int): int { n * n }\n" | "$HICA" repl 2>&1)
check "fun definition: defined message" "$out" "defined: square"

out=$(printf "fun square(n: int): int { n * n }\nsquare(5)\n" | "$HICA" repl 2>&1)
check "fun call: square(5) = 25" "$out" "25"

out=$(printf "fun double(n: int): int { n * 2 }\ndouble(21)\n" | "$HICA" repl 2>&1)
check "fun call: double(21) = 42" "$out" "42"

out=$(printf "fun add(a: int, b: int): int { a + b }\nadd(3, 4)\n" | "$HICA" repl 2>&1)
check "fun call: add(3, 4) = 7" "$out" "7"
echo ""

# ---------------------------------------------------------------------------
# Multiline input (unbalanced braces continue with ...>)
# ---------------------------------------------------------------------------

echo "--- Multiline ---"
out=$(printf 'fun fib(n: int): int {\n  if n <= 1 { n } else { fib(n - 1) + fib(n - 2) }\n}\n' | "$HICA" repl 2>&1)
check "multiline fun: defined" "$out" "defined: fib"

out=$(printf 'fun fib(n: int): int {\n  if n <= 1 { n } else { fib(n - 1) + fib(n - 2) }\n}\nfib(10)\n' | "$HICA" repl 2>&1)
check "multiline fun: fib(10) = 55" "$out" "55"

out=$(printf 'fun classify(n: int): string {\n  match n {\n    0 => "zero",\n    1 => "one",\n    _ => "other"\n  }\n}\nclassify(0)\n' | "$HICA" repl 2>&1)
check "multiline match: classify(0) = zero" "$out" "zero"
echo ""

# ---------------------------------------------------------------------------
# :help command
# ---------------------------------------------------------------------------

echo "--- :help ---"
out=$(repl ":help")
check ":help shows :defs"    "$out" ":defs"
check ":help shows :reset"   "$out" ":reset"
check ":help shows :quit"    "$out" ":quit"
check ":help shows :load"    "$out" ":load"
check ":help shows :type"    "$out" ":type"
check ":help shows :history" "$out" ":history"

out=$(repl ":h")
check ":h is alias for :help" "$out" ":defs"
echo ""

# ---------------------------------------------------------------------------
# :defs command
# ---------------------------------------------------------------------------

echo "--- :defs ---"
out=$(repl ":defs")
check ":defs empty state: no definitions" "$out" "(no definitions)"

out=$(printf "fun add(a: int, b: int): int { a + b }\n:defs\n" | "$HICA" repl 2>&1)
check ":defs lists function" "$out" "fun add"

out=$(printf "struct Vec { x: int, y: int }\n:defs\n" | "$HICA" repl 2>&1)
check ":defs lists struct" "$out" "struct Vec"
echo ""

# ---------------------------------------------------------------------------
# :type / :t command
# ---------------------------------------------------------------------------

echo "--- :type ---"
out=$(repl ":t 1 + 2")
check ":t int expression" "$out" "int"

out=$(printf ':t "hello"\n' | "$HICA" repl 2>&1)
check ":t string expression" "$out" "string"

out=$(repl ":t [1, 2, 3]")
check ":t list expression" "$out" "list"

out=$(repl ":t true")
check ":t bool expression" "$out" "bool"

out=$(printf ':type "hello"\n' | "$HICA" repl 2>&1)
check ":type (long form) works" "$out" "string"
echo ""

# ---------------------------------------------------------------------------
# :reset command
# ---------------------------------------------------------------------------

echo "--- :reset ---"
out=$(printf "let x = 99\n:reset\n" | "$HICA" repl 2>&1)
check ":reset: state cleared message" "$out" "state cleared"

out=$(printf "fun foo(): int { 1 }\n:reset\n:defs\n" | "$HICA" repl 2>&1)
check ":reset: defs are gone after reset" "$out" "(no definitions)"
echo ""

# ---------------------------------------------------------------------------
# :quit command
# ---------------------------------------------------------------------------

echo "--- :quit ---"
out=$(repl ":quit")
check ":quit prints Bye!" "$out" "Bye!"

out=$(repl ":q")
check ":q is alias for :quit" "$out" "Bye!"
echo ""

# ---------------------------------------------------------------------------
# Struct definitions and field access
# ---------------------------------------------------------------------------

echo "--- Structs ---"
out=$(printf "struct Point { x: int, y: int }\n" | "$HICA" repl 2>&1)
check "struct definition: defined message" "$out" "defined: struct Point"

out=$(printf "struct Point { x: int, y: int }\nlet p = Point(3, 4)\np.x + p.y\n" | "$HICA" repl 2>&1)
check "struct field access: p.x + p.y = 7" "$out" "7"
echo ""

# ---------------------------------------------------------------------------
# Enum / type definitions
# ---------------------------------------------------------------------------

echo "--- Enums ---"
out=$(printf "type Color { Red, Green, Blue }\n" | "$HICA" repl 2>&1)
check "type definition: defined message" "$out" "defined: type Color"

out=$(printf 'type Color { Red, Green, Blue }\nfun color_val(c: Color): int {\n  match c {\n    Red => 0,\n    Green => 1,\n    Blue => 2\n  }\n}\ncolor_val(Green)\n' | "$HICA" repl 2>&1)
check "enum match: Green = 1" "$out" "1"
echo ""

# ---------------------------------------------------------------------------
# :load command
# ---------------------------------------------------------------------------

echo "--- :load ---"
out=$(printf ":load examples/fizzbuzz.hc\nfizzbuzz(15)\n" | "$HICA" repl 2>&1)
check ":load loads file: loaded message" "$out" "loaded: fizzbuzz"
check ":load: calling loaded fun fizzbuzz(15)" "$out" "fizzbuzz"

out=$(printf ":load examples/arrow.hc\n:defs\n" | "$HICA" repl 2>&1)
check ":load: definitions appear in :defs" "$out" "fun"

out=$(printf ":load nonexistent-file.hc\n" | "$HICA" repl 2>&1)
check ":load nonexistent: error message" "$out" "not found"
echo ""

# ---------------------------------------------------------------------------
# Error handling — parse errors and type errors
# ---------------------------------------------------------------------------

echo "--- Error handling ---"
out=$(printf "let = 5\n" | "$HICA" repl 2>&1)
check "parse error: shows error" "$out" "parse error"
check_absent "parse error: no crash" "$out" "Unhandled exception"

out=$(printf "1 + true\n" | "$HICA" repl 2>&1)
check "type error: shows error" "$out" "error"
check_absent "type error: no crash" "$out" "Unhandled exception"

out=$(printf "1 + true\n2 + 2\n" | "$HICA" repl 2>&1)
check "type error: REPL continues after error" "$out" "4"
echo ""

# ---------------------------------------------------------------------------
# Results
# ---------------------------------------------------------------------------

echo "Results: $PASS passed, $FAIL failed, $SKIP skipped ($((PASS+FAIL+SKIP)) total)"

if [[ $FAIL -gt 0 ]]; then
  echo ""
  echo "Failures:"
  printf "%b\n" "$FAILURES"
  exit 1
fi
