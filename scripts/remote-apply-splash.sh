#!/usr/bin/env bash
# Runs ON the Pi (as root) to fetch and activate the latest AV Cyberdeck
# Plymouth splash. Not meant to be run directly on your computer -
# see scripts/deploy-splash.sh for that.

set -euo pipefail

THEME_DIR=/usr/share/plymouth/themes/av-cyberdeck
REPO_RAW="https://raw.githubusercontent.com/AsherVerLee/AV-Cyberdeck-OS/main"

mkdir -p "${THEME_DIR}"

echo "Fetching theme files..."
curl -fsSL -o "${THEME_DIR}/av-cyberdeck.plymouth" "${REPO_RAW}/plymouth-theme/av-cyberdeck.plymouth"
curl -fsSL -o "${THEME_DIR}/av-cyberdeck.script" "${REPO_RAW}/plymouth-theme/av-cyberdeck.script"
curl -fsSL -o "${THEME_DIR}/av-logo.png" "${REPO_RAW}/assets/av-logo.png"

echo "Reloading theme..."
plymouth-set-default-theme -R av-cyberdeck

echo "Active theme:"
cat /etc/plymouth/plymouthd.conf
