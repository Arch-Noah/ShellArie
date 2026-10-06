#!/usr/bin/env bash
# Installation de ShellArie (Arch Linux + Hyprland >= 0.56)
#
# Usage : ./install.sh [--check] [--yes]
#   --check   vérifie seulement les dépendances, n'installe ni ne modifie rien
#   --yes     répond oui aux questions (installation des paquets manquants)

set -uo pipefail

CHECK_ONLY=0
ASSUME_YES=0
for arg in "$@"; do
    case "$arg" in
        --check) CHECK_ONLY=1 ;;
        --yes|-y) ASSUME_YES=1 ;;
        -h|--help) sed -n '2,7p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "Option inconnue : $arg" >&2; exit 1 ;;
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
    read -r -p "$1 [o/N] " reply
    [[ "$reply" =~ ^[oOyY]$ ]]
}

# Paquets des dépôts officiels : paquet|rôle
REQUIRED_PKGS=(
    "networkmanager|Wi-Fi / Ethernet / VPN (nmcli)"
    "bluez|Bluetooth"
    "bluez-utils|Bluetooth"
    "inotify-tools|surveillance de fichiers (inotifywait)"
    "openbsd-netcat|connexion au démon metricd (nc -U)"
    "wireplumber|volume (wpctl)"
    "libpulse|volume (pactl)"
    "brightnessctl|luminosité"
    "upower|batterie"
    "power-profiles-daemon|profils d'énergie"
    "rofi|lanceur d'applications"
    "ttf-jetbrains-mono-nerd|icônes des workspaces"
)
OPTIONAL_PKGS=(
    "ddcutil|luminosité des écrans externes"
    "tailscale|widget Tailscale"
    "matugen|génération du thème de couleurs"
    "cava|visualiseur audio"
    "libqalculate|calculs dans le lanceur"
    "grim|captures d'écran"
)

# ---------------------------------------------------------------- système
step "Système"
if ! command -v pacman >/dev/null; then
    bad "pacman introuvable : ce script cible Arch Linux. Installez les dépendances du README à la main."
    exit 1
fi
ok "Arch Linux détecté"

if command -v hyprctl >/dev/null; then
    ver="$(hyprctl version 2>/dev/null | grep -oE 'v?[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
    ok "Hyprland ${ver:-?}"
    if [[ -n "$ver" ]] && [[ "$(printf '%s\n0.56.0\n' "${ver#v}" | sort -V | head -1)" != "0.56.0" ]]; then
        warn "Hyprland < 0.56 : les actions de la barre (workspaces, taskbar) utilisent la syntaxe Lua de 0.56+"
    fi
else
    bad "Hyprland introuvable"
fi

# ---------------------------------------------------------------- paquets officiels
step "Paquets (dépôts officiels)"
MISSING=()
for entry in "${REQUIRED_PKGS[@]}"; do
    pkg="${entry%%|*}"; role="${entry#*|}"
    if pacman -Qq "$pkg" >/dev/null 2>&1; then ok "$pkg ($role)"; else bad "$pkg manquant ($role)"; MISSING+=("$pkg"); fi
done
for entry in "${OPTIONAL_PKGS[@]}"; do
    pkg="${entry%%|*}"; role="${entry#*|}"
    if pacman -Qq "$pkg" >/dev/null 2>&1; then ok "$pkg [optionnel] ($role)"; else warn "$pkg absent [optionnel] ($role)"; fi
done

if (( ${#MISSING[@]} )) && (( ! CHECK_ONLY )); then
    echo
    if confirm "Installer les paquets requis manquants (${MISSING[*]}) avec sudo pacman ?"; then
        sudo pacman -S --needed "${MISSING[@]}" || bad "L'installation a échoué"
    fi
fi

# ---------------------------------------------------------------- hors dépôts officiels
step "Composants hors dépôts officiels"
NEED_MANUAL=0

if command -v qs >/dev/null || command -v quickshell >/dev/null; then
    ok "Quickshell ($(pacman -Q quickshell-git quickshell 2>/dev/null | head -1))"
else
    bad "Quickshell absent : AUR « quickshell-git » (ex. yay -S quickshell-git)"; NEED_MANUAL=1
fi

if pacman -Qq ttf-material-symbols-variable-git >/dev/null 2>&1 || fc-list 2>/dev/null | grep -qi "Material Symbols"; then
    ok "Police Material Symbols"
else
    bad "Police Material Symbols absente : AUR « ttf-material-symbols-variable-git »"; NEED_MANUAL=1
fi

if [[ -d /usr/lib/qt6/qml/Caelestia ]]; then
    ok "Module QML Caelestia"
else
    bad "Module QML Caelestia absent (/usr/lib/qt6/qml/Caelestia) : à compiler depuis https://github.com/caelestia-dots/shell (plugin installé dans /usr/lib/qt6/qml)"; NEED_MANUAL=1
fi

if command -v caelestia >/dev/null; then
    ok "CLI caelestia (fonds d'écran, enregistrement, schémas de couleurs)"
else
    warn "CLI caelestia absente [optionnel] : fonctions fond d'écran / enregistrement d'écran indisponibles"
fi

if command -v metricd >/dev/null; then
    if systemctl --user is-active --quiet metricd 2>/dev/null; then
        ok "metricd actif"
    else
        warn "metricd installé mais inactif : systemctl --user enable --now metricd"
    fi
else
    bad "metricd absent (CPU/RAM/disque/débit de la barre) : https://github.com/Arch-Noah/metricd"; NEED_MANUAL=1
fi

# ---------------------------------------------------------------- scripts Hyprland externes
step "Scripts Hyprland externes (optionnels)"
HYPR_SCRIPTS="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/scripts"
for s in qs_manager.sh generate_qs_colors.sh; do
    if [[ -x "$HYPR_SCRIPTS/$s" ]]; then ok "$s"; else warn "$s absent dans $HYPR_SCRIPTS (voir README)"; fi
done

if (( CHECK_ONLY )); then
    echo; echo "Mode --check : rien n'a été modifié."
    exit $(( NEED_MANUAL ))
fi

# ---------------------------------------------------------------- emplacement
step "Installation du projet"
if [[ "$SRC_DIR" == "$TARGET_DIR" ]]; then
    ok "Déjà dans $TARGET_DIR"
else
    if [[ -e "$TARGET_DIR" ]]; then
        warn "$TARGET_DIR existe déjà, rien n'est écrasé"
    elif confirm "Lier $SRC_DIR vers $TARGET_DIR ?"; then
        mkdir -p "$(dirname "$TARGET_DIR")"
        ln -s "$SRC_DIR" "$TARGET_DIR" && ok "Lien créé : $TARGET_DIR -> $SRC_DIR"
    fi
fi

mkdir -p "$STATE_DIR" && ok "Dossier d'état : $STATE_DIR (applications épinglées)"
chmod +x "$SRC_DIR/start.sh"

# ---------------------------------------------------------------- Hyprland
step "Configuration Hyprland"
cat <<EOS
Ajoutez à votre configuration Hyprland (Lua) :

  -- lancement au démarrage
  hl.exec_cmd("$TARGET_DIR/start.sh")

  -- afficher / masquer la seconde barre (icônes des applications)
  hl.bind("SUPER + Tab", hl.dsp.exec_cmd("qs ipc -p $TARGET_DIR/shell.qml call taskbar toggle"))

EOS

step "Terminé"
if (( NEED_MANUAL )); then
    warn "Il reste des composants à installer à la main (voir ci-dessus) avant de lancer le shell."
else
    if confirm "Lancer ShellArie maintenant ?"; then
        nohup "$SRC_DIR/start.sh" >/dev/null 2>&1 &
        ok "ShellArie lancé"
    fi
fi
