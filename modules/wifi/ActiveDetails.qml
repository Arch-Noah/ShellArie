import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

// Vue « Connecté » : réseau actif, ses informations et le bouton de déconnexion.
ColumnLayout {
    id: root

    // Réseau actif (AccessPoint) ou null
    property var network

    readonly property var details: Nmcli.wirelessDeviceDetails

    spacing: 4

    // Numéro de canal à partir de la fréquence en MHz (0 si inconnue)
    function channelFor(freq: int): int {
        if (freq === 2484)
            return 14;
        if (freq >= 2412 && freq <= 2472)
            return (freq - 2407) / 5;
        if (freq >= 5000 && freq <= 5900)
            return (freq - 5000) / 5;
        return 0;
    }

    function frequencyText(freq: int): string {
        if (!freq)
            return "—";
        const ch = channelFor(freq);
        return freq + " MHz" + (ch > 0 ? " (" + qsTr("canal") + " " + ch + ")" : "");
    }

    function orDash(value: string): string {
        return value && value.length > 0 ? value : "—";
    }

    WifiText {
        visible: !root.network
        text: qsTr("Aucun réseau connecté")
        color: Colours.palette.m3onSurfaceVariant
        Layout.fillWidth: true
        Layout.margins: 6
    }

    RowLayout {
        visible: !!root.network
        Layout.fillWidth: true
        Layout.leftMargin: 6
        Layout.rightMargin: 6
        spacing: 8

        WifiIcon {
            text: "wifi"
            color: Colours.palette.m3primary
            size: 14
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            WifiText {
                text: (root.network?.ssid ?? "")
                size: 10
                weight: Font.Medium
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            WifiText {
                text: qsTr("Connecté") + " · " + (root.network?.strength ?? 0) + "% · " + ((root.network?.isSecure ?? false) ? root.network.security : qsTr("Ouvert"))
                color: Colours.palette.m3onSurfaceVariant
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }
    }

    GridLayout {
        visible: !!root.network
        Layout.fillWidth: true
        Layout.leftMargin: 6
        Layout.rightMargin: 6
        columns: 2
        columnSpacing: 12
        rowSpacing: 3

        WifiText {
            size: 8
            text: qsTr("Adresse IP")
            color: Colours.palette.m3onSurfaceVariant
        }
        WifiText {
            text: root.orDash(root.details?.ipAddress ?? "")
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignRight
        }

        WifiText {
            size: 8
            text: qsTr("Passerelle")
            color: Colours.palette.m3onSurfaceVariant
        }
        WifiText {
            text: root.orDash(root.details?.gateway ?? "")
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignRight
        }

        WifiText {
            size: 8
            text: qsTr("DNS")
            color: Colours.palette.m3onSurfaceVariant
        }
        WifiText {
            text: root.orDash((root.details?.dns ?? []).join(", "))
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignRight
            wrapMode: Text.WordWrap
        }

        WifiText {
            size: 8
            text: qsTr("Adresse MAC")
            color: Colours.palette.m3onSurfaceVariant
        }
        WifiText {
            text: root.orDash(root.details?.macAddress ?? "")
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignRight
        }

        WifiText {
            size: 8
            text: qsTr("Fréquence")
            color: Colours.palette.m3onSurfaceVariant
        }
        WifiText {
            text: root.frequencyText(root.network?.frequency ?? 0)
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignRight
        }
    }

    TextButton {
        visible: !!root.network
        text: qsTr("Déconnecter")
        type: TextButton.Tonal
        font: Tokens.font.body.builders.small.size(9).build()
        horizontalPadding: 8
        verticalPadding: 3
        Layout.alignment: Qt.AlignRight
        Layout.rightMargin: 6
        onClicked: Nmcli.disconnectFromNetwork()
    }
}
