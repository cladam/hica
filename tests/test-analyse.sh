#!/usr/bin/env bash
set -uo pipefail

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
  examples/slice-patterns.hc
  examples/struct-patterns.hc
  examples/structs.hc
  examples/tuples.hc
)

echo "=== Analyse Tests ==="
echo ""

for f in "${EXAMPLES[@]}"; do
  if [[ ! -f "$f" ]]; then
    echo "  SKIP  $f (not found)"
    ((SKIP++))
    continue
  fi

  analyse_out=$("$HICA" analyse "$f" 2>&1)
  echo $analyse_out
  if [[ $? -ne 0 ]]; then
    echo "  FAIL  $f (Analyse failed)"
    FAILURES="$FAILURES\n  $f: Analyse failed"
    ((FAIL++))
    continue
  fi

done

echo ""
echo "Results: $PASS passed, $FAIL failed, $SKIP skipped ($((PASS+FAIL+SKIP)) total)"

if [[ $FAIL -gt 0 ]]; then
  echo ""
  echo "Failures:"
  echo "$FAILURES"
  exit 1
fi
