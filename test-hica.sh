#!/usr/bin/env bash
set -euo pipefail

echo "=== Build (Optimised) ==="
koka -O2 -ilib/klap -isrc -v0 src/main.kk -o hica
chmod +x hica

echo ""
echo "=== Verify binary ==="
./hica --version

echo ""
echo "=== Lexer tests ==="
koka -ilib/kunit -isrc -v0 -e tests/test-lexer.kk | grep -E "Results:|FAIL"

echo ""
echo "=== Parser tests ==="
koka -ilib/kunit -isrc -v0 -e tests/test-parser.kk | grep -E "Results:|FAIL"

echo ""
echo "=== Codegen tests ==="
koka -ilib/kunit -isrc -v0 -e tests/test-codegen.kk | grep -E "Results:|FAIL"

echo ""
echo "=== CLI e2e tests ==="
koka -ilib/kunit -ilib/klap -isrc -v0 -e tests/test-cli.kk -- ./hica | grep -E "Results:|FAIL"
