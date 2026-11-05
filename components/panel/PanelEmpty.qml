import QtQuick
import QtQuick.Layouts
import qs.services

// État vide d'une vue : icône et message centrés dans la largeur disponible.
Item {
    id: root

    property string icon
    property string text
    property real iconSize: 24

    Layout.fillWidth: true
    implicitHeight: col.implicitHeight + 36

    ColumnLayout {
        id: col
        anchors.centerIn: parent
        spacing: 8

        PanelIcon {
            visible: root.icon !== ""
            text: root.icon
            size: root.iconSize
            color: Colours.palette.m3onSurfaceVariant
            Layout.alignment: Qt.AlignHCenter
        }

        PanelText {
            text: root.text
            color: Colours.palette.m3onSurfaceVariant
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
