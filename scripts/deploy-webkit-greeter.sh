#!/usr/bin/env bash
# Installs and activates the custom AV Cyberdeck webkit login screen on a
# running Pi over SSH. Run this from your own computer, not on the Pi.
#
# Usage:
#   ./scripts/deploy-webkit-greeter.sh [user@host]
#
# Separate from deploy-splash.sh on purpose - this changes the actual
# login screen, so it's a deliberate one-time action, not something that
# should silently re-run with every routine style update.

set -euo pipefail

TARGET="${1:-asherverlee@ashdeck.local}"
REPO_RAW="https://raw.githubusercontent.com/AsherVerLee/AV-Cyberdeck-OS/main"
CB="cb=$(date +%s)"

echo "Deploying custom webkit login screen to ${TARGET} ..."

ssh -tt "${TARGET}" "curl -fsSL '${REPO_RAW}/scripts/remote-apply-webkit-greeter.sh?${CB}' | sudo bash"

echo "Done. Run 'sudo reboot' on the Pi to see it."
