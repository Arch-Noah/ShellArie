# Centre de notifications (panneau détaché) — spec de design

Date : 2026-11-05

## Objectif

Un centre de notifications sous forme de **colonne flottante à droite, pleine hauteur**, détachée de la barre, avec le style des panneaux Wi-Fi / Bluetooth / Son.

## Périmètre

**Inclus** : fenêtre flottante par écran ; en-tête (titre, nombre, « Ne pas déranger », « Tout effacer ») ; liste des notifications ; cloche avec badge dans la barre ; commande IPC `notifcenter toggle` ; masquage des popups pendant que le centre est ouvert.

**Exclus** : regroupement par application, historique au-delà de `Notifs`, réglages par application. L'ancien `modules/notification/NotificationCenter.qml` (dépendant de l'ancien shell) n'est pas touché.

## Données

`services/Notifs.qml` : `notClosed` (liste de `NotifData`), `dnd` (lecture/écriture). `NotifData` : `summary`, `body`, `appName`, `image`, `timeStr`, `urgency`, `actions` (`identifier`, `text`, `invoke()`), `close()`. Effacer tout = `close()` sur chaque notification (comme l'IPC `notifs clear`).

## Architecture

| Fichier | Rôle |
|---|---|
| `modules/notifcenter/NotifCenterWindow.qml` | `Variants` sur les écrans ; un `PanelWindow` Overlay ancré haut/bas/droite (marges 55 px en haut, 20 px à droite et en bas), 380 px de large, fond arrondi ; glisse depuis la droite avec un fondu ; `HyprlandFocusGrab` : un clic en dehors ferme |
| `modules/notifcenter/NotifCenterContent.qml` | en-tête fixe, liste défilante, état vide (`PanelEmpty`), Échap ferme |
| `modules/notifcenter/NotifCard.qml` | une notification : pastille (image ou icône), application, heure, titre, corps (3 lignes, un clic déplie), actions, croix |
- `components/ScreenState.qml` : `notifCenter` (bool) et `notifCenterClosedAt` (real). Pas d'exclusion avec les panneaux de la barre.
- `services/ShellState.qml` : `anyNotifCenterOpen()`.
- `bar/components/Utilities.qml` : cloche (icône cloche / cloche barrée si `dnd`, label = nombre) en tête du groupe ; un clic bascule `notifCenter` (ignoré si fermé depuis moins de 300 ms : le clic sur la cloche vide d'abord le focus grab).
- `shell.qml` : `NotifCenterWindow` et `IpcHandler` cible `notifcenter`.
- `modules/notification/NotificationPopups.qml` : masqués quand `ShellState.anyNotifCenterOpen()`.
- `README.md`.

## Comportement

- Fermeture : clic en dehors, Échap, ou nouveau clic sur la cloche.
- Liste : plus récente en haut ; carte critique teintée en rouge ; fermer une carte = `close()`.
- « Tout effacer » visible seulement s'il y a des notifications.
- Vide : « Aucune notification ».

## Vérification

Smoke et captures avec des `notify-send` de test. Je n'efface pas les notifications de l'utilisateur : « Tout effacer » et les croix restent à tester par lui.
