import qs.components.panel
import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.services

// Vue « Connecté » : carte du réseau actif, informations de connexion, déconnexion.
ColumnLayout {
    id: root

    // Réseau actif (AccessPoint) ou null
    property var network

    readonly property var details: Nmcli.wirelessDeviceDetails
    readonly property real strength: root.network?.strength ?? 0

    spacing: 10

    property bool ssidCopied

    function copySsid(): void {
        if (!root.network)
            return;
        Quickshell.execDetached(["wl-copy", "--", root.network.ssid]);
        ssidCopied = true;
        ssidTimer.restart();
    }

    Timer {
        id: ssidTimer
        interval: 1400
        onTriggered: root.ssidCopied = false
    }

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

    function bandText(freq: int): string {
        if (freq >= 5925)
            return "6 GHz";
        if (freq >= 4900)
            return "5 GHz";
        if (freq >= 2400)
            return "2,4 GHz";
        return "";
    }

    function frequencyText(freq: int): string {
        if (!freq)
            return "—";
        const ch = channelFor(freq);
        return freq + " MHz" + (ch > 0 ? " · " + qsTr("canal") + " " + ch : "");
    }

    function orDash(value: string): string {
        return value && value.length > 0 ? value : "—";
    }

    function signalIcon(strength: int): string {
        if (strength > 75)
            return "wifi";
        if (strength > 50)
            return "network_wifi_3_bar";
        if (strength > 25)
            return "network_wifi_2_bar";
        return "network_wifi_1_bar";
    }

    // --- Aucun réseau ---
    ColumnLayout {
        visible: !root.network
        Layout.fillWidth: true
        Layout.topMargin: 18
        Layout.bottomMargin: 18
        spacing: 8

        PanelIcon {
            text: "wifi_off"
            size: 26
            color: Colours.palette.m3onSurfaceVariant
            Layout.alignment: Qt.AlignHCenter
        }

        PanelText {
            text: qsTr("Aucun réseau connecté")
            color: Colours.palette.m3onSurfaceVariant
            Layout.alignment: Qt.AlignHCenter
        }
    }

    // --- Carte du réseau actif ---
    Rectangle {
        visible: !!root.network
        Layout.fillWidth: true
        implicitHeight: hero.implicitHeight + 28
        radius: 16
        color: Qt.alpha(Colours.palette.m3primary, 0.12)

        // Un clic sur la carte copie le nom du réseau
        StateLayer {
            anchors.fill: parent
            radius: parent.radius
            cursorShape: Qt.PointingHandCursor
            onClicked: root.copySsid()
        }

        ColumnLayout {
            id: hero
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Rectangle {
                    implicitWidth: 44
                    implicitHeight: 44
                    radius: 22
                    color: Qt.alpha(Colours.palette.m3primary, 0.2)

                    PanelIcon {
                        anchors.centerIn: parent
                        text: root.signalIcon(root.strength)
                        size: 22
                        color: Colours.palette.m3primary
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    PanelText {
                        text: root.network?.ssid ?? ""
                        size: 12
                        weight: Font.DemiBold
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        spacing: 5

                        Rectangle {
                            implicitWidth: 6
                            implicitHeight: 6
                            radius: 3
                            color: Colours.palette.m3primary
                        }

                        PanelText {
                            text: root.ssidCopied ? qsTr("Nom copié") : qsTr("Connecté")
                            size: 8.5
                            color: Colours.palette.m3primary
                        }
                    }
                }
            }

            // Pastilles : signal, sécurité, bande
            Flow {
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: [Math.round(root.strength) + " %", (root.network?.isSecure ?? false) ? root.network.security : qsTr("Ouvert"), root.bandText(root.network?.frequency ?? 0)].filter(t => t && t.length > 0)

                    delegate: Rectangle {
                        required property string modelData

                        implicitWidth: chip.implicitWidth + 16
                        implicitHeight: chip.implicitHeight + 8
                        radius: height / 2
                        color: Qt.alpha(Colours.palette.m3onSurface, 0.08)

                        PanelText {
                            id: chip
                            anchors.centerIn: parent
                            text: parent.modelData
                            size: 8.5
                        }
                    }
                }
            }
        }
    }

    // --- Informations de connexion (un clic copie la valeur) ---
    PanelCard {
        visible: !!root.network
        Layout.fillWidth: true

        Repeater {
            model: [
                {
                    icon: "lan",
                    label: qsTr("Adresse IP"),
                    value: root.orDash(root.details?.ipAddress ?? "")
                },
                {
                    icon: "router",
                    label: qsTr("Passerelle"),
                    value: root.orDash(root.details?.gateway ?? "")
                },
                {
                    icon: "dns",
                    label: qsTr("DNS"),
                    value: root.orDash((root.details?.dns ?? []).join(", "))
                },
                {
                    icon: "tag",
                    label: qsTr("Adresse MAC"),
                    value: root.orDash(root.details?.macAddress ?? "")
                },
                {
                    icon: "settings_input_antenna",
                    label: qsTr("Fréquence"),
                    value: root.frequencyText(root.network?.frequency ?? 0)
                }
            ]

            delegate: ColumnLayout {
                id: line

                required property int index
                required property var modelData

                Layout.fillWidth: true
                spacing: 0

                PanelDivider {
                    visible: line.index > 0
                }

                PanelInfoRow {
                    Layout.fillWidth: true
                    icon: line.modelData.icon
                    label: line.modelData.label
                    value: line.modelData.value
                }
            }
        }
    }

    // --- Déconnexion ---
    PanelButton {
        visible: !!root.network
        Layout.fillWidth: true
        text: qsTr("Se déconnecter")
        icon: "link_off"
        tint: Colours.palette.m3error
        onClicked: Nmcli.disconnectFromNetwork()
    }
}
