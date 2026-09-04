#!/usr/bin/env bash
# Runs ON the Pi (as root) to install a macOS Big Sur-style GTK theme and
# icon set (WhiteSur, by vinceliuice - widely used, actively maintained).
# Not meant to be run directly on your computer - see
# scripts/deploy-macos-theme.sh for that.
#
# This covers the confirmed-safe pieces: GTK widget theme + icon theme.
# The dock and window-decoration pieces are handled separately once
# verified compatible with labwc.

set -uo pipefail

PI_USER=asherverlee
PI_HOME="/home/${PI_USER}"

echo "== Prerequisites =="
command -v git >/dev/null 2>&1 || DEBIAN_FRONTEND=noninteractive apt-get install -y git >/dev/null 2>&1

echo "== WhiteSur GTK theme =="
if [ ! -d /usr/share/themes/WhiteSur-Dark ]; then
  rm -rf /tmp/WhiteSur-gtk-theme
  git clone --depth 1 https://github.com/vinceliuice/WhiteSur-gtk-theme.git /tmp/WhiteSur-gtk-theme
  if [ -x /tmp/WhiteSur-gtk-theme/install.sh ]; then
    (cd /tmp/WhiteSur-gtk-theme && ./install.sh -d /usr/share/themes) \
      && echo "  [OK] WhiteSur GTK theme" \
      || echo "  [SKIPPED - WhiteSur GTK theme install.sh failed]"
  else
    echo "  [SKIPPED - install.sh not found in WhiteSur-gtk-theme repo]"
  fi
else
  echo "  [already installed] WhiteSur GTK theme"
fi

echo "== WhiteSur icon theme =="
if [ ! -d /usr/share/icons/WhiteSur ]; then
  rm -rf /tmp/WhiteSur-icon-theme
  git clone --depth 1 https://github.com/vinceliuice/WhiteSur-icon-theme.git /tmp/WhiteSur-icon-theme
  if [ -x /tmp/WhiteSur-icon-theme/install.sh ]; then
    (cd /tmp/WhiteSur-icon-theme && ./install.sh -d /usr/share/icons) \
      && echo "  [OK] WhiteSur icon theme" \
      || echo "  [SKIPPED - WhiteSur icon theme install.sh failed]"
  else
    echo "  [SKIPPED - install.sh not found in WhiteSur-icon-theme repo]"
  fi
else
  echo "  [already installed] WhiteSur icon theme"
fi

echo "== Applying theme =="
GTK_CONF="${PI_HOME}/.config/gtk-3.0/settings.ini"
install -o "${PI_USER}" -g "${PI_USER}" -m 755 -d "${PI_HOME}/.config/gtk-3.0"
if [ ! -f "${GTK_CONF}" ]; then
  printf '%s\n' '[Settings]' > "${GTK_CONF}"
fi

set_gtk_setting() {
  local key="$1" value="$2"
  if grep -q "^${key}=" "${GTK_CONF}"; then
    sed -i "s|^${key}=.*|${key}=${value}|" "${GTK_CONF}"
  else
    sed -i "/^\[Settings\]/a ${key}=${value}" "${GTK_CONF}"
  fi
}

if [ -d /usr/share/themes/WhiteSur-Dark ]; then
  set_gtk_setting "gtk-theme-name" "WhiteSur-Dark"
fi
if [ -d /usr/share/icons/WhiteSur ]; then
  set_gtk_setting "gtk-icon-theme-name" "WhiteSur"
fi
chown "${PI_USER}:${PI_USER}" "${GTK_CONF}"

echo ""
echo "Done. Log out and back in (or reboot) to see the new theme/icons applied."
