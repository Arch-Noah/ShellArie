# ShellArie

Shell [Quickshell](https://quickshell.org) pour **Hyprland** (Arch Linux) : barre principale, dashboard déroulant, notifications et seconde barre d'applications.


![ShellArie sur un fond de forêt](docs/screenshots/screenshot-1.webp)

<p>
  <img src="docs/screenshots/screenshot-2.webp" width="49%" alt="ShellArie, thème sombre monochrome">
  <img src="docs/screenshots/screenshot-3.webp" width="49%" alt="ShellArie, thème chaud">
</p>

La barre principale en haut, et la seconde barre d'applications collée en dessous. Les couleurs suivent le fond d'écran.

## Fonctionnalités

- **Barre principale** : workspaces (clic pour y aller, glisser-déposer de fenêtres), horloge, lecteur média, débit réseau, Wi-Fi / Bluetooth / Ethernet, batterie, volume, luminosité, ressources (CPU / RAM / disque), Tailscale.
- **Dashboard** sous la barre : tableau de bord, média (paroles), performances, météo.
- **Notifications** : popups et centre de notifications avec mode Ne pas déranger.
- **Seconde barre** collée sous la barre principale : icônes des applications ouvertes.
  - clic : va sur le workspace de l'application (la lance si elle est fermée) ;
  - clic droit : épingle / désépingle l'application (conservé après redémarrage) ;
  - affichée avec `SUPER + Tab`, automatiquement quand rofi est ouvert ou quand le workspace actif est vide.

## Prérequis

| Composant | Rôle |
|---|---|
| Hyprland ≥ 0.56 | les actions utilisent la syntaxe Lua (`hl.dsp.*`) |
| `quickshell-git` (AUR) | le shell |
| Module QML **Caelestia** | composants, services et configuration (à compiler depuis [caelestia-dots/shell](https://github.com/caelestia-dots/shell), installé dans `/usr/lib/qt6/qml/Caelestia`) |
| [`metricd`](https://github.com/Arch-Noah/metricd) | démon fournissant CPU / RAM / disque / débit via `$XDG_RUNTIME_DIR/metricd.sock` |
| `networkmanager`, `bluez`, `bluez-utils`, `wireplumber`, `libpulse`, `brightnessctl`, `upower`, `power-profiles-daemon` | réseau, Bluetooth, audio, luminosité, énergie |
| `inotify-tools`, `openbsd-netcat` | surveillance de fichiers, accès au socket metricd |
| `rofi` | lanceur |
| `ttf-jetbrains-mono-nerd`, `ttf-material-symbols-variable-git` | polices d'icônes |

Optionnels : `ddcutil` (écrans externes), `tailscale`, `matugen`, `cava`, `libqalculate`, `grim`, la CLI `caelestia` (fonds d'écran, enregistrement d'écran).

Scripts externes utilisés si présents dans `~/.config/hypr/scripts/` :
- `qs_manager.sh` : panneaux ouverts par un clic sur les widgets réseau, batterie, volume ;
- `generate_qs_colors.sh` : écrit les couleurs du thème dans `/tmp/qs_colors.json`.

## Installation

```bash
git clone <url-du-dépôt> ~/.config/quickshell/ShellArie
cd ~/.config/quickshell/ShellArie
./install.sh --check   # vérifie les dépendances sans rien modifier
./install.sh           # installe les paquets manquants, crée le dossier d'état
```

`install.sh --yes` répond oui à toutes les questions. Le script installe les paquets des dépôts officiels ; Quickshell, le module Caelestia, la police Material Symbols et metricd restent à installer à la main, il vous indique lesquels manquent.

### Configuration Hyprland

Dans votre configuration Lua :

```lua
-- lancement au démarrage
hl.exec_cmd("~/.config/quickshell/ShellArie/start.sh")

-- afficher / masquer la seconde barre
hl.bind("SUPER + Tab", hl.dsp.exec_cmd(
    "qs ipc -p " .. os.getenv("HOME") .. "/.config/quickshell/ShellArie/shell.qml call taskbar toggle"))
```

## Utilisation

`./start.sh` (re)lance le shell, `./start.sh -q` l'arrête. Quickshell recharge les fichiers QML à chaud quand ils changent.

Commandes IPC (`qs ipc -p ~/.config/quickshell/ShellArie/shell.qml call <cible> <fonction>`) :

| Cible | Fonction | Effet |
|---|---|---|
| `taskbar` | `toggle` | affiche / masque la seconde barre |
| `taskbar` | `togglePin <appId>` | épingle / désépingle une application |
| `dashboard` | `toggle`, `showTab <n>` | ouvre le dashboard (sur l'onglet *n*) |

`qs ipc -p … show` liste toutes les cibles disponibles (média, volume, luminosité, notifications…).

### Données et variables d'environnement

| Élément | Emplacement |
|---|---|
| Applications épinglées | `~/.local/state/shellarie/taskbar-pins.json` (`$XDG_STATE_HOME`) |
| Couleurs du thème | `/tmp/qs_colors.json`, modifiable avec `QS_COLORS_FILE` |
| Échelle de l'interface | `uiScale` dans `~/.config/hypr/settings.json` |
| Socket metricd | `$XDG_RUNTIME_DIR/metricd.sock` |

## Structure

```
shell.qml        point d'entrée
bar/             barre principale, seconde barre (Taskbar.qml), widgets
modules/         dashboard, notifications
services/        services (réseau, audio, Hyprland, Metricd, TaskbarPins, VPN…)
components/      composants graphiques réutilisables
utils/           chemins (Paths.qml), icônes, scripts JS
commons/         styles et couleurs
assets/          polices, images
```

## Dépannage

- **Barre vide ou valeurs à 0 (CPU, RAM, débit)** : vérifiez `systemctl --user status metricd`.
- **Les clics sur les workspaces ne font rien** : Hyprland < 0.56. La syntaxe `hyprctl dispatch workspace 2` n'existe plus, les actions passent par `hl.dsp.*`.
- **Icônes remplacées par des lettres** dans la seconde barre : l'application n'a pas d'icône dans votre thème d'icônes.
- **Logs** : `qs log -p ~/.config/quickshell/ShellArie/shell.qml`.
