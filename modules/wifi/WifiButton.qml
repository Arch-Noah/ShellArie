import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

// Bouton du panneau Wi-Fi : plein (filled) ou teinté, avec icône optionnelle.
Rectangle {
    id: root

    property string text
    property string icon
    property color tint: Colours.palette.m3primary
    property color onTint: Colours.palette.m3onPrimary
    property bool filled
    property bool disabled
    property real textSize: 9.5

    signal clicked

    implicitWidth: row.implicitWidth + (text !== "" ? 28 : 18)
    implicitHeight: text !== "" ? 34 : 30
    radius: 12
    color: filled ? tint : Qt.alpha(tint, 0.14)
    opacity: disabled ? 0.4 : 1

    StateLayer {
        anchors.fill: parent
        radius: root.radius
        disabled: root.disabled
        onClicked: root.clicked()
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 7

        WifiIcon {
            visible: root.icon !== ""
            text: root.icon
            size: 15
            color: root.filled ? root.onTint : root.tint
        }

        WifiText {
            visible: root.text !== ""
            text: root.text
            size: root.textSize
            weight: Font.Medium
            color: root.filled ? root.onTint : root.tint
        }
    }
}
