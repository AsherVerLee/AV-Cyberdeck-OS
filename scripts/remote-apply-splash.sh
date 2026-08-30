#!/usr/bin/env bash
# Runs ON the Pi (as root) to fetch and apply the latest AV Cyberdeck style:
# boot splash, MOTD, shell prompt, wallpaper, and dark theme preference.
# Not meant to be run directly on your computer - see scripts/deploy-splash.sh.

set -euo pipefail

PI_USER=asherverlee
PI_HOME="/home/${PI_USER}"
THEME_DIR=/usr/share/plymouth/themes/av-cyberdeck
REPO_RAW="https://raw.githubusercontent.com/AsherVerLee/AV-Cyberdeck-OS/main"

echo "== Boot splash =="
mkdir -p "${THEME_DIR}"
curl -fsSL -o "${THEME_DIR}/av-cyberdeck.plymouth" "${REPO_RAW}/plymouth-theme/av-cyberdeck.plymouth"
curl -fsSL -o "${THEME_DIR}/av-cyberdeck.script" "${REPO_RAW}/plymouth-theme/av-cyberdeck.script"
curl -fsSL -o "${THEME_DIR}/av-logo.png" "${REPO_RAW}/assets/av-logo.png"
plymouth-set-default-theme -R av-cyberdeck
echo "Active theme: $(grep -m1 '^Theme=' /etc/plymouth/plymouthd.conf || echo unknown)"

echo "== MOTD =="
curl -fsSL -o /etc/update-motd.d/10-av-cyberdeck "${REPO_RAW}/motd/10-av-cyberdeck"
chmod 755 /etc/update-motd.d/10-av-cyberdeck

echo "== Shell prompt =="
if ! grep -q "AV Cyberdeck prompt" /etc/bash.bashrc; then
  {
    echo ""
    echo "# AV Cyberdeck prompt"
    echo "PS1='\[\e[38;2;254;232;1m\]\u@\h \[\e[38;2;57;196;182m\]\w \[\e[38;2;154;159;23m\]\$\[\e[0m\] '"
  } >> /etc/bash.bashrc
  echo "Prompt added."
else
  echo "Prompt already present, skipping."
fi

echo "== Wallpaper =="
install -o "${PI_USER}" -g "${PI_USER}" -m 755 -d "${PI_HOME}/.local/share/av-cyberdeck"
curl -fsSL -o "${PI_HOME}/.local/share/av-cyberdeck/wallpaper.png" "${REPO_RAW}/assets/wallpaper.png"
chown "${PI_USER}:${PI_USER}" "${PI_HOME}/.local/share/av-cyberdeck/wallpaper.png"

install -o "${PI_USER}" -g "${PI_USER}" -m 755 -d "${PI_HOME}/.config/autostart"
cat > "${PI_HOME}/.config/autostart/av-wallpaper.desktop" <<AUTOSTART
[Desktop Entry]
Type=Application
Name=AV Cyberdeck Wallpaper
Exec=pcmanfm --set-wallpaper=${PI_HOME}/.local/share/av-cyberdeck/wallpaper.png --wallpaper-mode=stretch
X-GNOME-Autostart-enabled=true
AUTOSTART
chown "${PI_USER}:${PI_USER}" "${PI_HOME}/.config/autostart/av-wallpaper.desktop"
# Apply immediately if a desktop session is already running.
sudo -u "${PI_USER}" pcmanfm --set-wallpaper="${PI_HOME}/.local/share/av-cyberdeck/wallpaper.png" --wallpaper-mode=stretch >/dev/null 2>&1 || true

echo "== Dark theme =="
install -o "${PI_USER}" -g "${PI_USER}" -m 755 -d "${PI_HOME}/.config/gtk-3.0"
cat > "${PI_HOME}/.config/gtk-3.0/settings.ini" <<GTK
[Settings]
gtk-application-prefer-dark-theme=1
GTK
chown "${PI_USER}:${PI_USER}" "${PI_HOME}/.config/gtk-3.0/settings.ini"

echo "== config.txt overlays (power button) =="
CONFIG=/boot/firmware/config.txt
grep -qxF 'dtoverlay=gpio-shutdown' "${CONFIG}" || echo 'dtoverlay=gpio-shutdown' >> "${CONFIG}"
# Remove any bare ws2812-pio line from an earlier run of this script - with
# no params it claims GPIO4 for a phantom 60-LED strip. Add it back with
# real gpio=/leds= params once the NeoPixel wiring is finalized.
sed -i '/^dtoverlay=ws2812-pio$/d' "${CONFIG}"

echo ""
echo "All style updates applied. Reboot to see the splash/wallpaper/overlays; open a new terminal or SSH session for the prompt/MOTD."
