#!/usr/bin/env bash
set -uo pipefail

# test-js.sh — Verify the JavaScript codegen backend produces the same output
# as the native Koka backend for a curated set of examples.
#
# Usage: ./tests/test-js.sh [path/to/hica]
#
# Requires: node, hica binary already built

HICA="${1:-./hica}"
PASS=0
FAIL=0
SKIP=0
FAILURES=""

# Examples that work with the JS backend (no unsupported prelude functions)
EXAMPLES=(
  examples/hello.hc
  examples/fizzbuzz.hc
  examples/recursion.hc
  examples/closures.hc
  examples/for-loops.hc
  examples/match.hc
  examples/enums.hc
  examples/binary-tree.hc
  examples/if-else.hc
  examples/math.hc
  examples/logic.hc
  examples/lambda.hc
  examples/higher-order.hc
  examples/chars.hc
  examples/float-enum-show.hc
  examples/combinators.hc
  examples/lists.hc
  examples/pipe.hc
)

cleanup() {
  # Remove generated .js files
  for f in "${EXAMPLES[@]}"; do
    local stem
    stem=$(basename "$f" .hc)
    local dir
    dir=$(dirname "$f")
    rm -f "$dir/$stem.js" "$dir/hc-$stem.js"
  done
}

trap cleanup EXIT

echo "=== JS Backend Tests ==="
echo ""

for f in "${EXAMPLES[@]}"; do
  if [[ ! -f "$f" ]]; then
    echo "  SKIP  $f (not found)"
    ((SKIP++))
    continue
  fi

  # Build native binary and run it directly (avoid capturing "compiled..." message)
  "$HICA" build "$f" >/dev/null 2>&1
  stem=$(basename "$f" .hc)
  dir=$(dirname "$f")
  native_bin="$dir/$stem"
  if [[ ! -f "$native_bin" ]]; then
    native_bin="$dir/hc-$stem"
  fi
  native_out=$("$native_bin" 2>/dev/null || true)

  # Build JS
  js_build_out=$("$HICA" build --target=js "$f" 2>&1)
  if [[ $? -ne 0 ]]; then
    echo "  FAIL  $f (JS build failed)"
    FAILURES="$FAILURES\n  $f: JS build failed"
    ((FAIL++))
    continue
  fi

  # Determine the output .js filename (may have hc- prefix for keyword names)
  stem=$(basename "$f" .hc)
  dir=$(dirname "$f")
  js_file="$dir/$stem.js"
  if [[ ! -f "$js_file" ]]; then
    js_file="$dir/hc-$stem.js"
  fi
  if [[ ! -f "$js_file" ]]; then
    echo "  FAIL  $f (JS file not found)"
    FAILURES="$FAILURES\n  $f: .js file not found"
    ((FAIL++))
    continue
  fi

  # Run JS and capture output
  js_out=$(node "$js_file" 2>/dev/null || true)

  # Compare
  if [[ "$native_out" == "$js_out" ]]; then
    echo "  PASS  $f"
    ((PASS++))
  else
    echo "  FAIL  $f (output mismatch)"
    FAILURES="$FAILURES\n  $f: expected=$(echo "$native_out" | head -3) got=$(echo "$js_out" | head -3)"
    ((FAIL++))
  fi
done

echo ""
echo "Results: $PASS passed, $FAIL failed, $SKIP skipped ($((PASS+FAIL+SKIP)) total)"

if [[ $FAIL -gt 0 ]]; then
  echo ""
  echo "Failures:"
  echo -e "$FAILURES"
  exit 1
fi
