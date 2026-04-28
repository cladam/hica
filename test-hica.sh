#!/usr/bin/env bash
set -euo pipefail

echo "=== Build (debug) ==="
koka -isrc -v0 src/main.kk -o hica
chmod +x hica

echo ""
echo "=== Verify binary ==="
./hica --version

echo ""
echo "=== Lexer tests ==="
koka -ilib/kunit -isrc -v0 -e tests/test-lexer.kk

echo ""
echo "=== Parser tests ==="
koka -ilib/kunit -isrc -v0 -e tests/test-parser.kk

echo ""
echo "=== Codegen tests ==="
koka -ilib/kunit -isrc -v0 -e tests/test-codegen.kk

echo ""
echo "=== CLI e2e tests ==="
koka -ilib/kunit -isrc -v0 -e tests/test-cli.kk -- ./hica
