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
# Earlier version of this script used a competing `pcmanfm --set-wallpaper`
# autostart entry that raced against the real desktop-manager pcmanfm
# instance and broke it ("Desktop manager is not active"). Remove that if
# present, and instead write the config file the real instance already
# reads on its own - no second process involved.
rm -f "${PI_HOME}/.config/autostart/av-wallpaper.desktop"
# Also drop the old per-user copy from an earlier run - superseded by the
# shared system-wide copy below, which the greeter's separate system user
# can also read (a home directory may not be traversable by other users).
rm -f "${PI_HOME}/.local/share/av-cyberdeck/wallpaper.png"

WALLPAPER_PATH=/usr/share/av-cyberdeck/wallpaper.png
install -d -m 755 /usr/share/av-cyberdeck
curl -fsSL -o "${WALLPAPER_PATH}" "${REPO_RAW}/assets/wallpaper.png"
chmod 644 "${WALLPAPER_PATH}"

PCMANFM_DIR="${PI_HOME}/.config/pcmanfm/LXDE-pi"
DESKTOP_CONF="${PCMANFM_DIR}/desktop-items-0.conf"
install -o "${PI_USER}" -g "${PI_USER}" -m 755 -d "${PCMANFM_DIR}"
if [ -f "${DESKTOP_CONF}" ]; then
  grep -q '^wallpaper=' "${DESKTOP_CONF}" \
    && sed -i "s|^wallpaper=.*|wallpaper=${WALLPAPER_PATH}|" "${DESKTOP_CONF}" \
    || sed -i "/^\[\*\]/a wallpaper=${WALLPAPER_PATH}" "${DESKTOP_CONF}"
  grep -q '^wallpaper_mode=' "${DESKTOP_CONF}" \
    && sed -i "s|^wallpaper_mode=.*|wallpaper_mode=stretch|" "${DESKTOP_CONF}" \
    || sed -i "/^\[\*\]/a wallpaper_mode=stretch" "${DESKTOP_CONF}"
else
  cat > "${DESKTOP_CONF}" <<CONF
[*]
wallpaper_mode=stretch
wallpaper_common=1
wallpaper=${WALLPAPER_PATH}
CONF
fi
chown "${PI_USER}:${PI_USER}" "${DESKTOP_CONF}"

echo "== Dark theme =="
install -o "${PI_USER}" -g "${PI_USER}" -m 755 -d "${PI_HOME}/.config/gtk-3.0"
cat > "${PI_HOME}/.config/gtk-3.0/settings.ini" <<GTK
[Settings]
gtk-application-prefer-dark-theme=1
GTK
chown "${PI_USER}:${PI_USER}" "${PI_HOME}/.config/gtk-3.0/settings.ini"

echo "== Login screen =="
GREETER_CONF=/etc/lightdm/pi-greeter.conf
if grep -q '^background=' "${GREETER_CONF}"; then
  sed -i "s|^background=.*|background=${WALLPAPER_PATH}|" "${GREETER_CONF}"
else
  sed -i "/^\[greeter\]/a background=${WALLPAPER_PATH}" "${GREETER_CONF}"
fi
raspi-config nonint do_boot_behaviour B3
echo "Autologin disabled (boot_behaviour=B3); greeter background set."
echo "To revert to autologin: sudo raspi-config nonint do_boot_behaviour B4"

echo "== config.txt overlays (power button) =="
CONFIG=/boot/firmware/config.txt
grep -qxF 'dtoverlay=gpio-shutdown' "${CONFIG}" || echo 'dtoverlay=gpio-shutdown' >> "${CONFIG}"
# Remove any bare ws2812-pio line from an earlier run of this script - with
# no params it claims GPIO4 for a phantom 60-LED strip. Add it back with
# real gpio=/leds= params once the NeoPixel wiring is finalized.
sed -i '/^dtoverlay=ws2812-pio$/d' "${CONFIG}"

echo ""
echo "All style updates applied. Reboot to see the splash/wallpaper/overlays; open a new terminal or SSH session for the prompt/MOTD."
