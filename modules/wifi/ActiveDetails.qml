import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

// Réseau actif : SSID, signal, sécurité, bouton de déconnexion et détails repliables.
ColumnLayout {
    id: root

    required property var network
    property bool expanded

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

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 8
        Layout.rightMargin: 8
        spacing: 10

        MaterialIcon {
            text: "wifi"
            color: Colours.palette.m3primary
            fontStyle: Tokens.font.icon.medium
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                text: (root.network?.ssid ?? "")
                font: Tokens.font.body.medium
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            StyledText {
                text: qsTr("Connecté") + " · " + (root.network?.strength ?? 0) + "% · " + ((root.network?.isSecure ?? false) ? root.network.security : qsTr("Ouvert"))
                color: Colours.palette.m3onSurfaceVariant
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        IconButton {
            icon: root.expanded ? "expand_less" : "expand_more"
            type: IconButton.Text
            onClicked: root.expanded = !root.expanded
        }
    }

    GridLayout {
        visible: root.expanded
        Layout.fillWidth: true
        Layout.leftMargin: 8
        Layout.rightMargin: 8
        columns: 2
        columnSpacing: 16
        rowSpacing: 4

        StyledText {
            text: qsTr("Adresse IP")
            color: Colours.palette.m3onSurfaceVariant
        }
        StyledText {
            text: root.orDash(root.details?.ipAddress ?? "")
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignRight
        }

        StyledText {
            text: qsTr("Passerelle")
            color: Colours.palette.m3onSurfaceVariant
        }
        StyledText {
            text: root.orDash(root.details?.gateway ?? "")
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignRight
        }

        StyledText {
            text: qsTr("DNS")
            color: Colours.palette.m3onSurfaceVariant
        }
        StyledText {
            text: root.orDash((root.details?.dns ?? []).join(", "))
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignRight
            wrapMode: Text.WordWrap
        }

        StyledText {
            text: qsTr("Adresse MAC")
            color: Colours.palette.m3onSurfaceVariant
        }
        StyledText {
            text: root.orDash(root.details?.macAddress ?? "")
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignRight
        }

        StyledText {
            text: qsTr("Fréquence")
            color: Colours.palette.m3onSurfaceVariant
        }
        StyledText {
            text: root.frequencyText(root.network?.frequency ?? 0)
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignRight
        }
    }

    TextButton {
        visible: root.expanded
        text: qsTr("Déconnecter")
        type: TextButton.Tonal
        Layout.alignment: Qt.AlignRight
        Layout.rightMargin: 8
        onClicked: Nmcli.disconnectFromNetwork()
    }
}
