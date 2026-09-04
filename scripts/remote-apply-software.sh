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

echo "== Standalone emulators =="
for pkg in ppsspp flycast dolphin-emu mgba-qt; do
  install_pkg "${pkg}"
done

echo "== Extra security toolkit =="
for pkg in kismet john; do
  install_pkg "${pkg}"
done

echo "== Productivity =="
for pkg in calibre pass syncthing gparted; do
  install_pkg "${pkg}"
done
# kiwix (offline Wikipedia/Gutenberg reader) - package name varies by
# release; try the desktop app first, fall back to the CLI server tool.
if ! dpkg -s kiwix >/dev/null 2>&1 && ! dpkg -s kiwix-tools >/dev/null 2>&1; then
  install_pkg kiwix
  dpkg -s kiwix >/dev/null 2>&1 || install_pkg kiwix-tools
else
  echo "  [already installed] kiwix"
fi

echo "== VS Code =="
if ! command -v code >/dev/null 2>&1; then
  curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/microsoft.gpg
  echo "deb [arch=arm64,armhf,amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list
  apt-get update -qq
  install_pkg code
else
  echo "  [already installed] code"
fi

echo "== Obsidian =="
if ! command -v obsidian >/dev/null 2>&1; then
  OBS_URL="$(curl -fsSL https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest \
    | grep -o 'https://[^"]*arm64\.deb' | head -n1)"
  if [ -n "${OBS_URL}" ]; then
    curl -fsSL -o /tmp/obsidian.deb "${OBS_URL}"
    DEBIAN_FRONTEND=noninteractive apt-get install -y /tmp/obsidian.deb >/tmp/install-obsidian.log 2>&1 \
      && echo "  [OK] obsidian" \
      || echo "  [SKIPPED - obsidian .deb failed to install, see /tmp/install-obsidian.log]"
  else
    echo "  [SKIPPED - couldn't find an arm64 .deb release for Obsidian]"
  fi
else
  echo "  [already installed] obsidian"
fi

echo "== Portainer (Docker container GUI) =="
if command -v docker >/dev/null 2>&1; then
  if ! docker ps -a --format '{{.Names}}' 2>/dev/null | grep -qx portainer; then
    docker volume create portainer_data >/dev/null 2>&1
    if docker run -d -p 9000:9000 --name portainer --restart=always \
      -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data \
      portainer/portainer-ce:latest >/tmp/install-portainer.log 2>&1; then
      echo "  [OK] portainer - visit http://ashdeck.local:9000 once it starts"
    else
      echo "  [SKIPPED - portainer container failed, see /tmp/install-portainer.log]"
    fi
  else
    echo "  [already installed] portainer"
  fi
else
  echo "  [SKIPPED - docker not installed]"
fi

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
  command -v unzip >/dev/null 2>&1 || DEBIAN_FRONTEND=noninteractive apt-get install -y unzip >/dev/null 2>&1
  BC_URL="$(curl -fsSL https://api.github.com/repos/bettercap/bettercap/releases/latest \
    | grep -o 'https://[^"]*linux_arm64[^"]*\.zip' | head -n1)"
  if [ -n "${BC_URL}" ]; then
    curl -fsSL -o /tmp/bettercap.zip "${BC_URL}"
    mkdir -p /tmp/bettercap-extract
    unzip -o -q /tmp/bettercap.zip -d /tmp/bettercap-extract
    if [ -f /tmp/bettercap-extract/bettercap ]; then
      install -m 755 /tmp/bettercap-extract/bettercap /usr/local/bin/bettercap
      echo "  [OK] bettercap"
    else
      echo "  [SKIPPED - downloaded archive didn't contain a bettercap binary]"
    fi
  else
    echo "  [SKIPPED - couldn't find an arm64 release asset for bettercap]"
  fi
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
command -v ppsspp >/dev/null 2>&1 && make_shortcut "PPSSPP" "ppsspp" "ppsspp" "false"
command -v flycast >/dev/null 2>&1 && make_shortcut "Flycast" "flycast" "flycast" "false"
command -v dolphin-emu >/dev/null 2>&1 && make_shortcut "Dolphin" "dolphin-emu" "dolphin-emu" "false"
command -v mgba-qt >/dev/null 2>&1 && make_shortcut "mGBA" "mgba-qt" "io.mgba.mGBA" "false"
command -v kismet >/dev/null 2>&1 && make_shortcut "Kismet" "kismet" "utilities-terminal" "true"
command -v code >/dev/null 2>&1 && make_shortcut "VSCode" "code" "code" "false"
command -v obsidian >/dev/null 2>&1 && make_shortcut "Obsidian" "obsidian" "obsidian" "false"
command -v kiwix >/dev/null 2>&1 && make_shortcut "Kiwix" "kiwix" "kiwix" "false"
command -v gparted >/dev/null 2>&1 && make_shortcut "GParted" "gparted" "gparted" "false"

echo ""
echo "Done. Log out and back in (or reboot) for group changes (docker/wireshark)"
echo "and shell aliases to take effect. Check the per-package lines above for"
echo "anything marked SKIPPED."
