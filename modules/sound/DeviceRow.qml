import QtQuick
import QtQuick.Layouts
import qs.components
import qs.components.panel
import qs.services

// Un périphérique audio : icône, nom, coche s'il est le périphérique par défaut. Un clic le choisit.
Item {
    id: root

    required property var node
    required property bool selected
    required property string icon

    signal chosen

    implicitHeight: row.implicitHeight + 16

    StateLayer {
        anchors.fill: parent
        anchors.margins: 2
        radius: 12
        cursorShape: Qt.PointingHandCursor
        onClicked: root.chosen()
    }

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        anchors.topMargin: 8
        anchors.bottomMargin: 8
        spacing: 10

        Rectangle {
            implicitWidth: 30
            implicitHeight: 30
            radius: 15
            color: root.selected ? Qt.alpha(Colours.palette.m3primary, 0.2) : Qt.alpha(Colours.palette.m3onSurface, 0.08)

            PanelIcon {
                anchors.centerIn: parent
                text: root.icon
                size: 15
                color: root.selected ? Colours.palette.m3primary : Colours.palette.m3onSurface
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            PanelText {
                text: root.node.description || root.node.name
                size: 10
                weight: Font.Medium
                elide: Text.ElideMiddle
                Layout.fillWidth: true
            }

            PanelText {
                visible: root.selected
                text: qsTr("Par défaut")
                size: 8
                color: Colours.palette.m3primary
            }
        }

        PanelIcon {
            visible: root.selected
            text: "check"
            size: 15
            color: Colours.palette.m3primary
        }
    }
}
