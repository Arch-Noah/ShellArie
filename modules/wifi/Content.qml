pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

Item {
    id: root

    required property ScreenState screenState

    readonly property int margin: 16
    readonly property int maxContentHeight: 640
    // Réseau dont le champ de mot de passe est déplié (un seul à la fois)
    property string expandedSsid
    property bool showHiddenForm

    // Réseaux non actifs, triés par signal (par paliers de 10 pour limiter les sauts d'ordre).
    // availableRaw se réévalue à chaque scan ; `available` (le modèle du Repeater) n'est remplacé
    // que si la liste change vraiment, pour ne pas détruire un champ de mot de passe en cours de saisie.
    readonly property var availableRaw: {
        const list = [];
        for (const n of Nmcli.networks) {
            if (!n.active)
                list.push({
                    ap: n,
                    bucket: Math.round(n.strength / 10)
                });
        }
        list.sort((a, b) => b.bucket - a.bucket || a.ap.ssid.localeCompare(b.ap.ssid));
        return list.map(e => e.ap);
    }
    property var available: []
    property string availableKey

    onAvailableRawChanged: {
        const ssids = availableRaw.map(n => n.ssid);
        // Un mot de passe est en cours de saisie : on ignore l'ordre, seul l'ensemble compte
        const key = (expandedSsid !== "" ? ssids.slice().sort() : ssids).join("\n");
        if (key !== availableKey) {
            availableKey = key;
            available = availableRaw;
        }
    }

    implicitWidth: 420
    implicitHeight: Math.min(column.implicitHeight + margin * 2, maxContentHeight)

    // Les détails IP/DNS/MAC suivent le réseau actif
    Connections {
        target: Nmcli

        function onActiveChanged(): void {
            Nmcli.getWirelessDeviceDetails("", null);
        }
    }

    Component.onCompleted: {
        availableRawChanged();
        Nmcli.getWirelessDeviceDetails("", null);
        Nmcli.rescanWifi();
        Nmcli.loadSavedConnections(null);
    }

    Flickable {
        id: flick
        anchors.fill: parent
        anchors.margins: root.margin
        clip: true
        contentWidth: width
        contentHeight: column.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: column
            width: flick.width
            spacing: 12

            // --- En-tête : titre, interrupteur, scan ---
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                StyledText {
                    text: qsTr("Wi-Fi")
                    font: Tokens.font.title.small
                    Layout.fillWidth: true
                }

                IconButton {
                    icon: "refresh"
                    type: IconButton.Text
                    disabled: !Nmcli.wifiEnabled
                    opacity: Nmcli.scanning ? 0.5 : 1
                    onClicked: Nmcli.rescanWifi()
                }

                StyledSwitch {
                    checked: Nmcli.wifiEnabled
                    onToggled: Nmcli.toggleWifi(null)
                }
            }

            StyledText {
                visible: !Nmcli.wifiEnabled
                text: qsTr("Wi-Fi désactivé")
                color: Colours.palette.m3onSurfaceVariant
                Layout.fillWidth: true
            }

            // --- Réseau actif ---
            Loader {
                active: Nmcli.wifiEnabled && !!Nmcli.active
                visible: active
                Layout.fillWidth: true

                sourceComponent: ActiveDetails {
                    network: Nmcli.active
                }
            }

            // --- Réseaux disponibles ---
            StyledText {
                visible: Nmcli.wifiEnabled
                text: qsTr("Réseaux disponibles")
                color: Colours.palette.m3onSurfaceVariant
                Layout.fillWidth: true
            }

            StyledText {
                visible: Nmcli.wifiEnabled && root.available.length === 0
                text: qsTr("Aucun réseau détecté")
                color: Colours.palette.m3onSurfaceVariant
                Layout.fillWidth: true
            }

            Repeater {
                model: Nmcli.wifiEnabled ? root.available : []

                delegate: ColumnLayout {
                    id: item

                    required property var modelData

                    Layout.fillWidth: true
                    spacing: 0

                    function attempt(password: string): void {
                        row.errorText = "";
                        Nmcli.connectToNetwork(modelData.ssid, password, modelData.bssid, result => {
                            if (result.success) {
                                root.expandedSsid = "";
                                prompt.clear();
                            } else if (result.needsPassword) {
                                row.errorText = qsTr("Mot de passe refusé");
                            } else {
                                row.errorText = result.error || qsTr("Échec de la connexion");
                            }
                        });
                    }

                    NetworkRow {
                        id: row
                        Layout.fillWidth: true
                        network: item.modelData
                        onConnectRequested: {
                            if (Nmcli.connecting)
                                return;
                            errorText = "";
                            if (item.modelData.isSecure && !Nmcli.hasSavedProfile(item.modelData.ssid)) {
                                root.expandedSsid = root.expandedSsid === item.modelData.ssid ? "" : item.modelData.ssid;
                                return;
                            }
                            root.expandedSsid = "";
                            Nmcli.connectToNetworkWithPasswordCheck(item.modelData.ssid, item.modelData.isSecure, result => {
                                if (result.success)
                                    return;
                                if (result.needsPassword)
                                    root.expandedSsid = item.modelData.ssid;
                                else
                                    errorText = result.error || qsTr("Échec de la connexion");
                            }, item.modelData.bssid);
                        }
                    }

                    PasswordPrompt {
                        id: prompt
                        visible: root.expandedSsid === item.modelData.ssid
                        Layout.fillWidth: true
                        Layout.leftMargin: 8
                        Layout.rightMargin: 8
                        Layout.bottomMargin: 6
                        onVisibleChanged: if (visible)
                            focusField()
                        onSubmitted: password => item.attempt(password)
                    }

                    Connections {
                        target: Nmcli

                        function onConnectionFailed(ssid: string): void {
                            if (ssid === item.modelData.ssid && row.errorText === "")
                                row.errorText = qsTr("Échec de la connexion");
                        }
                    }
                }
            }

            // --- Réseau caché ---
            TextButton {
                visible: Nmcli.wifiEnabled && !root.showHiddenForm
                text: qsTr("Réseau caché")
                type: TextButton.Text
                Layout.alignment: Qt.AlignLeft
                onClicked: root.showHiddenForm = true
            }

            Loader {
                active: Nmcli.wifiEnabled && root.showHiddenForm
                visible: active
                Layout.fillWidth: true
                Layout.leftMargin: 8
                Layout.rightMargin: 8

                sourceComponent: HiddenNetworkForm {
                    onClosed: root.showHiddenForm = false
                }
            }

            // --- Réseaux enregistrés ---
            StyledText {
                visible: Nmcli.wifiEnabled && Nmcli.savedConnectionSsids.length > 0
                text: qsTr("Réseaux enregistrés")
                color: Colours.palette.m3onSurfaceVariant
                Layout.fillWidth: true
            }

            Repeater {
                model: Nmcli.wifiEnabled ? Nmcli.savedConnectionSsids : []

                delegate: SavedRow {
                    required property string modelData

                    ssid: modelData
                    Layout.fillWidth: true
                }
            }
        }
    }
}
