#!/usr/bin/env bash
# Runs ON the Pi (as root) to install and activate the custom AV Cyberdeck
# webkit login screen. Not meant to be run directly on your computer - see
# scripts/deploy-webkit-greeter.sh for that.
#
# This is a separate, opt-in script from remote-apply-splash.sh because it
# changes the actual login authentication screen. It leaves pi-greeter
# fully installed and configured, so reverting is one command (printed at
# the end of this script), and SSH access is unaffected either way.

set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/AsherVerLee/AV-Cyberdeck-OS/main"
CB="cb=$(date +%s)"
THEME_DIR=/usr/share/lightdm-webkit2-greeter/themes/av-cyberdeck

echo "== Installing lightdm-webkit2-greeter =="
apt-get update -qq
apt-get install -y lightdm-webkit2-greeter

echo "== Deploying theme files =="
install -d -m 755 "${THEME_DIR}"
curl -fsSL -o "${THEME_DIR}/index.html" "${REPO_RAW}/webkit-greeter-theme/index.html?${CB}"
curl -fsSL -o "${THEME_DIR}/background.png" "${REPO_RAW}/webkit-greeter-theme/background.png?${CB}"
curl -fsSL -o "${THEME_DIR}/avatar.png" "${REPO_RAW}/webkit-greeter-theme/avatar.png?${CB}"

echo "== Configuring greeter theme =="
WEBKIT_CONF=/etc/lightdm/lightdm-webkit2-greeter.conf
if [ -f "${WEBKIT_CONF}" ] && grep -q '^theme *=' "${WEBKIT_CONF}"; then
  sed -i "s|^theme *=.*|theme = av-cyberdeck|" "${WEBKIT_CONF}"
elif [ -f "${WEBKIT_CONF}" ] && grep -q '^\[greeter\]' "${WEBKIT_CONF}"; then
  sed -i "/^\[greeter\]/a theme = av-cyberdeck" "${WEBKIT_CONF}"
else
  printf '%s\n' '[greeter]' 'theme = av-cyberdeck' > "${WEBKIT_CONF}"
fi

echo "== Switching active greeter =="
LIGHTDM_CONF=/etc/lightdm/lightdm.conf
if grep -q '^greeter-session *=' "${LIGHTDM_CONF}"; then
  sed -i "s|^greeter-session *=.*|greeter-session=lightdm-webkit2-greeter|" "${LIGHTDM_CONF}"
elif grep -q '^\[Seat:\*\]' "${LIGHTDM_CONF}"; then
  sed -i "/^\[Seat:\*\]/a greeter-session=lightdm-webkit2-greeter" "${LIGHTDM_CONF}"
else
  printf '\n[Seat:*]\ngreeter-session=lightdm-webkit2-greeter\n' >> "${LIGHTDM_CONF}"
fi

echo ""
echo "Done. Reboot to see the new login screen: sudo reboot"
echo ""
echo "If it doesn't look right or won't accept your password, revert with:"
echo "  sudo sed -i 's|^greeter-session *=.*|greeter-session=pi-greeter|' /etc/lightdm/lightdm.conf && sudo reboot"
