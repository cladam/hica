#!/usr/bin/env bash
# build.sh — build libimgui_hica.a for the hica Dear ImGui binding
#
# Usage:
#   cd lib/imgui
#   ./build.sh
#
# Outputs:
#   lib/imgui/lib/libimgui_hica.a   ← link with --cclib=imgui_hica
#
# Requirements (macOS):
#   brew install sdl2
#
# Requirements (Linux):
#   sudo apt install libsdl2-dev
#
# The vendor/imgui submodule is fetched automatically if absent.
# To add it once:
#   git submodule add https://github.com/ocornut/imgui.git lib/imgui/vendor/imgui
#   git submodule update --init lib/imgui/vendor/imgui

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENDOR="$SCRIPT_DIR/vendor/imgui"
BACKEND="$SCRIPT_DIR/backend"
OUT_DIR="$SCRIPT_DIR/lib"
OUT_LIB="$OUT_DIR/libimgui_hica.a"
BUILD_TMP="$SCRIPT_DIR/.build"

# ── 1. Ensure Dear ImGui is present ──────────────────────────────────────────
if [ ! -f "$VENDOR/imgui.h" ]; then
    echo "→ Cloning Dear ImGui into vendor/imgui …"
    git clone --depth=1 https://github.com/ocornut/imgui.git "$VENDOR"
    echo "   Done."
else
    echo "→ vendor/imgui already present — skipping clone"
fi

# ── 2. Detect platform flags ─────────────────────────────────────────────────
CXX="${CXX:-clang++}"
AR="${AR:-ar}"

if [[ "$(uname)" == "Darwin" ]]; then
    SDL2_CFLAGS="$(sdl2-config --cflags)"
    PLATFORM_FLAGS="-DGL_SILENCE_DEPRECATION"
else
    SDL2_CFLAGS="$(sdl2-config --cflags)"
    PLATFORM_FLAGS=""
fi

CXX_FLAGS="-std=c++17 -O2 -fPIC -Wall \
    -I$VENDOR \
    -I$VENDOR/backends \
    -I$BACKEND \
    $SDL2_CFLAGS \
    $PLATFORM_FLAGS"

# ── 3. Compile ───────────────────────────────────────────────────────────────
mkdir -p "$BUILD_TMP" "$OUT_DIR"

SOURCES=(
    "$VENDOR/imgui.cpp"
    "$VENDOR/imgui_draw.cpp"
    "$VENDOR/imgui_tables.cpp"
    "$VENDOR/imgui_widgets.cpp"
    "$VENDOR/backends/imgui_impl_sdl2.cpp"
    "$VENDOR/backends/imgui_impl_opengl3.cpp"
    "$BACKEND/imgui_glue.cpp"
)

OBJECTS=()
for src in "${SOURCES[@]}"; do
    base="$(basename "$src" .cpp)"
    obj="$BUILD_TMP/$base.o"
    echo "→ compiling $base.cpp"
    $CXX $CXX_FLAGS -c "$src" -o "$obj"
    OBJECTS+=("$obj")
done

# ── 4. Archive ────────────────────────────────────────────────────────────────
echo "→ archiving into libimgui_hica.a"
$AR rcs "$OUT_LIB" "${OBJECTS[@]}"

echo ""
echo "Built: $OUT_LIB"
echo ""
echo "Add to hica.ini in your project:"
if [[ "$(uname)" == "Darwin" ]]; then
    echo "  [koka]"
    echo "  flags = -L./lib/imgui/lib --cclib=imgui_hica --cclib=SDL2 -framework OpenGL"
else
    echo "  [koka]"
    echo "  flags = -L./lib/imgui/lib --cclib=imgui_hica --cclib=SDL2 --cclib=GL"
fi
