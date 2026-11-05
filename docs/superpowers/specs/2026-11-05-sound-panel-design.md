# Panneau Son — spec de design

Date : 2026-11-05

## Objectif

Remplacer le popup volume externe (`qs_manager.sh toggle volume`) par un panneau intégré sous la barre, dans le style des panneaux Wi-Fi et Bluetooth.

## Périmètre

**Inclus** : deux vues, **Sortie** et **Entrée** ; ouverture par un clic sur le widget de volume de la barre et par `qs ipc call sound toggle`.

**Exclus** : mixage par application, profils de la carte son, égaliseur, visualiseur, son de test. Le curseur au survol du widget de volume de la barre reste inchangé.

## Données

Tout vient de `services/Audio.qml` (Pipewire) : `sink`, `sinks`, `source`, `sources`, `volume`, `muted`, `sourceVolume`, `sourceMuted`, `setStreamVolume(node, v)` et `setStreamMuted(node, bool)` (valables pour tout nœud), `setAudioSink(node)`, `setAudioSource(node)`. Plafond de volume : `GlobalConfig.services.maxVolume`.

## Architecture

- `modules/sound/Wrapper.qml` : `PanelWrapper` sur `ScreenState.audio`.
- `modules/sound/Content.qml` : en-tête « Son », onglets en icônes (`volume_up`, `mic`), flèches gauche/droite, Échap, une vue à la fois ; s'ouvre sur Sortie.
- `modules/sound/DeviceView.qml` : vue paramétrée par `output: bool` (Sortie ou Entrée). Carte du périphérique actif (icône, nom, volume en grand, curseur `StyledSlider`, bouton sourdine) puis carte de la liste des périphériques.
- `modules/sound/DeviceRow.qml` : une ligne de périphérique (icône, nom, coche si c'est le périphérique par défaut) ; un clic le définit par défaut.
- `components/ScreenState.qml` : `property bool audio` ; exclusion mutuelle entre dashboard, wifi, bluetooth, audio.
- `bar/BarWindow.qml` : `Snd.Wrapper` ; hauteur, masque, focus grab, barre des tâches pour quatre panneaux.
- `bar/components/utilities_components/VolumeWidget.qml` : propriété `screenState`, le clic bascule `screenState.audio` ; `Utilities.qml` la lui passe.
- `shell.qml` : `IpcHandler` cible `sound` (la cible `audio` existe déjà dans `Audio.qml`).
- `README.md`.

## Comportement

- Curseur : `value` lié au volume du nœud (via `Binding` actif hors glissement), `onMoved` → `Audio.setStreamVolume`. Sourdine : `Audio.setStreamMuted(node, !muted)`.
- Icône du périphérique d'après son nom : casque (`headphones`), HDMI/DisplayPort (`tv`), enceinte (`speaker`) par défaut, micro (`mic`) pour l'entrée ; icône de sourdine (`volume_off` / `mic_off`) quand coupé.
- Aucun périphérique : message vide centré (`PanelEmpty`).
- Listes à modèle stable (remplacé seulement si l'ensemble des nœuds change).

## Vérification

Smoke et captures. Aucune modification du volume, de la sourdine ou du périphérique par défaut pendant les tests.

## Écart avec le design présenté

Pas de `PanelSlider` : `StyledSlider` (existant) suffit.
