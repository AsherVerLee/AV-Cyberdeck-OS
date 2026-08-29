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

ssh -t "${TARGET}" bash -s <<EOF
set -euo pipefail

THEME_DIR=/usr/share/plymouth/themes/av-cyberdeck
REPO_RAW="${REPO_RAW}"

sudo mkdir -p "\${THEME_DIR}"

echo "Fetching theme files..."
sudo curl -fsSL -o "\${THEME_DIR}/av-cyberdeck.plymouth" "\${REPO_RAW}/plymouth-theme/av-cyberdeck.plymouth"
sudo curl -fsSL -o "\${THEME_DIR}/av-cyberdeck.script" "\${REPO_RAW}/plymouth-theme/av-cyberdeck.script"
sudo curl -fsSL -o "\${THEME_DIR}/av-logo.png" "\${REPO_RAW}/assets/av-logo.png"

echo "Reloading theme..."
sudo plymouth-set-default-theme -R av-cyberdeck

echo "Active theme:"
cat /etc/plymouth/plymouthd.conf
EOF

echo "Done. Reboot the Pi (or use the plymouthd preview trick) to see it."
