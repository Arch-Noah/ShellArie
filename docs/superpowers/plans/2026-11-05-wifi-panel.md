# Panneau Wi-Fi Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remplacer le popup réseau externe par un panneau Wi-Fi intégré qui s'ouvre sous la barre, avec connexion, réseaux enregistrés et détails du réseau actif.

**Architecture:** Un module `modules/wifi/` calqué sur `modules/dashboard` (Wrapper animé + Content), branché dans `bar/BarWindow.qml` via un drapeau `ScreenState.wifi`. Toutes les données et actions passent par le singleton `services/Nmcli.qml`, qui fournit déjà tout le nécessaire.

**Tech Stack:** Quickshell (QML), singleton `Nmcli` (nmcli), thème `Colours`/`Tokens` (`qs.services`, `Caelestia.Config`) et contrôles de `qs.components.controls`.

**Spec:** `docs/superpowers/specs/2026-11-05-wifi-panel-design.md`

## Global Constraints

- Largeur de contenu du panneau : 420 px ; hauteur de contenu plafonnée à 640 px, au-delà la liste défile.
- Un seul de `dashboard` et `wifi` est ouvert à la fois par écran.
- Aucun polling : on lit les propriétés réactives de `Nmcli` (`networks`, `active`, `scanning`, `connecting`, `wifiEnabled`, `savedConnections`).
- Bluetooth et Ethernet gardent `qs_manager.sh` ; `qs_manager.sh` n'est plus appelé que par eux.
- Pas de réglages avancés (IP statique, DNS, MAC aléatoire, metered, proxy).
- Textes de l'interface via `qsTr(...)`, en français dans les commits et commentaires.

## Review Focus

- Wi-Fi désactivé : le panneau montre l'interrupteur et un message, aucune liste, aucun scan.
- Aucun réseau actif ou aucun réseau détecté : pas de section « actif », message vide dans la liste.
- Mot de passe faux : le champ reste ouvert avec le message d'erreur, le texte saisi est conservé.
- Réseau caché avec SSID vide : le bouton de connexion est désactivé.
- Double clic ou clic sur un autre réseau pendant `Nmcli.connecting` : ignoré.
- Oublier le réseau actif : la confirmation est demandée, puis la section « actif » disparaît.
- Longue liste de réseaux : le panneau garde sa hauteur plafonnée et défile.
- Plusieurs écrans : le panneau n'agit que sur l'écran concerné (`ShellState.forScreen` / `forActive`).

## Vérification (valable pour toutes les tâches)

Aucun test automatisé n'existe pour le QML. L'instance Quickshell en cours d'exécution est l'ancien `~/.config/hypr/scripts/quickshell/Shell.qml`, pas ShellArie. On lance donc ShellArie en parallèle pour vérifier :

- **Smoke** (aucune erreur de chargement) : depuis la racine du dépôt, `timeout 10 qs -p shell.qml > $SCRATCH/smoke.log 2>&1; grep -E "ERROR|unavailable|is not a type|is not defined|ReferenceError|TypeError" $SCRATCH/smoke.log` doit ne rien afficher. `$SCRATCH` est le dossier scratchpad de la session.
- **Pilotage** : instance lancée en arrière-plan avec `qs -d -p shell.qml`, puis `qs -p shell.qml ipc call wifi toggle`, capture avec `grim $SCRATCH/x.png`, arrêt avec `pkill -f "qs.*ShellArie/shell.qml"`.
- Avant la Task 1, faire un smoke de référence pour savoir quelles erreurs existent déjà.

---

### Task 1: Squelette du panneau, branchement et en-tête

**Files:**
- Create: `modules/wifi/Wrapper.qml`, `modules/wifi/Content.qml`
- Modify: `components/ScreenState.qml`, `bar/BarWindow.qml`, `bar/components/CustomRevealer.qml`, `bar/components/Utilities.qml`, `shell.qml`

**Interfaces:**
- Produces: `ScreenState.wifi: bool` ; `Wifi.Wrapper` avec `required property ScreenState screenState`, `readonly property bool shouldBeActive`, `implicitHeight` ; `Content` avec `required property ScreenState screenState`, `implicitWidth: 420`, `implicitHeight` plafonné à 640, et une `ColumnLayout` id `column` à l'intérieur d'un `Flickable` où les tâches suivantes ajoutent leurs sections ; IPC `wifi.toggle()`.

- [ ] **Step 1: Smoke de référence.** Lancer le smoke décrit plus haut sur l'état actuel du dépôt et noter les erreurs déjà présentes. Si ShellArie ne démarre pas du tout, le signaler avant d'aller plus loin.

- [ ] **Step 2: `ScreenState.wifi` et exclusion mutuelle.** Dans `components/ScreenState.qml`, ajouter `property bool wifi` ainsi que `onDashboardChanged: if (dashboard) wifi = false` et `onWifiChanged: if (wifi) dashboard = false`. Cela couvre tous les endroits qui écrivent `dashboard` (IPC, horloge, MPRIS, `User.qml`) sans les toucher.

- [ ] **Step 3: `modules/wifi/Wrapper.qml`.** Copier la mécanique de `modules/dashboard/Wrapper.qml` (animation `offsetScale` avec `Anim.SlowSpatial`, fond `Styles.mixAlpha(Styles.background, 0.90)`, notches gauche et droite, `Loader` actif seulement si `shouldBeActive`). Différences : `shouldBeActive = screenState?.wifi ?? false`, pas de `FileDialog`, pas de `Config.dashboard.enabled`, largeur de contenu fixe `Content.implicitWidth`, `sourceComponent: Content { screenState: root.screenState }`. Garder `notchRadius` à 60 et `clip: true`, comme dans le dashboard.

- [ ] **Step 4: `modules/wifi/Content.qml`.** Un `Item` avec `implicitWidth: 420`, `implicitHeight: Math.min(column.implicitHeight + 2 * margin, 640)`, un `Flickable` (`clip: true`, `contentHeight: column.implicitHeight`) contenant `ColumnLayout { id: column }`. Premier contenu : l'en-tête. Titre « Wi-Fi », `StyledSwitch` lié à `Nmcli.wifiEnabled` (`onToggled: Nmcli.toggleWifi(null)`), `IconButton` de scan (`icon: "refresh"`, `onClicked: Nmcli.rescanWifi()`, désactivé si `!Nmcli.wifiEnabled`, `LoadingIndicator` ou icône animée tant que `Nmcli.scanning`). Si `!Nmcli.wifiEnabled`, afficher en dessous un `StyledText` « Wi-Fi désactivé ». À l'ouverture (`Component.onCompleted`), appeler `Nmcli.rescanWifi()` et `Nmcli.loadSavedConnections(null)`.

- [ ] **Step 5: Brancher dans `bar/BarWindow.qml`.** Ajouter `import "../modules/wifi" as Wifi`. Instancier `Wifi.Wrapper { id: wifiWrapper; screenState: ShellState.forScreen(modelData); anchors.top: barRect.bottom; anchors.right: parent.right; z: -1 }` à côté de `dashWrapper` (ancré à droite car le bouton Wi-Fi est dans la zone de droite de la barre). Mettre à jour :
  - `implicitHeight` de la fenêtre : `Math.max(dashWrapper.implicitHeight + 60, wifiWrapper.implicitHeight + 60, 850)` ;
  - `inputMask` : la hauteur utilise le plus grand `implicitHeight` des wrappers visibles (`dashWrapper.visible` / `wifiWrapper.visible`) ;
  - `HyprlandFocusGrab` : `active: dashWrapper.shouldBeActive || wifiWrapper.shouldBeActive`, et `onCleared` met `dashboard` et `wifi` à `false` ;
  - `Taskbar.suppressed: dashWrapper.visible || wifiWrapper.visible`.

- [ ] **Step 6: Le bouton Wi-Fi.** Dans `bar/components/CustomRevealer.qml`, ajouter `signal clicked()` émis sur clic gauche (avant l'éventuelle commande, qui reste inchangée quand `onClickCommand` est défini). Dans `bar/components/Utilities.qml`, ajouter `property var screenState`, retirer `onClickCommand` de `wifiRevealer` et ajouter `onClicked: if (utilitiesLayout.screenState) utilitiesLayout.screenState.wifi = !utilitiesLayout.screenState.wifi`. Dans `BarWindow.qml`, passer `screenState: ShellState.forScreen(modelData)` à l'instance `Utilities`.

- [ ] **Step 7: IPC.** Dans `shell.qml`, ajouter un `IpcHandler { target: "wifi"; function toggle(): void }` qui bascule `ShellState.forActive().wifi`, sur le modèle de celui du dashboard.

- [ ] **Step 8: Vérifier.** Smoke sans nouvelle erreur par rapport à la référence. Puis `qs -p shell.qml ipc call wifi toggle` : le panneau apparaît sous la barre à droite avec l'animation, l'en-tête s'affiche, un second appel le ferme. Ouvrir `dashboard toggle` pendant que le Wi-Fi est ouvert : le Wi-Fi se ferme. Capture `grim` pour confirmer le rendu.

- [ ] **Step 9: Commit** — `git add modules/wifi components/ScreenState.qml bar shell.qml && git commit -m "Wi-Fi: panneau sous la barre avec en-tête, IPC et bouton"`

---

### Task 2: Réseaux disponibles, connexion et mot de passe

**Files:**
- Create: `modules/wifi/NetworkRow.qml`, `modules/wifi/PasswordPrompt.qml`
- Modify: `modules/wifi/Content.qml`

**Interfaces:**
- Consumes: `Content.column` (Task 1) ; de `Nmcli` : `networks` (éléments `AccessPoint` : `ssid`, `bssid`, `strength`, `security`, `isSecure`, `active`), `connecting`, `connectingSsid()`, `hasSavedProfile(ssid): bool`, `connectToNetwork(ssid, password, bssid, callback)`, `connectToNetworkWithPasswordCheck(ssid, isSecure, callback, bssid)`, signal `connectionFailed(ssid)`.
- Produces: `NetworkRow` avec `required property var network`, `property string errorText`, `signal connectRequested()` ; `PasswordPrompt` avec `signal submitted(string password)`, `property string errorText`, `function clear()`.

- [ ] **Step 1: `NetworkRow.qml`.** Ligne cliquable : icône de signal (mêmes seuils 80/60/40/20 que `Utilities.qml`), SSID, icône cadenas si `network.isSecure`, état « connexion… » si `Nmcli.connectingSsid() === network.ssid`, et `errorText` sous la ligne quand il n'est pas vide. Le clic est ignoré si `Nmcli.connecting`.

- [ ] **Step 2: `PasswordPrompt.qml`.** `StyledTextField` en mode mot de passe (`echoMode: TextInput.Password`), bouton de validation désactivé si le champ est vide, `Keys.onReturnPressed` valide aussi. Émet `submitted(password)`. Ne vide pas le champ en cas d'erreur.

- [ ] **Step 3: Liste dans `Content.qml`.** Propriété `readonly property var available` : tableau des `Nmcli.networks` non actifs, trié par `strength` décroissant ; l'expression doit lire `n.active` et `n.strength` pour que le tri se mette à jour quand le scan modifie les valeurs. Un `Repeater` sur `available` instancie `NetworkRow` + `PasswordPrompt` (visible seulement pour la ligne dépliée). Titre de section « Réseaux disponibles » ; si la liste est vide et `Nmcli.wifiEnabled`, message « Aucun réseau détecté ». Toute la section est masquée quand `!Nmcli.wifiEnabled`.

- [ ] **Step 4: Logique de connexion.** Sur `connectRequested` : si `!isSecure || Nmcli.hasSavedProfile(ssid)` → `Nmcli.connectToNetworkWithPasswordCheck(ssid, isSecure, cb, bssid)` ; si le résultat indique `needsPassword`, déplier le `PasswordPrompt`. Sinon déplier le prompt. À la validation du prompt → `Nmcli.connectToNetwork(ssid, password, bssid, cb)`. Succès : replier le prompt et vider `errorText`. Échec (callback `success: false` ou `Nmcli.connectionFailed(ssid)` via un `Connections`) : renseigner `errorText` de la ligne avec l'erreur et garder le prompt ouvert. Un seul prompt ouvert à la fois (propriété `expandedSsid` dans `Content`).

- [ ] **Step 5: Vérifier.** Smoke propre ; ouvrir le panneau, constater la liste triée, tester à la main : connexion à un réseau enregistré, à un réseau sécurisé inconnu avec mauvais mot de passe (le prompt reste, le message s'affiche, le texte est conservé) puis bon mot de passe, Wi-Fi désactivé (pas de liste), clic pendant la connexion (ignoré). Si la liste ne se rafraîchit pas après un scan, vérifier que la binding lit bien `Nmcli.networks` et les propriétés des éléments.

- [ ] **Step 6: Commit** — `git add modules/wifi && git commit -m "Wi-Fi: liste des réseaux, connexion et mot de passe"`

---

### Task 3: Réseau actif et détails

**Files:**
- Create: `modules/wifi/ActiveDetails.qml`
- Modify: `modules/wifi/Content.qml`

**Interfaces:**
- Consumes: `Nmcli.active` (`AccessPoint` ou `null`), `Nmcli.wirelessDeviceDetails` (objet `{ ipAddress, gateway, dns: [], subnet, macAddress }` ou `null`), `Nmcli.getWirelessDeviceDetails("", callback)`, `Nmcli.disconnectFromNetwork()`.
- Produces: `ActiveDetails` avec `required property var network` et `property bool expanded`.

- [ ] **Step 1: `ActiveDetails.qml`.** En-tête de section : icône de signal, SSID, sécurité, flèche pour replier/déplier. Quand `expanded`, lignes libellé/valeur : IP, passerelle, DNS (valeurs jointes par « , »), adresse MAC, fréquence en MHz et canal calculé à partir de `network.frequency` (2,4 GHz : `(f - 2407) / 5`, canal 14 pour 2484 ; 5 GHz : `(f - 5000) / 5`). Valeur absente → « — ». Bouton « Déconnecter » qui appelle `Nmcli.disconnectFromNetwork()`.

- [ ] **Step 2: Intégrer dans `Content.qml`.** Section affichée uniquement si `Nmcli.active && Nmcli.wifiEnabled`, placée entre l'en-tête et la liste des disponibles. Appeler `Nmcli.getWirelessDeviceDetails("", null)` à l'ouverture et dès que `Nmcli.active` change (via `Connections` ou `onActiveChanged`). Les détails sont lus dans `Nmcli.wirelessDeviceDetails`.

- [ ] **Step 3: Vérifier.** Smoke propre ; avec un réseau connecté, les valeurs affichées correspondent à `nmcli device show <interface>` (IP, passerelle, DNS, MAC) et à `nmcli -f ACTIVE,FREQ,SSID device wifi` pour la fréquence. Se déconnecter fait disparaître la section ; sans réseau actif, aucune section vide n'apparaît.

- [ ] **Step 4: Commit** — `git add modules/wifi && git commit -m "Wi-Fi: réseau actif et détails de connexion"`

---

### Task 4: Réseaux enregistrés et réseau caché

**Files:**
- Create: `modules/wifi/SavedRow.qml`, `modules/wifi/HiddenNetworkForm.qml`
- Modify: `modules/wifi/Content.qml`

**Interfaces:**
- Consumes: `Nmcli.savedConnections: list<string>`, `Nmcli.getAutoconnect(name, cb(bool))`, `Nmcli.setAutoconnect(name, enabled, cb)`, `Nmcli.forgetNetwork(ssid, cb)`, `Nmcli.addHiddenNetwork(ssid, password, security, hidden, cb)`, `Nmcli.savedConnectionSsids`, `Nmcli.active`.
- Produces: `SavedRow` avec `required property string connectionName` ; `HiddenNetworkForm` avec `signal closed()`.

- [ ] **Step 1: `SavedRow.qml`.** Nom de la connexion, `StyledSwitch` « Connexion automatique » initialisé par `Nmcli.getAutoconnect` à la création et appliqué par `Nmcli.setAutoconnect` au changement (en cas d'échec, remettre l'interrupteur à sa valeur précédente), bouton « Oublier » qui bascule la ligne en mode confirmation (« Confirmer » / « Annuler ») avant d'appeler `Nmcli.forgetNetwork(connectionName, cb)`.

- [ ] **Step 2: `HiddenNetworkForm.qml`.** Champs SSID, sécurité (« Aucune » / « WPA/WPA2 », valeurs `"none"` / `"wpa-psk"` passées à `addHiddenNetwork`), mot de passe (visible seulement avec sécurité), boutons « Connecter » (désactivé si SSID vide, ou mot de passe vide avec sécurité) et « Annuler ». À la validation → `Nmcli.addHiddenNetwork(ssid, password, security, true, cb)` ; succès : émettre `closed()`, échec : afficher l'erreur dans le formulaire.

- [ ] **Step 3: Intégrer dans `Content.qml`.** Bouton « Réseau caché » en fin de la section des disponibles, qui affiche le `HiddenNetworkForm`. Section « Réseaux enregistrés » en bas : `Repeater` sur les connexions Wi-Fi enregistrées. `Nmcli.savedConnections` contient toutes les connexions NetworkManager (Ethernet, VPN…), donc filtrer sur `Nmcli.savedConnectionSsids` (ou l'équivalent qui ne garde que les connexions de type `802-11-wireless`) ; vérifier dans `Nmcli.qml` (`parseConnectionList`, `queryNextSsid`, `processSsidOutput`) ce qui correspond à un nom de connexion et choisir en conséquence. Section masquée si la liste est vide.

- [ ] **Step 4: Vérifier.** Smoke propre ; la liste des enregistrés correspond à `nmcli -t -f NAME,TYPE connection show | grep 802-11-wireless` ; la bascule d'autoconnect est reflétée par `nmcli -g connection.autoconnect connection show <nom>` ; « Oublier » demande confirmation puis la connexion disparaît ; oublier le réseau actif fait aussi disparaître la section « actif » ; formulaire caché avec SSID vide : bouton désactivé.

- [ ] **Step 5: Commit** — `git add modules/wifi && git commit -m "Wi-Fi: réseaux enregistrés et ajout d'un réseau caché"`

---

### Task 5: Passe finale

**Files:**
- Modify: `README.md` (seulement s'il documente les IPC ou le bouton Wi-Fi)

- [ ] **Step 1: Relire la check-list de vérification de la spec** (9 points) et la dérouler sur l'instance de test. Pour le point 9, vérifier que les boutons Bluetooth et Ethernet appellent toujours `qs_manager.sh`.

- [ ] **Step 2: Revue du diff.** `git diff main --stat` ; vérifier qu'aucun fichier hors périmètre n'a été touché et qu'aucune trace de `qs_manager.sh ... network wifi` ne reste dans le dépôt.

- [ ] **Step 3: README.** Si `README.md` liste les commandes IPC ou décrit le comportement du bouton Wi-Fi, ajouter `wifi toggle`. Sinon ne rien changer.

- [ ] **Step 4: Arrêter l'instance de test** et commit éventuel — `git commit -am "README: commande IPC wifi"`
