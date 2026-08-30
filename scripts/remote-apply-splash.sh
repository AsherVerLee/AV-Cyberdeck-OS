#!/usr/bin/env bash
# Runs ON the Pi (as root) to fetch and apply the latest AV Cyberdeck style:
# boot splash, MOTD, shell prompt, wallpaper, and dark theme preference.
# Not meant to be run directly on your computer - see scripts/deploy-splash.sh.

set -euo pipefail

PI_USER=asherverlee
PI_HOME="/home/${PI_USER}"
THEME_DIR=/usr/share/plymouth/themes/av-cyberdeck
REPO_RAW="https://raw.githubusercontent.com/AsherVerLee/AV-Cyberdeck-OS/main"
# raw.githubusercontent.com caches responses for a few minutes; append a
# cache-busting query param to every fetch so a just-pushed file is never
# served stale.
CB="cb=$(date +%s)"

echo "== Boot splash =="
mkdir -p "${THEME_DIR}"
curl -fsSL -o "${THEME_DIR}/av-cyberdeck.plymouth" "${REPO_RAW}/plymouth-theme/av-cyberdeck.plymouth?${CB}"
curl -fsSL -o "${THEME_DIR}/av-cyberdeck.script" "${REPO_RAW}/plymouth-theme/av-cyberdeck.script?${CB}"
curl -fsSL -o "${THEME_DIR}/av-logo.png" "${REPO_RAW}/assets/av-logo.png?${CB}"
plymouth-set-default-theme -R av-cyberdeck
echo "Active theme: $(grep -m1 '^Theme=' /etc/plymouth/plymouthd.conf || echo unknown)"

echo "== MOTD =="
curl -fsSL -o /etc/update-motd.d/10-av-cyberdeck "${REPO_RAW}/motd/10-av-cyberdeck?${CB}"
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
LOGIN_WALLPAPER_PATH=/usr/share/av-cyberdeck/wallpaper-login.png
install -d -m 755 /usr/share/av-cyberdeck
curl -fsSL -o "${WALLPAPER_PATH}" "${REPO_RAW}/assets/wallpaper.png?${CB}"
curl -fsSL -o "${LOGIN_WALLPAPER_PATH}" "${REPO_RAW}/assets/wallpaper-login.png?${CB}"
chmod 644 "${WALLPAPER_PATH}" "${LOGIN_WALLPAPER_PATH}"

# Also drop a copy in Pictures so it can be picked manually via
# Desktop Preferences > Wallpaper > Browse, instead of relying on the
# pcmanfm config automation below.
install -o "${PI_USER}" -g "${PI_USER}" -m 755 -d "${PI_HOME}/Pictures"
cp "${WALLPAPER_PATH}" "${PI_HOME}/Pictures/av-cyberdeck-wallpaper.png"
chown "${PI_USER}:${PI_USER}" "${PI_HOME}/Pictures/av-cyberdeck-wallpaper.png"

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
# Merge into the existing file rather than overwriting it - a blind
# overwrite here previously wiped out this OS's own gtk-icon-theme-name
# (PiXtrix), leaving desktop icons like Trash with no image.
GTK_CONF="${PI_HOME}/.config/gtk-3.0/settings.ini"
install -o "${PI_USER}" -g "${PI_USER}" -m 755 -d "${PI_HOME}/.config/gtk-3.0"
if [ ! -f "${GTK_CONF}" ]; then
  printf '%s\n' '[Settings]' > "${GTK_CONF}"
fi
grep -q '^gtk-application-prefer-dark-theme=' "${GTK_CONF}" \
  && sed -i 's|^gtk-application-prefer-dark-theme=.*|gtk-application-prefer-dark-theme=1|' "${GTK_CONF}" \
  || sed -i '/^\[Settings\]/a gtk-application-prefer-dark-theme=1' "${GTK_CONF}"
if ! grep -q '^gtk-icon-theme-name=' "${GTK_CONF}"; then
  sed -i '/^\[Settings\]/a gtk-icon-theme-name=PiXtrix' "${GTK_CONF}"
fi
chown "${PI_USER}:${PI_USER}" "${GTK_CONF}"

echo "== On-screen keyboard =="
# squeekboard (system autostart at /etc/xdg/autostart/squeekboard.desktop)
# was getting stuck showing a blank surface instead of hiding itself.
# Since a physical keyboard is planned for this build, disable it per-user
# via the standard XDG override rather than fighting its behavior.
pkill squeekboard >/dev/null 2>&1 || true
install -o "${PI_USER}" -g "${PI_USER}" -m 755 -d "${PI_HOME}/.config/autostart"
printf '%s\n' '[Desktop Entry]' 'Hidden=true' > "${PI_HOME}/.config/autostart/squeekboard.desktop"
chown "${PI_USER}:${PI_USER}" "${PI_HOME}/.config/autostart/squeekboard.desktop"

echo "== Login screen =="
AVATAR_PATH=/usr/share/av-cyberdeck/avatar-square.png
curl -fsSL -o "${AVATAR_PATH}" "${REPO_RAW}/assets/avatar-square.png?${CB}"
chmod 644 "${AVATAR_PATH}"

GREETER_CONF=/etc/lightdm/pi-greeter.conf
set_greeter_option() {
  local key="$1" value="$2"
  if grep -q "^${key}=" "${GREETER_CONF}"; then
    sed -i "s|^${key}=.*|${key}=${value}|" "${GREETER_CONF}"
  elif grep -q "^#${key}=" "${GREETER_CONF}"; then
    sed -i "s|^#${key}=.*|${key}=${value}|" "${GREETER_CONF}"
  else
    sed -i "/^\[greeter\]/a ${key}=${value}" "${GREETER_CONF}"
  fi
}
set_greeter_option "background" "${LOGIN_WALLPAPER_PATH}"
# This Pi-customized greeter build actually reads wallpaper=/wallpaper_mode=
# (a desktop-style background system) rather than the standard background=
# key above - set both so it works regardless of which one this build honors.
set_greeter_option "wallpaper" "${LOGIN_WALLPAPER_PATH}"
set_greeter_option "wallpaper_mode" "crop"
set_greeter_option "default-user-image" "${AVATAR_PATH}"
set_greeter_option "round-user-image" "true"
set_greeter_option "indicators" "~host;~spacer;~clock;~spacer;~session;~power"
set_greeter_option "clock-format" "%H:%M"

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
