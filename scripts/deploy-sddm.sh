#!/usr/bin/env bash
# Installs and activates the custom AV Cyberdeck SDDM login screen on a
# running Pi over SSH. Run this from your own computer, not on the Pi.
#
# Usage:
#   ./scripts/deploy-sddm.sh [user@host]
#
# This replaces the display manager (lightdm -> sddm). Separate from the
# other deploy scripts on purpose - it's a deliberate one-time action.

set -euo pipefail

TARGET="${1:-asherverlee@ashdeck.local}"
REPO_RAW="https://raw.githubusercontent.com/AsherVerLee/AV-Cyberdeck-OS/main"
CB="cb=$(date +%s)"

echo "Deploying custom SDDM login screen to ${TARGET} ..."

ssh -tt "${TARGET}" "curl -fsSL '${REPO_RAW}/scripts/remote-apply-sddm.sh?${CB}' | sudo bash"

echo "Done. Run 'sudo reboot' on the Pi to see it."
