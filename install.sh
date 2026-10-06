#!/usr/bin/env bash
# ShellArie installer (Arch Linux + Hyprland >= 0.56)
#
# Usage : ./install.sh [--check] [--yes]
#   --check   only check dependencies, install and change nothing
#   --yes     answer yes to every question (installs missing packages)

set -uo pipefail

CHECK_ONLY=0
ASSUME_YES=0
for arg in "$@"; do
    case "$arg" in
        --check) CHECK_ONLY=1 ;;
        --yes|-y) ASSUME_YES=1 ;;
        -h|--help) sed -n '2,7p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "Unknown option: $arg" >&2; exit 1 ;;
    esac
done

SRC_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
TARGET_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/ShellArie"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/shellarie"

if [[ -t 1 ]]; then
    RED=$'\e[31m'; GREEN=$'\e[32m'; YELLOW=$'\e[33m'; BOLD=$'\e[1m'; RESET=$'\e[0m'
else
    RED=; GREEN=; YELLOW=; BOLD=; RESET=
fi
ok()   { echo "  ${GREEN}✔${RESET} $*"; }
warn() { echo "  ${YELLOW}!${RESET} $*"; }
bad()  { echo "  ${RED}✘${RESET} $*"; }
step() { echo; echo "${BOLD}== $* ==${RESET}"; }

confirm() {
    (( ASSUME_YES )) && return 0
    read -r -p "$1 [y/N] " reply
    [[ "$reply" =~ ^[oOyY]$ ]]
}

# Official repository packages: package|purpose
REQUIRED_PKGS=(
    "networkmanager|Wi-Fi / Ethernet / VPN (nmcli)"
    "bluez|Bluetooth"
    "bluez-utils|Bluetooth"
    "inotify-tools|file watching (inotifywait)"
    "openbsd-netcat|metricd daemon connection (nc -U)"
    "wireplumber|volume (wpctl)"
    "libpulse|volume (pactl)"
    "brightnessctl|brightness"
    "upower|battery"
    "power-profiles-daemon|power profiles"
    "rofi|application launcher"
    "ttf-jetbrains-mono-nerd|workspace icons"
)
OPTIONAL_PKGS=(
    "ddcutil|external display brightness"
    "tailscale|Tailscale widget"
    "matugen|color theme generation"
    "cava|audio visualizer"
    "libqalculate|calculator in the launcher"
    "grim|screenshots"
)

# ---------------------------------------------------------------- system
step "System"
if ! command -v pacman >/dev/null; then
    bad "pacman not found: this script targets Arch Linux. Install the dependencies listed in the README by hand."
    exit 1
fi
ok "Arch Linux detected"

if command -v hyprctl >/dev/null; then
    ver="$(hyprctl version 2>/dev/null | grep -oE 'v?[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
    ok "Hyprland ${ver:-?}"
    if [[ -n "$ver" ]] && [[ "$(printf '%s\n0.56.0\n' "${ver#v}" | sort -V | head -1)" != "0.56.0" ]]; then
        warn "Hyprland < 0.56: bar actions (workspaces, application bar) use the Lua syntax of 0.56+"
    fi
else
    bad "Hyprland not found"
fi

# ---------------------------------------------------------------- official packages
step "Packages (official repositories)"
MISSING=()
for entry in "${REQUIRED_PKGS[@]}"; do
    pkg="${entry%%|*}"; role="${entry#*|}"
    if pacman -Qq "$pkg" >/dev/null 2>&1; then ok "$pkg ($role)"; else bad "$pkg missing ($role)"; MISSING+=("$pkg"); fi
done
for entry in "${OPTIONAL_PKGS[@]}"; do
    pkg="${entry%%|*}"; role="${entry#*|}"
    if pacman -Qq "$pkg" >/dev/null 2>&1; then ok "$pkg [optional] ($role)"; else warn "$pkg not installed [optional] ($role)"; fi
done

if (( ${#MISSING[@]} )) && (( ! CHECK_ONLY )); then
    echo
    if confirm "Install the missing required packages (${MISSING[*]}) with sudo pacman?"; then
        sudo pacman -S --needed "${MISSING[@]}" || bad "Installation failed"
    fi
fi

# ---------------------------------------------------------------- outside official repositories
step "Components outside the official repositories"
NEED_MANUAL=0

if command -v qs >/dev/null || command -v quickshell >/dev/null; then
    ok "Quickshell ($(pacman -Q quickshell-git quickshell 2>/dev/null | head -1))"
else
    bad "Quickshell missing: AUR package 'quickshell-git' (e.g. yay -S quickshell-git)"; NEED_MANUAL=1
fi

if pacman -Qq ttf-material-symbols-variable-git >/dev/null 2>&1 || fc-list 2>/dev/null | grep -qi "Material Symbols"; then
    ok "Material Symbols font"
else
    bad "Material Symbols font missing: AUR package 'ttf-material-symbols-variable-git'"; NEED_MANUAL=1
fi

if [[ -d /usr/lib/qt6/qml/Caelestia ]]; then
    ok "Caelestia QML module"
else
    bad "Caelestia QML module missing (/usr/lib/qt6/qml/Caelestia): build it from https://github.com/caelestia-dots/shell (the plugin installs into /usr/lib/qt6/qml)"; NEED_MANUAL=1
fi

if command -v caelestia >/dev/null; then
    ok "caelestia CLI (wallpapers, recording, color schemes)"
else
    warn "caelestia CLI missing [optional]: wallpaper and screen recording features unavailable"
fi

if command -v metricd >/dev/null; then
    if systemctl --user is-active --quiet metricd 2>/dev/null; then
        ok "metricd running"
    else
        warn "metricd installed but not running: systemctl --user enable --now metricd"
    fi
else
    bad "metricd missing (bar CPU/RAM/disk/throughput): https://github.com/Arch-Noah/metricd"; NEED_MANUAL=1
fi

# ---------------------------------------------------------------- external Hyprland scripts
step "External Hyprland scripts (optional)"
HYPR_SCRIPTS="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/scripts"
for s in qs_manager.sh generate_qs_colors.sh; do
    if [[ -x "$HYPR_SCRIPTS/$s" ]]; then ok "$s"; else warn "$s not found in $HYPR_SCRIPTS (see README)"; fi
done

if (( CHECK_ONLY )); then
    echo; echo "--check mode: nothing was modified."
    exit $(( NEED_MANUAL ))
fi

# ---------------------------------------------------------------- location
step "Project installation"
if [[ "$SRC_DIR" == "$TARGET_DIR" ]]; then
    ok "Already in $TARGET_DIR"
else
    if [[ -e "$TARGET_DIR" ]]; then
        warn "$TARGET_DIR already exists, nothing overwritten"
    elif confirm "Link $SRC_DIR to $TARGET_DIR?"; then
        mkdir -p "$(dirname "$TARGET_DIR")"
        ln -s "$SRC_DIR" "$TARGET_DIR" && ok "Link created: $TARGET_DIR -> $SRC_DIR"
    fi
fi

mkdir -p "$STATE_DIR" && ok "State directory: $STATE_DIR (pinned applications)"
chmod +x "$SRC_DIR/start.sh"

# ---------------------------------------------------------------- Hyprland
step "Hyprland configuration"
cat <<EOS
Add this to your Hyprland (Lua) configuration:

  -- start with the session
  hl.exec_cmd("$TARGET_DIR/start.sh")

  -- show / hide the application bar
  hl.bind("SUPER + Tab", hl.dsp.exec_cmd("qs ipc -p $TARGET_DIR/shell.qml call taskbar toggle"))

EOS

step "Done"
if (( NEED_MANUAL )); then
    warn "Some components still have to be installed by hand (see above) before starting the shell."
else
    if confirm "Start ShellArie now?"; then
        nohup "$SRC_DIR/start.sh" >/dev/null 2>&1 &
        ok "ShellArie started"
    fi
fi
