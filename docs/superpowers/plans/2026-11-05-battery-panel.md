# Panneau Batterie Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans (inline). **Spec :** `docs/superpowers/specs/2026-11-05-battery-panel-design.md`

## Global Constraints
340 px de large ; `PanelWrapper` ; un seul panneau de la barre ouvert à la fois ; aucune déconnexion lancée pendant les tests ; textes en `qsTr`.

## Review Focus
- Pas de batterie (`displayDevice` nul ou absent) : message, pas d'erreur.
- Charge / décharge / pleine : texte et couleur justes ; pourcentage 0 et 100 : anneau vide / complet.
- Un clic sur le bouton de déconnexion ne déconnecte pas sans confirmation.
- Uptime supérieur à 99 heures : la tuile reste lisible.

### Task 1: Branchement
`ScreenState.closeOthers`, `BarWindow`, `BatteryWidget`, `Utilities`, `shell.qml`, `Wrapper`. Vérifier : smoke, IPC.
### Task 2: Contenu
`Content.qml` : tuiles, déconnexion, jauge. Vérifier à l'écran.
### Task 3: Finitions
README, relecture du Review Focus.
