pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

// Une ligne de réseau Wi-Fi disponible : signal, SSID, cadenas, état de connexion.
Item {
    id: root

    required property var network
    property string errorText

    readonly property bool connectingThis: Nmcli.connecting && Nmcli.connectingSsid() === network.ssid

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
        radius: Tokens.rounding.small
        disabled: Nmcli.connecting
        onClicked: root.connectRequested()
    }

    ColumnLayout {
        id: layout
        anchors.fill: parent
        spacing: 1

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 6
            Layout.rightMargin: 6
            Layout.topMargin: 4
            Layout.bottomMargin: 4
            spacing: 8

            WifiIcon {
                text: root.signalIcon(root.network.strength)
                size: 14
            }

            WifiText {
                text: root.network.ssid
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            WifiText {
                visible: root.connectingThis
                size: 8
                text: qsTr("Connexion…")
                color: Colours.palette.m3onSurfaceVariant
            }

            WifiIcon {
                visible: root.network.isSecure
                text: "lock"
                size: 11
                color: Colours.palette.m3onSurfaceVariant
            }
        }

        WifiText {
            size: 8
            visible: root.errorText !== ""
            text: root.errorText
            color: Colours.palette.m3error
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.leftMargin: 6
            Layout.rightMargin: 6
            Layout.bottomMargin: 4
        }
    }
}
