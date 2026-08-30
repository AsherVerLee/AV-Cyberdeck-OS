#!/usr/bin/env bash
# Pushes the latest AV Cyberdeck Plymouth boot splash (theme files + logo)
# from GitHub onto a running Pi over SSH, then reloads it. Run this from
# your own computer, not on the Pi itself.
#
# Usage:
#   ./scripts/deploy-splash.sh [user@host]
#
# Defaults to asherverlee@ashdeck.local if no argument is given.

set -euo pipefail

TARGET="${1:-asherverlee@ashdeck.local}"
REPO_RAW="https://raw.githubusercontent.com/AsherVerLee/AV-Cyberdeck-OS/main"

echo "Deploying AV Cyberdeck splash to ${TARGET} ..."

ssh -tt "${TARGET}" "curl -fsSL '${REPO_RAW}/scripts/remote-apply-splash.sh' | sudo bash"

echo "Done. Reboot the Pi (or use the plymouthd preview trick) to see it."
