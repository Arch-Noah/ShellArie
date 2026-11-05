# Panneau Son Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans (inline).

**Goal:** Panneau Son (Sortie, Entrée) sous la barre. **Spec :** `docs/superpowers/specs/2026-11-05-sound-panel-design.md`

## Global Constraints
340 px de large, 480 px de haut maximum, composants `qs.components.panel` ; un seul panneau ouvert à la fois ; ne pas modifier le volume, la sourdine ni le périphérique de l'utilisateur pendant les tests ; textes en `qsTr`.

## Review Focus
- Aucun périphérique de sortie ou d'entrée : message vide.
- Volume au-delà de 100 % (plafond `maxVolume`) : le curseur et le pourcentage le gèrent.
- Périphérique par défaut qui change pendant que le panneau est ouvert : coche et carte suivent.
- Le curseur n'écrase pas la valeur pendant le glissement.

### Task 1: Squelette, branchement
Créer `modules/sound/{Wrapper,Content}.qml` ; modifier `ScreenState`, `BarWindow`, `VolumeWidget`, `Utilities`, `shell.qml`. Vérifier : smoke, `ipc call sound toggle`, exclusion mutuelle.
### Task 2: Vue de périphériques
Créer `DeviceView.qml`, `DeviceRow.qml`. Vérifier à l'écran (Sortie et Entrée).
### Task 3: Finitions
README, relecture du Review Focus, vérifier Wi-Fi et Bluetooth.
