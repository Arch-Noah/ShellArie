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
        spacing: 2

        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 8
            spacing: 10

            MaterialIcon {
                text: root.signalIcon(root.network.strength)
                fontStyle: Tokens.font.icon.medium
            }

            StyledText {
                text: root.network.ssid
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            StyledText {
                visible: root.connectingThis
                text: qsTr("Connexion…")
                color: Colours.palette.m3onSurfaceVariant
            }

            MaterialIcon {
                visible: root.network.isSecure
                text: "lock"
                color: Colours.palette.m3onSurfaceVariant
            }
        }

        StyledText {
            visible: root.errorText !== ""
            text: root.errorText
            color: Colours.palette.m3error
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            Layout.bottomMargin: 6
        }
    }
}
