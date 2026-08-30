#!/usr/bin/env bash
# Runs ON the Pi (as root) to install the AV Cyberdeck software bundle:
# Vivaldi, terminal quality-of-life tools, a security/networking toolkit,
# media/fun tools, and Docker. Not meant to be run directly on your
# computer - see scripts/deploy-software.sh for that.
#
# Each package installs independently with its own pass/fail line, so one
# unavailable/renamed package can't take down the whole run.

set -uo pipefail

PI_USER=asherverlee
PI_HOME="/home/${PI_USER}"

echo "== Updating package lists =="
apt-get update -qq

install_pkg() {
  local pkg="$1"
  if dpkg -s "${pkg}" >/dev/null 2>&1; then
    echo "  [already installed] ${pkg}"
    return 0
  fi
  if DEBIAN_FRONTEND=noninteractive apt-get install -y "${pkg}" >/tmp/install-"${pkg}".log 2>&1; then
    echo "  [OK] ${pkg}"
  else
    echo "  [SKIPPED - not available or failed, see /tmp/install-${pkg}.log] ${pkg}"
  fi
}

echo "== Terminal quality-of-life =="
for pkg in btop tmux fzf ripgrep bat eza ranger neofetch fastfetch; do
  install_pkg "${pkg}"
done

echo "== Security / networking toolkit =="
# wireshark's installer asks an interactive question about letting non-root
# users capture packets - preseed it so this doesn't hang the script.
echo "wireshark-common wireshark-common/install-setuid boolean true" | debconf-set-selections
for pkg in nmap wireshark tshark aircrack-ng netcat-openbsd tcpdump ettercap-graphical hydra sqlmap nikto hcxtools hcxdumptool netdiscover; do
  install_pkg "${pkg}"
done
if dpkg -s wireshark >/dev/null 2>&1; then
  usermod -aG wireshark "${PI_USER}"
fi

echo "== Media & fun =="
for pkg in vlc cmatrix hollywood figlet lolcat retroarch; do
  install_pkg "${pkg}"
done

echo "== Productivity =="
install_pkg calibre

echo "== Docker =="
if ! command -v docker >/dev/null 2>&1; then
  curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
  sh /tmp/get-docker.sh
  usermod -aG docker "${PI_USER}"
  echo "  [OK] docker installed, ${PI_USER} added to docker group (log out/in to take effect)"
else
  echo "  [already installed] docker"
fi

echo "== Vivaldi =="
if ! command -v vivaldi-stable >/dev/null 2>&1; then
  curl -fsSL https://repo.vivaldi.com/archive/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/vivaldi-browser.gpg
  echo "deb [signed-by=/usr/share/keyrings/vivaldi-browser.gpg] https://repo.vivaldi.com/archive/deb/ stable main" > /etc/apt/sources.list.d/vivaldi.list
  apt-get update -qq
  install_pkg vivaldi-stable
else
  echo "  [already installed] vivaldi"
fi

echo "== Bettercap =="
if ! command -v bettercap >/dev/null 2>&1; then
  curl -fsSL https://raw.githubusercontent.com/bettercap/bettercap/master/install.sh | bash \
    && echo "  [OK] bettercap" \
    || echo "  [SKIPPED - bettercap installer failed]"
else
  echo "  [already installed] bettercap"
fi

echo "== Shell niceties =="
if command -v batcat >/dev/null 2>&1 && ! grep -q "alias bat=" "${PI_HOME}/.bashrc" 2>/dev/null; then
  echo "alias bat=batcat" >> "${PI_HOME}/.bashrc"
fi
if command -v eza >/dev/null 2>&1 && ! grep -q "alias ls=" "${PI_HOME}/.bashrc" 2>/dev/null; then
  echo "alias ls='eza --icons'" >> "${PI_HOME}/.bashrc"
fi
chown "${PI_USER}:${PI_USER}" "${PI_HOME}/.bashrc"

echo "== Desktop shortcuts =="
install -o "${PI_USER}" -g "${PI_USER}" -m 755 -d "${PI_HOME}/Desktop"

make_shortcut() {
  local name="$1" exec_cmd="$2" icon="$3" in_terminal="$4"
  local file="${PI_HOME}/Desktop/${name}.desktop"
  printf '%s\n' \
    "[Desktop Entry]" \
    "Type=Application" \
    "Name=${name}" \
    "Exec=${exec_cmd}" \
    "Icon=${icon}" \
    "Terminal=${in_terminal}" \
    > "${file}"
  chmod +x "${file}"
  chown "${PI_USER}:${PI_USER}" "${file}"
  echo "  [shortcut] ${name}"
}

command -v vivaldi-stable >/dev/null 2>&1 && make_shortcut "Vivaldi" "vivaldi-stable" "vivaldi" "false"
command -v wireshark >/dev/null 2>&1 && make_shortcut "Wireshark" "wireshark" "wireshark" "false"
command -v vlc >/dev/null 2>&1 && make_shortcut "VLC" "vlc" "vlc" "false"
command -v retroarch >/dev/null 2>&1 && make_shortcut "RetroArch" "retroarch" "retroarch" "false"
command -v ettercap >/dev/null 2>&1 && make_shortcut "Ettercap" "ettercap -G" "ettercap" "false"
command -v cmatrix >/dev/null 2>&1 && make_shortcut "Matrix" "cmatrix" "utilities-terminal" "true"
command -v hollywood >/dev/null 2>&1 && make_shortcut "Hollywood" "hollywood" "utilities-terminal" "true"

echo ""
echo "Done. Log out and back in (or reboot) for group changes (docker/wireshark)"
echo "and shell aliases to take effect. Check the per-package lines above for"
echo "anything marked SKIPPED."
