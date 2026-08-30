#!/usr/bin/env bash
# Installs the AV Cyberdeck software bundle on a running Pi over SSH.
# Run this from your own computer, not on the Pi itself.
#
# Usage:
#   ./scripts/deploy-software.sh [user@host]

set -euo pipefail

TARGET="${1:-asherverlee@ashdeck.local}"
REPO_RAW="https://raw.githubusercontent.com/AsherVerLee/AV-Cyberdeck-OS/main"
CB="cb=$(date +%s)"

echo "Installing software bundle on ${TARGET} ..."
echo "This installs a lot of packages - it will take several minutes."

ssh -tt "${TARGET}" "curl -fsSL '${REPO_RAW}/scripts/remote-apply-software.sh?${CB}' | sudo bash"

echo "Done."
