pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

// Une ligne de réseau disponible : signal, nom, sécurité, état de connexion.
Item {
    id: root

    required property var network
    property string errorText

    readonly property bool connectingThis: Nmcli.connecting && Nmcli.connectingSsid() === network.ssid
    readonly property bool known: Nmcli.hasSavedProfile(network.ssid)

    signal connectRequested

    implicitHeight: layout.implicitHeight

    function signalIcon(strength: int): string {
        if (strength > 75)
            return "wifi";
        if (strength > 50)
            return "network_wifi_3_bar";
        if (strength > 25)
            return "network_wifi_2_bar";
        return "network_wifi_1_bar";
    }

    StateLayer {
        anchors.fill: parent
        anchors.margins: 2
        radius: 12
        disabled: Nmcli.connecting
        cursorShape: Qt.PointingHandCursor
        onClicked: root.connectRequested()
    }

    ColumnLayout {
        id: layout
        anchors.fill: parent
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 10
            Layout.rightMargin: 10
            Layout.topMargin: 8
            Layout.bottomMargin: 8
            spacing: 10

            Rectangle {
                implicitWidth: 30
                implicitHeight: 30
                radius: 15
                color: Qt.alpha(Colours.palette.m3onSurface, 0.08)

                WifiIcon {
                    anchors.centerIn: parent
                    text: root.signalIcon(root.network.strength)
                    size: 15
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                WifiText {
                    text: root.network.ssid
                    size: 10
                    weight: Font.Medium
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                WifiText {
                    text: (root.network.isSecure ? root.network.security : qsTr("Ouvert")) + " · " + Math.round(root.network.strength) + " %" + (root.known ? " · " + qsTr("Enregistré") : "")
                    size: 8
                    color: Colours.palette.m3onSurfaceVariant
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            WifiText {
                visible: root.connectingThis
                text: qsTr("Connexion…")
                size: 8.5
                color: Colours.palette.m3primary
            }

            WifiIcon {
                visible: root.network.isSecure && !root.connectingThis
                text: "lock"
                size: 13
                color: Colours.palette.m3onSurfaceVariant
            }
        }

        WifiText {
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
}
