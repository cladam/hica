#!/bin/sh
set -e

REPO="cladam/hica"
INSTALL_DIR="${HICA_INSTALL_DIR:-$HOME/.local/bin}"
TMP_DIR=""

main() {
  need_cmd curl
  need_cmd tar
  need_cmd uname

  TMP_DIR="$(mktemp -d)"

  local os arch artifact
  os="$(uname -s)"
  arch="$(uname -m)"

  case "$os" in
    Linux)  os="linux" ;;
    Darwin) os="macos" ;;
    *)      err "unsupported OS: $os" ;;
  esac

  case "$arch" in
    x86_64|amd64)  arch="x86_64" ;;
    aarch64|arm64) arch="arm64" ;;
    *)             err "unsupported architecture: $arch" ;;
  esac

  artifact="hica-${os}-${arch}"
  local url="https://github.com/${REPO}/releases/latest/download/${artifact}.tar.gz"

  echo "Installing hica..."
  echo "  os:      $os"
  echo "  arch:    $arch"
  echo "  install: $INSTALL_DIR"
  echo ""

  curl -fsSL "$url" -o "$TMP_DIR/${artifact}.tar.gz" \
    || err "download failed — check that a release exists for ${artifact}"

  tar xzf "$TMP_DIR/${artifact}.tar.gz" -C "$TMP_DIR"

  mkdir -p "$INSTALL_DIR"
  mv "$TMP_DIR/hica" "$INSTALL_DIR/hica"
  chmod +x "$INSTALL_DIR/hica"

  # Create hica-js wrapper script
    cat << 'EOF' > "$INSTALL_DIR/hica-js"
#!/bin/sh
set -e

if [ -f "$1" ]; then
  # Create a temporary file ending with .hc
  TMP_BASE="$(mktemp -t hica_script)"
  TMP_FILE="${TMP_BASE}.hc"
  trap 'rm -f "$TMP_BASE" "$TMP_FILE"' EXIT

  # Comment out the shebang on Line 1 (preserves line numbering)
  sed '1s/^#!/\/\//' "$1" > "$TMP_FILE"

  SCRIPT_PATH="$1"
  shift
  exec hica run --target=js "$TMP_FILE" "$@"
else
  exec hica run --target=js "$@"
fi
EOF
    chmod +x "$INSTALL_DIR/hica-js"

    echo "hica and hica-js installed to $INSTALL_DIR"

  if ! echo "$PATH" | tr ':' '\n' | grep -qx "$INSTALL_DIR"; then
    echo ""
    echo "Add hica to your PATH by adding this to your shell profile:"
    echo "  export PATH=\"$INSTALL_DIR:\$PATH\""
  fi

  echo ""
  "$INSTALL_DIR/hica" --version
}

need_cmd() {
  if ! command -v "$1" > /dev/null 2>&1; then
    err "need '$1' (not found)"
  fi
}

err() {
  echo "error: $1" >&2
  exit 1
}

cleanup() {
  if [ -n "$TMP_DIR" ]; then
    rm -rf "$TMP_DIR" 2>/dev/null
  fi
}

trap cleanup EXIT
main