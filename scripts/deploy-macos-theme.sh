#!/usr/bin/env bash
# Installs the macOS Big Sur-style GTK theme + icons on a running Pi over
# SSH. Run this from your own computer, not on the Pi itself.
#
# Usage:
#   ./scripts/deploy-macos-theme.sh [user@host]

set -euo pipefail

TARGET="${1:-asherverlee@ashdeck.local}"
REPO_RAW="https://raw.githubusercontent.com/AsherVerLee/AV-Cyberdeck-OS/main"
CB="cb=$(date +%s)"

echo "Installing macOS-style theme on ${TARGET} ..."
echo "This clones and builds theme repos - can take a few minutes."

ssh -tt "${TARGET}" "curl -fsSL '${REPO_RAW}/scripts/remote-apply-macos-theme.sh?${CB}' | sudo bash"

echo "Done."
