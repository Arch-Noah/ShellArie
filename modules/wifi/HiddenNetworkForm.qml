import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

// Vue « Caché » : ajout et connexion à un réseau dont le nom n'est pas diffusé.
ColumnLayout {
    id: root

    property string errorText

    // Émis après une connexion réussie
    signal closed

    readonly property bool valid: ssidField.text.trim().length > 0 && (!secured.checked || passwordField.text.length > 0)

    spacing: 0

    function submit(): void {
        if (!valid || Nmcli.connecting)
            return;
        errorText = "";
        Nmcli.addHiddenNetwork(ssidField.text.trim(), passwordField.text, secured.checked ? "wpa-psk" : "none", true, result => {
            if (!root)
                return;
            if (result.success)
                root.closed();
            else
                root.errorText = result.error || qsTr("Échec de la connexion");
        });
    }

    WifiCard {
        Layout.fillWidth: true

        ColumnLayout {
            Layout.fillWidth: true
            Layout.margins: 10
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    implicitWidth: 30
                    implicitHeight: 30
                    radius: 15
                    color: Qt.alpha(Colours.palette.m3onSurface, 0.08)

                    WifiIcon {
                        anchors.centerIn: parent
                        text: "visibility_off"
                        size: 15
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    WifiText {
                        text: qsTr("Réseau caché")
                        size: 10
                        weight: Font.Medium
                    }

                    WifiText {
                        text: qsTr("Saisissez le nom exact du réseau")
                        size: 8
                        color: Colours.palette.m3onSurfaceVariant
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }
            }

            WifiField {
                id: ssidField
                Layout.fillWidth: true
                icon: "wifi"
                placeholderText: qsTr("Nom du réseau (SSID)")
                onAccepted: root.submit()
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                WifiText {
                    text: qsTr("Réseau sécurisé (WPA/WPA2)")
                    Layout.fillWidth: true
                }

                CompactSwitch {
                    id: secured
                    checked: true
                }
            }

            WifiField {
                id: passwordField
                visible: secured.checked
                Layout.fillWidth: true
                icon: "key"
                placeholderText: qsTr("Mot de passe")
                echoMode: TextInput.Password
                onAccepted: root.submit()
            }

            WifiText {
                visible: root.errorText !== ""
                text: root.errorText
                size: 8.5
                color: Colours.palette.m3error
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            WifiButton {
                Layout.fillWidth: true
                text: qsTr("Se connecter")
                icon: "wifi"
                filled: true
                disabled: !root.valid || Nmcli.connecting
                onClicked: root.submit()
            }
        }
    }
}
