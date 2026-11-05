# Panneau de gestion Wi-Fi — spec de design

Date : 2026-11-05

## Objectif

Remplacer le popup réseau externe (`~/.config/hypr/scripts/quickshell/network/NetworkPopup.qml`, appelé via `qs_manager.sh toggle network wifi`) par un panneau Wi-Fi intégré au shell, qui s'ouvre sous la barre comme le dashboard. Le panneau permet de gérer le Wi-Fi comme un gestionnaire de réseau : connexion, réseaux enregistrés, détails du réseau actif.

## Périmètre

**Inclus**
- Activer/désactiver le Wi-Fi, scanner, se connecter (avec mot de passe), se déconnecter, ajouter un réseau caché.
- Réseaux enregistrés : lister, oublier, activer/désactiver la connexion automatique.
- Détails du réseau actif : SSID, signal, sécurité, IP, passerelle, DNS, adresse MAC, fréquence et canal.
- Ouverture par le bouton Wi-Fi de la barre et par une commande IPC.

**Exclus (hors périmètre)**
- Réglages avancés : IP statique, DNS personnalisés, MAC aléatoire, connexion à usage limité, proxy.
- Bluetooth et Ethernet : leurs boutons gardent le comportement actuel (popup externe via `qs_manager.sh`).
- Fenêtre Hyprland classique ou fenêtre flottante centrée.

## Décisions déjà prises

- Forme : panneau sous la barre, même mécanique que `modules/dashboard` (approche A).
- Fonctions : base, réseaux enregistrés, détails du réseau actif.
- Les données viennent uniquement du singleton `services/Nmcli.qml`, qui expose déjà `networks`, `active`, `scanning`, `connecting`, `wifiEnabled`, `savedConnections`, `connectionFailed`, ainsi que `connectToNetwork`, `disconnectFromNetwork`, `forgetNetwork`, `getAutoconnect`/`setAutoconnect`, `addHiddenNetwork`, `rescanWifi`, `toggleWifi`, `getWirelessDeviceDetails`.

## Architecture

### Fichiers

| Fichier | Rôle |
|---|---|
| `modules/wifi/Wrapper.qml` | Enveloppe animée (descente depuis la barre, fond, coins « notch »), calquée sur `modules/dashboard/Wrapper.qml`. Expose `shouldBeActive`, `implicitHeight`. |
| `modules/wifi/Content.qml` | Colonne unique : en-tête, réseau actif, réseaux disponibles, réseaux enregistrés. |
| `modules/wifi/NetworkRow.qml` | Une ligne de réseau disponible (icône de signal, SSID, sécurité, état). |
| `modules/wifi/PasswordPrompt.qml` | Champ de mot de passe affiché sous une ligne de réseau sécurisé et inconnu. |
| `modules/wifi/SavedRow.qml` | Une ligne de réseau enregistré (bascule connexion automatique, bouton Oublier avec confirmation). |
| `modules/wifi/ActiveDetails.qml` | Bloc repliable des détails du réseau actif. |
| `modules/wifi/HiddenNetworkForm.qml` | Formulaire d'ajout d'un réseau caché (SSID, sécurité, mot de passe). |

### Modifications de fichiers existants

- `components/ScreenState.qml` : ajouter `property bool wifi`.
- `bar/BarWindow.qml` : instancier `Wifi.Wrapper` à côté de `dashWrapper` (même ancrage sous `barRect`, même `z: -1`), étendre le masque d'entrée (`inputMask`) et le `HyprlandFocusGrab` pour couvrir aussi le panneau Wi-Fi, ajuster `implicitHeight` de la fenêtre pour qu'elle contienne le panneau.
- `bar/components/Utilities.qml` : le bouton Wi-Fi bascule `ScreenState.wifi` au lieu d'exécuter `qs_manager.sh`.
- `shell.qml` : ajouter un `IpcHandler` de cible `wifi` avec `toggle()`, sur le modèle de celui du dashboard.
- `services/Nmcli.qml` : uniquement les ajouts nécessaires (voir « Service »).

### Coordination des panneaux

Un seul de `dashboard` et `wifi` est ouvert à la fois par écran : ouvrir l'un met l'autre à `false`. Cette règle est appliquée là où les drapeaux sont modifiés (bouton, IPC), pas dans les composants d'affichage.

### Service

`Nmcli` gère déjà la connexion, l'oubli, l'autoconnect, le réseau caché et le scan. Les ajouts éventuels se limitent à exposer les détails du réseau actif sous une forme directement affichable (IP, passerelle, DNS, MAC, fréquence, canal) à partir de `getWirelessDeviceDetails` et `parseDeviceDetails`. On vérifie d'abord ce que ces fonctions renvoient déjà avant d'ajouter quoi que ce soit.

## Contenu et comportement

**En-tête** : interrupteur Wi-Fi (`Nmcli.toggleWifi`), bouton de scan (`Nmcli.rescanWifi`) avec indicateur lié à `Nmcli.scanning`.

**Réseau actif** : SSID, force du signal, sécurité, puis le bloc repliable des détails. Bouton « Déconnecter » (`Nmcli.disconnectFromNetwork`). Section absente si aucun réseau n'est actif.

**Réseaux disponibles** : liste issue de `Nmcli.networks`, triée par signal décroissant, sans le réseau actif. Un clic :
- réseau enregistré : connexion directe ;
- réseau ouvert : connexion directe ;
- réseau sécurisé et inconnu : affichage du `PasswordPrompt` sous la ligne, puis connexion à la validation.
Un bouton « Réseau caché » ouvre le `HiddenNetworkForm`.

**Réseaux enregistrés** : liste issue de `Nmcli.savedConnections`. Chaque ligne a une bascule de connexion automatique (`getAutoconnect` à l'affichage, `setAutoconnect` au changement) et un bouton « Oublier » qui demande une confirmation avant d'appeler `forgetNetwork`.

**Fermeture** : clic en dehors (via `HyprlandFocusGrab`), nouveau clic sur le bouton Wi-Fi, ou commande IPC `toggle`.

## Flux de données

Le panneau lit les propriétés réactives de `Nmcli`. Il n'y a pas de polling : le service se met à jour via `nmcli monitor`. Les actions appellent les fonctions de `Nmcli` et l'interface se met à jour par réaction aux propriétés, sans état dupliqué dans le panneau, sauf l'état purement visuel (ligne dépliée, champ de mot de passe ouvert, confirmation d'oubli en attente).

## Gestion des erreurs

- Échec de connexion : signal `Nmcli.connectionFailed(ssid)`. La ligne concernée affiche un message d'erreur et permet un nouvel essai.
- Mot de passe refusé : le `PasswordPrompt` reste ouvert avec un message, le champ est conservé.
- Wi-Fi désactivé (`wifiEnabled` faux) : le panneau montre l'interrupteur et un message, sans listes ni scan.
- Aucun réseau détecté : message vide dans la liste, le bouton de scan reste disponible.
- Connexion en cours (`Nmcli.connecting`) : la ligne concernée affiche un état « connexion… » et les autres clics sont ignorés tant qu'elle dure.

## Vérification

Pas de tests automatiques sur l'interface QML. Vérification manuelle après relance de Quickshell :
1. Le bouton Wi-Fi ouvre et ferme le panneau, avec l'animation du dashboard.
2. Ouvrir le panneau Wi-Fi ferme le dashboard, et inversement.
3. Le clic en dehors ferme le panneau.
4. Le scan met à jour la liste ; l'interrupteur coupe et rétablit le Wi-Fi.
5. Connexion à un réseau enregistré, à un réseau sécurisé inconnu (mot de passe juste puis faux), à un réseau caché.
6. Déconnexion, bascule de connexion automatique, oubli d'un réseau avec confirmation.
7. Les détails du réseau actif correspondent à `nmcli device show`.
8. La commande IPC `wifi toggle` ouvre et ferme le panneau.
9. Les boutons Bluetooth et Ethernet fonctionnent comme avant.

## Risques et points à confirmer à l'implémentation

- La largeur du panneau (environ 420 px) est une valeur de départ à ajuster visuellement.
- `inputMask` et `implicitHeight` de la `BarWindow` dépendent aujourd'hui du seul `dashWrapper` ; il faut qu'ils prennent le plus grand des deux panneaux.
- Le popup externe reste présent pour Bluetooth et Ethernet. Il n'est pas supprimé, car il est hors du dépôt.
