#!/bin/bash
set -euo pipefail

REPO="valllabh/qualys-cli"
GITHUB_API="https://api.github.com/repos/${REPO}/releases/latest"

info() { printf "\033[1;34m==>\033[0m %s\n" "$1"; }
success() { printf "\033[1;32m==>\033[0m %s\n" "$1"; }
error() { printf "\033[1;31mError:\033[0m %s\n" "$1" >&2; exit 1; }

# Auth header for private repos (optional)
AUTH_HEADER=""
if [ -n "${GITHUB_TOKEN:-}" ]; then
  AUTH_HEADER="Authorization: token ${GITHUB_TOKEN}"
elif [ -n "${GH_TOKEN:-}" ]; then
  AUTH_HEADER="Authorization: token ${GH_TOKEN}"
else
  # Try gh CLI token
  GH_CLI_TOKEN=$(gh auth token 2>/dev/null || echo "")
  if [ -n "$GH_CLI_TOKEN" ]; then
    AUTH_HEADER="Authorization: token ${GH_CLI_TOKEN}"
  fi
fi

curl_auth() {
  if [ -n "$AUTH_HEADER" ]; then
    curl -fsSL -H "$AUTH_HEADER" "$@"
  else
    curl -fsSL "$@"
  fi
}

# Detect OS
OS="$(uname -s)"
case "$OS" in
  Darwin) PLATFORM="darwin" ;;
  Linux)  PLATFORM="linux" ;;
  MINGW*|MSYS*|CYGWIN*)
    error "Windows detected. Download the .exe manually from https://github.com/${REPO}/releases/latest"
    ;;
  *) error "Unsupported OS: $OS" ;;
esac

# Detect architecture
ARCH="$(uname -m)"
case "$ARCH" in
  x86_64|amd64)  ARCH_SUFFIX="x64" ;;
  arm64|aarch64)  ARCH_SUFFIX="arm64" ;;
  *) error "Unsupported architecture: $ARCH" ;;
esac

BINARY_NAME="qualys-${PLATFORM}-${ARCH_SUFFIX}"
info "Detected: ${PLATFORM}/${ARCH_SUFFIX}"

# Fetch latest release tag
info "Checking latest release..."
RELEASE_JSON=$(curl_auth "$GITHUB_API" 2>/dev/null) || error "Failed to fetch release info. For private repos set GITHUB_TOKEN or login with gh auth login"
TAG=$(echo "$RELEASE_JSON" | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')
[ -z "$TAG" ] && error "Could not determine latest release tag"
info "Latest release: ${TAG}"

# Get asset download URL from API (needed for private repos)
ASSET_URL=$(echo "$RELEASE_JSON" | grep -A2 "\"name\": \"${BINARY_NAME}\"" | grep "browser_download_url" | head -1 | sed 's/.*"browser_download_url": *"\([^"]*\)".*/\1/')
if [ -z "$ASSET_URL" ]; then
  # Fallback to direct URL for public repos
  ASSET_URL="https://github.com/${REPO}/releases/download/${TAG}/${BINARY_NAME}"
fi

# For private repos, use the API asset endpoint with accept header
ASSET_ID=$(echo "$RELEASE_JSON" | grep -B5 "\"name\": \"${BINARY_NAME}\"" | grep '"id"' | head -1 | sed 's/[^0-9]//g')

# Determine install directory
INSTALL_DIR="/usr/local/bin"
if [ ! -w "$INSTALL_DIR" ] 2>/dev/null; then
  INSTALL_DIR="${HOME}/.local/bin"
  mkdir -p "$INSTALL_DIR"
fi
INSTALL_PATH="${INSTALL_DIR}/qualys"

# Download
info "Downloading ${BINARY_NAME}..."
TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT

if [ -n "$AUTH_HEADER" ] && [ -n "$ASSET_ID" ]; then
  # Private repo: use asset API with octet-stream accept
  curl -fsSL -H "$AUTH_HEADER" -H "Accept: application/octet-stream" \
    -o "$TMPFILE" "https://api.github.com/repos/${REPO}/releases/assets/${ASSET_ID}" \
    || error "Download failed"
else
  curl_auth -o "$TMPFILE" "$ASSET_URL" || error "Download failed. Check that release ${TAG} has binary ${BINARY_NAME}"
fi

# Install
chmod +x "$TMPFILE"
mv "$TMPFILE" "$INSTALL_PATH"
trap - EXIT

# Verify
INSTALLED_VERSION=$("$INSTALL_PATH" --version 2>/dev/null || echo "unknown")
success "Installed qualys ${INSTALLED_VERSION} to ${INSTALL_PATH}"

# Check PATH
case ":$PATH:" in
  *":${INSTALL_DIR}:"*) ;;
  *)
    echo ""
    echo "Add this to your shell profile to put qualys on your PATH:"
    echo "  export PATH=\"${INSTALL_DIR}:\$PATH\""
    ;;
esac
