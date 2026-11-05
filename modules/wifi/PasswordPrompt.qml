import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

// Champ de mot de passe affiché sous un réseau sécurisé. Le texte saisi est conservé en cas d'erreur.
RowLayout {
    id: root

    signal submitted(string password)

    spacing: 8

    function clear(): void {
        field.text = "";
    }

    function focusField(): void {
        field.forceActiveFocus();
    }

    StyledTextField {
        id: field
        Layout.fillWidth: true
        placeholderText: qsTr("Mot de passe")
        echoMode: TextInput.Password
        onAccepted: if (text.length > 0)
            root.submitted(text)
    }

    TextButton {
        text: qsTr("Connecter")
        type: TextButton.Filled
        disabled: field.text.length === 0 || Nmcli.connecting
        onClicked: root.submitted(field.text)
    }
}
