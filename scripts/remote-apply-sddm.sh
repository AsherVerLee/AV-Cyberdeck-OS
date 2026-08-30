#!/usr/bin/env bash
# Runs ON the Pi (as root) to install and activate the custom AV Cyberdeck
# SDDM login screen. Not meant to be run directly on your computer - see
# scripts/deploy-sddm.sh for that.
#
# This is the biggest change yet: it replaces the display manager itself
# (lightdm -> sddm), not just a theme. pi-greeter/lightdm are left fully
# installed and configured, so reverting is a couple of commands (printed
# at the end), and SSH access is unaffected either way.

set -uo pipefail

REPO_RAW="https://raw.githubusercontent.com/AsherVerLee/AV-Cyberdeck-OS/main"
CB="cb=$(date +%s)"
THEME_DIR=/usr/share/sddm/themes/av-cyberdeck
FAIL=0

echo "== Installing sddm =="
# Installing a second display manager alongside lightdm normally pops an
# interactive debconf prompt asking which one should be default, which
# would hang a non-interactive install. Pre-answer it.
echo "sddm shared/default-x-display-manager select sddm" | debconf-set-selections
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y sddm
if ! dpkg -l sddm >/dev/null 2>&1; then
  echo "ERROR: sddm did not install. Aborting before touching any config."
  echo "Nothing was changed; lightdm is still active."
  exit 1
fi
echo "sddm installed OK."

echo "== Deploying theme files =="
install -d -m 755 "${THEME_DIR}"
curl -fsSL -o "${THEME_DIR}/metadata.desktop" "${REPO_RAW}/sddm-theme/metadata.desktop?${CB}" || FAIL=1
curl -fsSL -o "${THEME_DIR}/theme.conf" "${REPO_RAW}/sddm-theme/theme.conf?${CB}" || FAIL=1
curl -fsSL -o "${THEME_DIR}/Main.qml" "${REPO_RAW}/sddm-theme/Main.qml?${CB}" || FAIL=1
curl -fsSL -o "${THEME_DIR}/background.png" "${REPO_RAW}/sddm-theme/background.png?${CB}" || FAIL=1
curl -fsSL -o "${THEME_DIR}/avatar.png" "${REPO_RAW}/sddm-theme/avatar.png?${CB}" || FAIL=1

if [ "${FAIL}" -ne 0 ]; then
  echo "ERROR: one or more theme files failed to download. Not switching the"
  echo "display manager over - lightdm is still active and unaffected."
  exit 1
fi
echo "Theme files deployed OK: $(ls ${THEME_DIR})"

echo "== Configuring sddm to use the theme =="
install -d -m 755 /etc/sddm.conf.d
printf '%s\n' "[Theme]" "Current=av-cyberdeck" > /etc/sddm.conf.d/av-cyberdeck.conf
echo "Wrote /etc/sddm.conf.d/av-cyberdeck.conf"

echo "== Switching default display manager to sddm =="
SDDM_BIN="$(command -v sddm)"
if [ -z "${SDDM_BIN}" ]; then
  echo "ERROR: sddm installed but its binary isn't on PATH. Not switching over."
  exit 1
fi
echo "${SDDM_BIN}" > /etc/X11/default-display-manager
systemctl disable lightdm.service >/dev/null 2>&1 || true
systemctl enable sddm.service

echo ""
echo "Done. Reboot to see it: sudo reboot"
echo ""
echo "If it doesn't come up right, or won't accept your password, revert with:"
echo "  echo /usr/sbin/lightdm | sudo tee /etc/X11/default-display-manager"
echo "  sudo systemctl disable sddm && sudo systemctl enable lightdm"
echo "  sudo reboot"
