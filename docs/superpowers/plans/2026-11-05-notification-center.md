# Centre de notifications Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans (inline). **Spec :** `docs/superpowers/specs/2026-11-05-notification-center-design.md`

## Global Constraints
Colonne de 380 px, marges 55/20/20 ; composants `qs.components.panel` ; fermeture par clic extérieur, Échap ou cloche ; textes en `qsTr` ; ne pas effacer les notifications de l'utilisateur pendant les tests.

## Review Focus
- Liste vide : état vide, pas de bouton « Tout effacer ».
- Corps très long : 3 lignes puis dépliable, la carte reste dans la largeur.
- Notification sans image : icône de repli.
- Clic sur la cloche alors que le centre est ouvert : il se ferme (pas de réouverture immédiate).
- Notifications arrivant pendant que le centre est ouvert : elles apparaissent dans la liste, sans popup.

### Task 1: Fenêtre, drapeau, IPC, cloche
`ScreenState`, `ShellState`, `NotifCenterWindow`, `shell.qml`, `Utilities`, masquage des popups. Vérifier : smoke, `ipc call notifcenter toggle`.
### Task 2: Contenu et cartes
`NotifCenterContent`, `NotifCard`. Vérifier avec `notify-send` (courte, longue, avec action).
### Task 3: Finitions
README, relecture du Review Focus.
