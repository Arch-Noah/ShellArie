import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs.components
import qs.components.panel
import qs.services
import "deviceIcon.js" as DeviceIcon

// Un appareil détecté : clic = appairer, puis faire confiance et connecter.
ColumnLayout {
    id: root

    required property var device

    readonly property bool unnamed: DeviceIcon.isAddressName(device.name)
    readonly property bool working: attempting && (device.pairing || device.paired)

    property bool attempting
    property string errorText

    // Appairage terminé (réussi ou non) : la vue peut retirer la ligne
    signal finished

    spacing: 0

    function pairNow(): void {
        if (root.attempting || device.pairing)
            return;
        errorText = "";
        attempting = true;
        device.pair();
    }

    // Appairage réussi : confiance puis connexion
    Connections {
        target: root.device

        function onPairedChanged(): void {
            if (root.attempting && root.device.paired) {
                root.device.trusted = true;
                root.device.connect();
                root.attempting = false;
                root.finished();
            }
        }

        function onPairingChanged(): void {
            if (root.attempting && !root.device.pairing && !root.device.paired) {
                root.attempting = false;
                root.errorText = qsTr("Échec de l'appairage");
            }
        }
    }

    Item {
        Layout.fillWidth: true
        implicitHeight: row.implicitHeight + 16

        StateLayer {
            anchors.fill: parent
            anchors.margins: 2
            radius: 12
            disabled: root.attempting
            cursorShape: Qt.PointingHandCursor
            onClicked: root.pairNow()
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
                color: Qt.alpha(Colours.palette.m3onSurface, 0.08)

                PanelIcon {
                    anchors.centerIn: parent
                    text: DeviceIcon.deviceIcon(root.device.icon)
                    size: 15
                    color: root.unnamed ? Colours.palette.m3onSurfaceVariant : Colours.palette.m3onSurface
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                PanelText {
                    text: root.device.name
                    size: 10
                    weight: Font.Medium
                    color: root.unnamed ? Colours.palette.m3onSurfaceVariant : Colours.palette.m3onSurface
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                PanelText {
                    text: root.attempting ? qsTr("Appairage…") : (root.unnamed ? qsTr("Appareil sans nom") : root.device.address)
                    size: 8
                    color: root.attempting ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            PanelIcon {
                visible: !root.attempting
                text: "add_link"
                size: 14
                color: Colours.palette.m3onSurfaceVariant
            }
        }
    }

    PanelText {
        visible: root.errorText !== ""
        text: root.errorText
        size: 8.5
        color: Colours.palette.m3error
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        Layout.leftMargin: 50
        Layout.rightMargin: 10
        Layout.bottomMargin: 8
    }
}
