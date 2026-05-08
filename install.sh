#!/bin/sh
set -e

TMP_DIR="\$(mktemp -d)"

main() {
  need_cmd curl
  need_cmd uname

  local os arch
  os=\$(uname -s | tr '[:upper:]' '[:lower:]')
  arch=\$(uname -m)

  case "\$os" in
    linux)  os="linux" ;;
    darwin) os="macos" ;;
    *)      err "unsupported OS: \$os" ;;
  esac

  case "\$arch" in
    x86_64|amd64)  arch="x86_64" ;;
    aarch64|arm64) arch="aarch64" ;;
    *)             err "unsupported architecture: \$arch" ;;
  esac

  local url="https://github.com/cladam/hica/releases/latest/download/hica-\$os-\$arch"

  echo "installing hica..."
  echo "  os:   \$os"
  echo "  arch: \$arch"
  echo ""

  curl -fsSL "\$url" -o "\$TMP_DIR/hica"
  chmod +x "\$TMP_DIR/hica"

  rm -rf "\$TMP_DIR"
}

need_cmd() {
  if ! command -v "\$1" > /dev/null 2>&1; then
    err "need '\$1' (not found)"
  fi
}

err() {
  echo "error: \$1" >&2
  exit 1
}

cleanup() {
  rm -rf "\$TMP_DIR" 2>/dev/null
}

trap cleanup EXIT
main