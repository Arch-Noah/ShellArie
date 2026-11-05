# Panneau Bluetooth Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (inline) or superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Panneau Bluetooth intégré sous la barre (Connecté, Appairés, Découverte, Réglages), dans le style du panneau Wi-Fi.

**Architecture:** Composants communs extraits dans `components/panel/`, `modules/bluetooth/` calqué sur `modules/wifi/`, branché via `ScreenState.bluetooth`. Données via `Quickshell.Bluetooth`.

**Tech Stack:** Quickshell (QML), `Quickshell.Bluetooth`, composants `qs.components.panel`.

**Spec:** `docs/superpowers/specs/2026-11-05-bluetooth-panel-design.md`

## Global Constraints
- Dimensions : 340 px de large, 480 px de haut maximum ; polices compactes (`PanelText`, `PanelIcon`).
- Un seul panneau ouvert à la fois parmi dashboard, wifi, bluetooth.
- Aucune action sur le matériel de l'utilisateur pendant les vérifications (pas de connexion, déconnexion, oubli, appairage).
- Textes via `qsTr(...)`, commits et commentaires en français.

## Review Focus
- Adaptateur éteint ou absent : message, aucune liste, aucun scan.
- Quitter la vue Découverte ou fermer le panneau arrête le scan.
- Appareil sans nom (adresse brute) : affiché en bas de la découverte, en gris.
- Échec d'appairage : message sur la ligne, la ligne reste utilisable.
- Oublier un appareil connecté : confirmation puis disparition de la vue Connecté.
- Le Wi-Fi fonctionne comme avant l'extraction des composants.

## Vérification
`$SCRATCH/check.sh` (smoke : aucune erreur QML), puis relancer l'instance (`pkill -x qs` puis `QT_NO_XDG_DESKTOP_PORTAL=1 qs -d -p …/shell.qml`), `qs -p shell.qml ipc call <cible> toggle` et `grim` pour les captures. Quickshell perd parfois le suivi des fichiers : relancer l'instance plutôt que d'attendre un rechargement.

---

### Task 1: Extraire les composants communs (Wi-Fi inchangé)
**Files:** déplacer `modules/wifi/{WifiText,WifiIcon,CompactSwitch,WifiCard,WifiDivider,WifiButton,WifiField,WifiTabs,InfoRow}.qml` vers `components/panel/` avec les noms `Panel*` ; créer `components/panel/PanelWrapper.qml` ; modifier tous les fichiers de `modules/wifi/`.
**Interfaces — Produces:** `PanelText{size,weight}`, `PanelIcon{size}`, `PanelSwitch{checked,toggled}`, `PanelCard`, `PanelDivider`, `PanelButton{text,icon,tint,onTint,filled,disabled,textSize,clicked}`, `PanelField{text,placeholderText,echoMode,icon,accepted,focusField()}`, `PanelTabs{currentIndex,icons}`, `PanelInfoRow{icon,label,value,copyText}`, `PanelWrapper{shouldBeActive: bool, contentComponent: Component}`.
- [ ] `git mv` + renommage des types dans tous les fichiers de `modules/wifi/` (mots entiers) ; ajouter `import qs.components.panel` aux fichiers de `modules/wifi/`.
- [ ] `PanelWrapper` : enveloppe de `modules/wifi/Wrapper.qml` avec `shouldBeActive` et `contentComponent` ; `modules/wifi/Wrapper.qml` ne garde que `screenState`, `shouldBeActive: screenState?.wifi ?? false` et `contentComponent: Component { Content { screenState: wrapper.screenState } }`.
- [ ] Vérifier : smoke propre ; ouvrir le Wi-Fi et capturer les vues Connecté et Disponibles (rendu identique à avant). Commit.

### Task 2: Squelette Bluetooth, branchement, en-tête
**Files:** créer `modules/bluetooth/{Wrapper,Content,deviceIcon.js}` ; modifier `components/ScreenState.qml`, `bar/BarWindow.qml`, `bar/components/Utilities.qml`, `shell.qml`.
**Interfaces — Produces:** `ScreenState.bluetooth`, IPC `bluetooth.toggle()`, `Content` avec `currentTab` (0 Connecté, 1 Appairés, 2 Découverte, 3 Réglages), `tabIcons`, Loader de vues ; `deviceIcon.js` : `deviceIcon(icon: string): string`.
- [ ] `ScreenState` : drapeau et exclusion mutuelle à trois.
- [ ] `Content` : en-tête (titre, interrupteur `adapter.enabled`), `PanelTabs` (icônes `bluetooth_connected`, `devices`, `bluetooth_searching`, `tune`), flèches, Échap, Loader de vues (vues vides provisoires), états sans adaptateur / éteint.
- [ ] `BarWindow` : `Bt.Wrapper`, hauteur, masque, focus grab, barre des tâches pour trois panneaux ; `Utilities` : bouton → `screenState.bluetooth` ; `shell.qml` : IPC.
- [ ] Vérifier : smoke, `ipc call bluetooth toggle` ouvre/ferme, ouvrir le dashboard ou le Wi-Fi ferme le Bluetooth. Commit.

### Task 3: Vue Connecté
**Files:** `modules/bluetooth/ConnectedView.qml`.
- [ ] Une carte par appareil connecté (hero + pastilles + `PanelInfoRow` adresse/appairé/confiance + bouton « Se déconnecter » → `device.disconnect()`), message vide « Aucun appareil connecté ». Vérifier à l'écran, commit.

### Task 4: Vue Appairés
**Files:** `PairedView.qml`, `PairedRow.qml`.
- [ ] Liste stable des `paired`, connectés d'abord ; `PairedRow` : clic connecte/déconnecte (état « Connexion… »), `PanelSwitch` confiance, corbeille + confirmation → `forget()`. Vérifier l'affichage, commit.

### Task 5: Vue Découverte
**Files:** `DiscoveryView.qml`, `DiscoveryRow.qml`.
- [ ] Scan à la création/destruction ; liste des non appairés (nommés d'abord, adresses brutes en gris) ; clic → `pair()` ; `onPairedChanged` → confiance + `connect()` ; erreur si `pairing` retombe sans `paired`. Vérifier l'affichage (sans appairer), commit.

### Task 6: Vue Réglages et finitions
**Files:** `SettingsView.qml`, `README.md`.
- [ ] Nom, interrupteurs Visible/Appairable, nombre d'appareils appairés. README : panneau et commande IPC. Relire le Review Focus, vérifier le Wi-Fi, commit.
