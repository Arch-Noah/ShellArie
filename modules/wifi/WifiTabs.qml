import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

// Barre d'onglets du panneau Wi-Fi : une vue à la fois.
RowLayout {
    id: root

    property int currentIndex
    property var tabs: []

    spacing: 0

    Repeater {
        model: root.tabs

        delegate: Item {
            id: tab

            required property int index
            required property string modelData

            readonly property bool selected: root.currentIndex === index

            Layout.fillWidth: true
            implicitHeight: label.implicitHeight + 10

            StateLayer {
                anchors.fill: parent
                radius: 6
                onClicked: root.currentIndex = tab.index
            }

            WifiText {
                id: label
                anchors.centerIn: parent
                text: tab.modelData
                size: 9
                weight: tab.selected ? Font.Medium : Font.Normal
                color: tab.selected ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                width: parent.width * 0.6
                height: 2
                radius: 1
                color: Colours.palette.m3primary
                visible: tab.selected
            }
        }
    }
}
