pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.services

// Vue « Disponibles » : réseaux détectés, triés par signal, avec connexion et mot de passe.
ColumnLayout {
    id: root

    // Réseau dont le champ de mot de passe est déplié (un seul à la fois)
    property string expandedSsid

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

    Component.onCompleted: availableRawChanged()

    spacing: 0

    WifiText {
        visible: root.available.length === 0
        text: qsTr("Aucun réseau détecté")
        color: Colours.palette.m3onSurfaceVariant
        Layout.fillWidth: true
        Layout.margins: 6
    }

    Repeater {
        model: root.available

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
                Layout.leftMargin: 6
                Layout.rightMargin: 6
                Layout.bottomMargin: 4
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
}
