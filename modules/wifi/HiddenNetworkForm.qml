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

    signal closed

    spacing: 8

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
        placeholderText: qsTr("Nom du réseau (SSID)")
        onAccepted: root.submit()
    }

    RowLayout {
        Layout.fillWidth: true

        StyledText {
            text: qsTr("Réseau sécurisé (WPA/WPA2)")
            Layout.fillWidth: true
        }

        StyledSwitch {
            id: secured
            checked: true
        }
    }

    StyledTextField {
        id: passwordField
        visible: secured.checked
        Layout.fillWidth: true
        placeholderText: qsTr("Mot de passe")
        echoMode: TextInput.Password
        onAccepted: root.submit()
    }

    StyledText {
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
            text: qsTr("Annuler")
            type: TextButton.Text
            onClicked: root.closed()
        }

        TextButton {
            text: qsTr("Connecter")
            type: TextButton.Filled
            disabled: !root.valid || Nmcli.connecting
            onClicked: root.submit()
        }
    }
}
