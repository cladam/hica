#!/usr/bin/env bash
set -euo pipefail

# build-playground.sh — Build the hica playground (browser-based compiler)
#
# Compiles src/playground.kk with Koka's JS backend, then bundles
# the output into a single docs/playground/hica-compiler.js file.
#
# Prerequisites: koka, npx (for esbuild)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$SCRIPT_DIR/.."
OUT_DIR="$ROOT/playground"

echo "=== Building hica playground ==="

# Step 1: Compile playground.kk to JavaScript modules via Koka
echo "  [1/3] Compiling playground.kk with --target=js ..."
cd "$ROOT"
koka --target=js -isrc src/playground.kk 2>&1 | grep -E "error|warning|created|Failed" || true

# Find the generated entry module
JS_DIR=$(find .koka -type d -name 'js-*' | sort | tail -1)
if [ -z "$JS_DIR" ]; then
  echo "ERROR: Koka JS output directory not found"
  exit 1
fi

ENTRY="$JS_DIR/playground.mjs"
if [ ! -f "$ENTRY" ]; then
  echo "ERROR: $ENTRY not found — compilation may have failed"
  exit 1
fi

# Step 2: Bundle all modules into a single IIFE
echo "  [2/3] Bundling with esbuild ..."
mkdir -p "$OUT_DIR"
npx esbuild "$ENTRY" \
  --bundle \
  --format=iife \
  --global-name=__hica \
  --outfile="$OUT_DIR/hica-compiler.js" \
  2>&1

# Step 3: Report sizes
RAW_SIZE=$(ls -lh "$OUT_DIR/hica-compiler.js" | awk '{print $5}')
GZ_SIZE=$(gzip -c "$OUT_DIR/hica-compiler.js" | wc -c | awk '{printf "%.0fK", $1/1024}')
echo "  [3/3] Done!"
echo ""
echo "  Output:  $OUT_DIR/hica-compiler.js"
echo "  Size:    $RAW_SIZE raw, $GZ_SIZE gzipped"
echo ""
echo "  Serve locally:"
echo "    cd $OUT_DIR && python3 -m http.server 8080"
echo "    open http://localhost:8080"
