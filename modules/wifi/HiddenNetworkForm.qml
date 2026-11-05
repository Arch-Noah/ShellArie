import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

// Ajout et connexion à un réseau caché (SSID, sécurité, mot de passe).
ColumnLayout {
    id: root

    property string errorText

    // Émis après une connexion réussie
    signal closed

    spacing: 6

    readonly property bool valid: ssidField.text.trim().length > 0 && (!secured.checked || passwordField.text.length > 0)

    function submit(): void {
        if (!valid || Nmcli.connecting)
            return;
        errorText = "";
        Nmcli.addHiddenNetwork(ssidField.text.trim(), passwordField.text, secured.checked ? "wpa-psk" : "none", true, result => {
            if (result.success)
                root.closed();
            else
                root.errorText = result.error || qsTr("Échec de la connexion");
        });
    }

    StyledTextField {
        id: ssidField
        Layout.fillWidth: true
        font: Tokens.font.body.builders.small.size(9).build()
        verticalPadding: 5
        horizontalPadding: 8
        placeholderText: qsTr("Nom du réseau (SSID)")
        onAccepted: root.submit()
    }

    RowLayout {
        Layout.fillWidth: true

        WifiText {
            text: qsTr("Réseau sécurisé (WPA/WPA2)")
            Layout.fillWidth: true
        }

        CompactSwitch {
            id: secured
            checked: true
        }
    }

    StyledTextField {
        id: passwordField
        visible: secured.checked
        Layout.fillWidth: true
        font: Tokens.font.body.builders.small.size(9).build()
        verticalPadding: 5
        horizontalPadding: 8
        placeholderText: qsTr("Mot de passe")
        echoMode: TextInput.Password
        onAccepted: root.submit()
    }

    WifiText {
        size: 8
        visible: root.errorText !== ""
        text: root.errorText
        color: Colours.palette.m3error
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Item {
            Layout.fillWidth: true
        }

        TextButton {
            text: qsTr("Connecter")
            type: TextButton.Filled
            font: Tokens.font.body.builders.small.size(9).build()
            horizontalPadding: 8
            verticalPadding: 3
            disabled: !root.valid || Nmcli.connecting
            onClicked: root.submit()
        }
    }
}
