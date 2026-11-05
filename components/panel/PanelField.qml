import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

// Champ de saisie du panneau Wi-Fi : fond arrondi, hauteur confortable, liseré au focus.
Rectangle {
    id: root

    property alias text: input.text
    property string placeholderText
    property int echoMode: TextInput.Normal
    property string icon

    signal accepted

    function focusField(): void {
        input.forceActiveFocus();
    }

    implicitHeight: 40
    radius: 12
    color: Qt.alpha(Colours.palette.m3onSurface, input.activeFocus ? 0.12 : 0.08)
    border.width: input.activeFocus ? 1.5 : 0
    border.color: Colours.palette.m3primary

    // Un clic n'importe où dans le champ donne le focus à la saisie
    TapHandler {
        onTapped: input.forceActiveFocus()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 8

        PanelIcon {
            visible: root.icon !== ""
            text: root.icon
            size: 14
            color: input.activeFocus ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
        }

        TextInput {
            id: input
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            font: Tokens.font.body.builders.small.size(9.5).build()
            color: Colours.palette.m3onSurface
            selectionColor: Qt.alpha(Colours.palette.m3primary, 0.4)
            selectedTextColor: color
            echoMode: root.echoMode
            passwordCharacter: "•"
            selectByMouse: true
            clip: true
            onAccepted: root.accepted()

            PanelText {
                anchors.verticalCenter: parent.verticalCenter
                visible: input.text.length === 0 && input.preeditText.length === 0
                text: root.placeholderText
                size: 9.5
                color: Colours.palette.m3onSurfaceVariant
            }
        }
    }
}
