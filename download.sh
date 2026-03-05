#!/bin/bash
set -euo pipefail

REPO="valllabh/qualys-cli"
BINARY="qualys"

# --- Output helpers ---
info()    { printf "\n  \033[1;34minfo\033[0m  %s\n" "$1"; }
step()    { printf "  \033[1;36m  >>\033[0m  %s\n" "$1"; }
success() { printf "\n  \033[1;32mdone\033[0m  %s\n\n" "$1"; }
fail()    { printf "\n  \033[1;31merror\033[0m %s\n\n" "$1" >&2; exit 1; }

# --- Detect platform ---
detect_platform() {
  local os arch
  os="$(uname -s)"
  arch="$(uname -m)"

  case "$os" in
    Darwin) PLATFORM="darwin" ;;
    Linux)  PLATFORM="linux" ;;
    MINGW*|MSYS*|CYGWIN*)
      fail "Windows is not supported by this installer. Download the .exe from https://github.com/${REPO}/releases/latest"
      ;;
    *) fail "Unsupported operating system: $os" ;;
  esac

  case "$arch" in
    x86_64|amd64)   ARCH="x64" ;;
    arm64|aarch64)   ARCH="arm64" ;;
    *) fail "Unsupported architecture: $arch" ;;
  esac

  ASSET_NAME="${BINARY}-${PLATFORM}-${ARCH}"
  step "Platform: ${PLATFORM}/${ARCH}"
}

# --- Find latest release ---
find_latest_release() {
  local api_url="https://api.github.com/repos/${REPO}/releases/latest"
  local response

  response=$(curl -fsSL "$api_url" 2>/dev/null) || fail "Could not reach GitHub. Check your internet connection."

  TAG=$(echo "$response" | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')
  [ -z "$TAG" ] && fail "No releases found for ${REPO}"

  DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${TAG}/${ASSET_NAME}"
  step "Latest version: ${TAG}"
}

# --- Choose install directory ---
choose_install_dir() {
  INSTALL_DIR="/usr/local/bin"
  NEEDS_SUDO=""

  if [ ! -w "$INSTALL_DIR" ] 2>/dev/null; then
    # Try user local bin first
    INSTALL_DIR="${HOME}/.local/bin"
    mkdir -p "$INSTALL_DIR"
  fi

  INSTALL_PATH="${INSTALL_DIR}/${BINARY}"
  step "Install location: ${INSTALL_PATH}"
}

# --- Download binary ---
download_binary() {
  TMPFILE=$(mktemp)
  trap 'rm -f "$TMPFILE"' EXIT

  curl -fsSL --progress-bar -o "$TMPFILE" "$DOWNLOAD_URL" \
    || fail "Download failed. Verify the release ${TAG} has a binary named ${ASSET_NAME} at https://github.com/${REPO}/releases/latest"

  chmod +x "$TMPFILE"
  step "Downloaded ${ASSET_NAME}"
}

# --- Install binary ---
install_binary() {
  if [ -f "$INSTALL_PATH" ]; then
    local old_version
    old_version=$("$INSTALL_PATH" --version 2>/dev/null || echo "unknown")
    step "Replacing existing installation (v${old_version})"
  fi

  mv "$TMPFILE" "$INSTALL_PATH"
  trap - EXIT

  local installed_version
  installed_version=$("$INSTALL_PATH" --version 2>/dev/null || echo "unknown")
  step "Installed version: v${installed_version}"
}

# --- Check PATH ---
check_path() {
  case ":$PATH:" in
    *":${INSTALL_DIR}:"*) ;;
    *)
      echo ""
      echo "  Add ${INSTALL_DIR} to your PATH by adding this line to your shell profile:"
      echo ""
      echo "    export PATH=\"${INSTALL_DIR}:\$PATH\""
      echo ""
      ;;
  esac
}

# --- Main ---
main() {
  info "Installing Qualys CLI"

  detect_platform
  find_latest_release
  choose_install_dir
  download_binary
  install_binary
  check_path

  success "Qualys CLI installed. Run 'qualys --help' to get started."
}

main
