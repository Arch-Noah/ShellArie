# Panneau Batterie — spec de design

Date : 2026-11-05

## Objectif

Remplacer le popup batterie externe (`qs_manager.sh toggle battery`) par un panneau intégré sous la barre, qui reprend la composition du haut de l'ancien popup : tuiles d'uptime, déconnexion, grande jauge circulaire. Pas d'onglets.

## Périmètre

**Inclus** : un seul écran sous la barre (340 px) avec
1. ligne du haut : tuiles d'uptime « HR : MIN » à gauche, bouton de déconnexion à droite ;
2. jauge circulaire (anneau, icône de batterie, pourcentage, état), puis une ligne « autonomie · puissance ».

**Exclus** (demandé) : curseurs luminosité/volume, actions système (verrouiller, veille, redémarrer, éteindre), profils d'énergie. L'ancien fichier n'est pas touché.

## Données

`UPower.displayDevice` (Quickshell.Services.UPower) : `percentage` (0..1), `state`, `timeToEmpty`, `timeToFull` (secondes), `changeRate` (W), `isPresent`. Uptime : `/proc/uptime` lu toutes les 15 s.

## Architecture

- `modules/battery/Wrapper.qml` : `PanelWrapper` sur `ScreenState.battery`.
- `modules/battery/Content.qml` : tuiles, déconnexion, jauge (`Canvas`), textes, cercles de fond flous, Échap ferme.
- `components/ScreenState.qml` : `battery` ; l'exclusion mutuelle passe par `closeOthers(name)` (dashboard, wifi, bluetooth, audio, battery).
- `bar/BarWindow.qml` : `Bat.Wrapper`, hauteur / masque / focus grab / barre des tâches pour cinq panneaux.
- `BatteryWidget.qml` : le clic bascule `screenState.battery` ; `Utilities.qml` lui passe `screenState`.
- `shell.qml` : IPC `battery toggle`. `README.md`.

## Comportement

- Anneau animé vers le pourcentage ; couleur : principale par défaut, jaune ≤ 40 %, rouge ≤ 20 % (décharge), verte en charge ; pulsation sous 15 % en décharge.
- État : « EN DÉCHARGE », « EN CHARGE », « CHARGÉE », « VIDE »…
- Autonomie : `timeToEmpty` en décharge, `timeToFull` en charge, au format « 36 min » ou « 1 h 24 ».
- Déconnexion : un premier clic demande « Confirmer ? » (3 s), un second lance `hyprctl dispatch exit` (l'ancien `exit.sh` n'existe pas).
- Pas de batterie : message « Aucune batterie ».

## Vérification

Smoke et captures. Aucune action de déconnexion lancée pendant les tests.
