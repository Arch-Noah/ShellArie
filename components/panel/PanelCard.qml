import QtQuick
import QtQuick.Layouts
import qs.services

// Carte arrondie qui regroupe des lignes (listes, informations, formulaires).
Rectangle {
    id: root

    default property alias content: col.data
    property alias spacing: col.spacing
    property real padding: 6

    implicitHeight: col.implicitHeight + padding * 2
    radius: 16
    color: Colours.tPalette.m3surfaceContainer

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: root.padding
        spacing: 0
    }
}
