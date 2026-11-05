import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

// Sélecteur de vue du panneau Wi-Fi : une icône par vue, sans texte.
// Se pilote à la souris ou avec les flèches gauche / droite (gérées par Content).
Item {
    id: root

    property int currentIndex
    // Noms d'icônes Material Symbols, un par vue
    property var icons: []

    implicitHeight: 34

    Rectangle {
        id: track
        anchors.centerIn: parent
        implicitWidth: row.implicitWidth + 8
        implicitHeight: 30
        width: implicitWidth
        height: implicitHeight
        radius: height / 2
        color: Colours.tPalette.m3surfaceContainer

        // Pastille de la vue courante
        Rectangle {
            id: pill
            height: parent.height - 6
            width: 44
            radius: height / 2
            y: 3
            x: 4 + root.currentIndex * (width + row.spacing)
            color: Qt.alpha(Colours.palette.m3primary, 0.22)

            Behavior on x {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }
        }

        Row {
            id: row
            x: 4
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Repeater {
                model: root.icons

                delegate: Item {
                    id: tab

                    required property int index
                    required property string modelData

                    width: 44
                    height: track.height - 6

                    StateLayer {
                        anchors.fill: parent
                        radius: height / 2
                        onClicked: root.currentIndex = tab.index
                    }

                    PanelIcon {
                        anchors.centerIn: parent
                        text: tab.modelData
                        size: 14
                        color: root.currentIndex === tab.index ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                    }
                }
            }
        }
    }
}
