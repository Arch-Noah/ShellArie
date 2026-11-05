import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs.components
import qs.components.panel
import qs.services
import "deviceIcon.js" as DeviceIcon

// Un appareil appairé : clic = connecter / déconnecter, confiance, oubli avec confirmation.
ColumnLayout {
    id: root

    required property var device

    readonly property string stateName: BluetoothDeviceState.toString(device.state)
    readonly property bool busy: stateName === "Connecting" || stateName === "Disconnecting"

    property bool confirmingForget

    spacing: 0

    function subtitle(): string {
        if (root.stateName === "Connecting")
            return qsTr("Connexion…");
        if (root.stateName === "Disconnecting")
            return qsTr("Déconnexion…");
        if (device.connected)
            return device.batteryAvailable ? qsTr("Connecté") + " · " + Math.round(device.battery * 100) + " %" : qsTr("Connecté");
        return qsTr("Appairé");
    }

    Item {
        Layout.fillWidth: true
        implicitHeight: row.implicitHeight + 16

        StateLayer {
            anchors.fill: parent
            anchors.margins: 2
            radius: 12
            disabled: root.busy || root.confirmingForget
            cursorShape: Qt.PointingHandCursor
            onClicked: root.device.connected ? root.device.disconnect() : root.device.connect()
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
                color: root.device.connected ? Qt.alpha(Colours.palette.m3primary, 0.2) : Qt.alpha(Colours.palette.m3onSurface, 0.08)

                PanelIcon {
                    anchors.centerIn: parent
                    text: DeviceIcon.deviceIcon(root.device.icon)
                    size: 15
                    color: root.device.connected ? Colours.palette.m3primary : Colours.palette.m3onSurface
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                PanelText {
                    text: root.device.name
                    size: 10
                    weight: Font.Medium
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                PanelText {
                    text: root.subtitle()
                    size: 8
                    color: root.device.connected ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            PanelSwitch {
                id: trust
                visible: !root.confirmingForget
                onToggled: root.device.trusted = checked
            }

            Binding {
                target: trust
                property: "checked"
                value: root.device.trusted
            }

            PanelButton {
                visible: !root.confirmingForget
                icon: "delete"
                tint: Colours.palette.m3error
                onClicked: root.confirmingForget = true
            }

            PanelButton {
                visible: root.confirmingForget
                text: qsTr("Oublier")
                tint: Colours.palette.m3error
                onTint: Colours.palette.m3onError
                filled: true
                textSize: 8.5
                implicitHeight: 28
                onClicked: root.device.forget()
            }

            PanelButton {
                visible: root.confirmingForget
                text: qsTr("Annuler")
                tint: Colours.palette.m3onSurfaceVariant
                textSize: 8.5
                implicitHeight: 28
                onClicked: root.confirmingForget = false
            }
        }
    }
}
