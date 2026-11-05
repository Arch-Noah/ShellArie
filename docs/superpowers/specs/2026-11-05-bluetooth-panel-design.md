# Panneau de gestion Bluetooth — spec de design

Date : 2026-11-05

## Objectif

Remplacer le popup Bluetooth externe (`qs_manager.sh toggle network bt`) par un panneau intégré sous la barre, dans le même style que le panneau Wi-Fi (cartes arrondies, onglets en icônes, flèches gauche/droite, copie au clic).

## Périmètre

**Inclus**
- Activer/désactiver l'adaptateur.
- Quatre vues : **Connecté**, **Appairés**, **Découverte**, **Réglages**.
- Ouverture par le bouton Bluetooth de la barre et par la commande IPC `bluetooth toggle`.
- Extraction des composants communs du panneau Wi-Fi vers `components/panel/`, utilisés par les deux panneaux.

**Exclus**
- Saisie d'un code PIN ou d'une clé d'appairage (`Quickshell.Bluetooth` n'expose pas d'agent) : seuls les appareils qui s'appairent sans code (casques, enceintes, souris…) sont gérés.
- Transfert de fichiers, choix du codec audio, renommage d'un appareil.
- Les boutons Ethernet et Batterie/Volume gardent `qs_manager.sh`.

## Données (Quickshell.Bluetooth)

- Adaptateur `Bluetooth.defaultAdapter` : `name`, `enabled` (lecture/écriture), `discovering` (l/é), `discoverable` (l/é), `pairable` (l/é).
- Appareils `Bluetooth.devices.values` : `address`, `name`, `icon`, `state`, `connected`, `paired`, `pairing`, `trusted` (l/é), `batteryAvailable`, `battery` (0..1) ; méthodes `connect()`, `disconnect()`, `pair()`, `cancelPair()`, `forget()`.
- Un appareil sans nom a pour `name` son adresse (`7F-92-03-79-A2-90`).

## Architecture

### Composants communs (`components/panel/`, import `qs.components.panel`)
Déplacés depuis `modules/wifi/` et renommés, sans changement de comportement :
`WifiText→PanelText`, `WifiIcon→PanelIcon`, `CompactSwitch→PanelSwitch`, `WifiCard→PanelCard`, `WifiDivider→PanelDivider`, `WifiButton→PanelButton`, `WifiField→PanelField`, `WifiTabs→PanelTabs`, `InfoRow→PanelInfoRow`. Nouveau `PanelWrapper` : l'enveloppe animée de `modules/wifi/Wrapper.qml` rendue générique (`shouldBeActive`, `contentComponent`). `modules/wifi/Wrapper.qml` devient une enveloppe fine autour de lui.

### Module `modules/bluetooth/`
| Fichier | Rôle |
|---|---|
| `Wrapper.qml` | `PanelWrapper` branché sur `ScreenState.bluetooth` |
| `Content.qml` | en-tête (titre, interrupteur), onglets, une vue à la fois, flèches, Échap |
| `ConnectedView.qml` | une carte par appareil connecté : icône, nom, pastilles (batterie, type), lignes copiables (adresse, appairé, confiance), bouton « Se déconnecter » |
| `PairedView.qml` / `PairedRow.qml` | appareils appairés (connectés d'abord) ; clic = connecter/déconnecter ; interrupteur « de confiance » ; corbeille avec confirmation (`forget()`) |
| `DiscoveryView.qml` / `DiscoveryRow.qml` | scan tant que la vue est affichée ; appareils non appairés (nommés d'abord) ; clic = `pair()` puis confiance + `connect()` ; états « Appairage… » et erreur |
| `SettingsView.qml` | nom de l'adaptateur, interrupteurs Visible (`discoverable`) et Appairable (`pairable`), nombre d'appareils appairés |
| `deviceIcon.js` | correspondance `icon` BlueZ → icône Material (headphones, speaker, keyboard, mouse, smartphone, computer, watch, sports_esports, bluetooth par défaut) |

### Modifications existantes
- `components/ScreenState.qml` : `property bool bluetooth` ; exclusion mutuelle entre `dashboard`, `wifi`, `bluetooth` (chaque ouverture ferme les deux autres).
- `bar/BarWindow.qml` : instancier `Bt.Wrapper` (ancré à droite sous la barre) ; hauteur de fenêtre, masque d'entrée, `HyprlandFocusGrab` et barre des tâches prennent en compte les trois panneaux ; `onCleared` ferme les trois.
- `bar/components/Utilities.qml` : le bouton Bluetooth bascule `screenState.bluetooth`.
- `shell.qml` : `IpcHandler` cible `bluetooth`, fonction `toggle()`.
- `README.md` : fonction du panneau et commande IPC.

## Comportement

- Adaptateur éteint : en-tête et message « Bluetooth désactivé », pas d'onglets. Aucun adaptateur : « Aucun adaptateur Bluetooth ».
- Le panneau s'ouvre toujours sur **Connecté**. Flèches gauche/droite changent de vue, Échap ferme.
- **Découverte** : `adapter.discovering = true` à la création de la vue, `false` à sa destruction (changement de vue ou fermeture du panneau).
- **Appairage** : `device.pair()` ; quand `paired` passe à vrai : `trusted = true` puis `connect()`. Si `pairing` repasse à faux sans `paired`, message « Échec de l'appairage ».
- Les listes utilisent un modèle stable (remplacé seulement si l'ensemble ou l'ordre des adresses change) pour ne pas détruire l'état d'une ligne (confirmation d'oubli, appairage en cours).
- Style : dimensions du panneau Wi-Fi (340 px de large, 480 px de haut maximum), polices et boutons compacts.

## Vérification

Pas de tests automatisés. Smoke de chargement (`qs -p shell.qml` sans erreur QML) et captures d'écran de chaque vue. Les actions qui agissent sur le matériel de l'utilisateur (connecter, déconnecter, oublier, appairer) ne sont pas exécutées sans son accord.

## Risques

- Pas d'agent de saisie de PIN : certains appareils ne pourront pas être appairés depuis le panneau.
- Le renommage des composants du Wi-Fi touche tout `modules/wifi/` : vérifier le Wi-Fi par smoke et capture avant de continuer.
