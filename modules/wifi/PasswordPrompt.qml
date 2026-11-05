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
        type: StyledTextField.Filled
        font: Tokens.font.body.builders.small.size(9.5).build()
        verticalPadding: 8
        horizontalPadding: 12
        placeholderText: qsTr("Mot de passe")
        echoMode: TextInput.Password
        onAccepted: if (text.length > 0 && !Nmcli.connecting)
            root.submitted(text)
    }

    WifiButton {
        icon: "arrow_forward"
        filled: true
        disabled: field.text.length === 0 || Nmcli.connecting
        implicitHeight: 34
        onClicked: root.submitted(field.text)
    }
}
