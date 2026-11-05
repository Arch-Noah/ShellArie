import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import qs.components
import qs.components.panel
import qs.services
import "deviceIcon.js" as DeviceIcon

// Vue « Connecté » : une carte par appareil connecté (infos copiables, déconnexion).
ColumnLayout {
    id: root

    readonly property var connected: Bluetooth.devices.values.filter(d => d.connected)

    spacing: 10

    // --- Aucun appareil ---
    PanelEmpty {
        visible: root.connected.length === 0
        icon: "bluetooth_disabled"
        text: qsTr("Aucun appareil connecté")
        iconSize: 26
    }

    Repeater {
        model: root.connected

        delegate: ColumnLayout {
            id: card

            required property var modelData

            property bool nameCopied

            Layout.fillWidth: true
            spacing: 10

            function copyName(): void {
                Quickshell.execDetached(["wl-copy", "--", modelData.name]);
                nameCopied = true;
                nameTimer.restart();
            }

            Timer {
                id: nameTimer
                interval: 1400
                onTriggered: card.nameCopied = false
            }

            // --- Carte de l'appareil (un clic copie son nom) ---
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: hero.implicitHeight + 28
                radius: 16
                color: Qt.alpha(Colours.palette.m3primary, 0.12)

                StateLayer {
                    anchors.fill: parent
                    radius: parent.radius
                    cursorShape: Qt.PointingHandCursor
                    onClicked: card.copyName()
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
                                text: DeviceIcon.deviceIcon(card.modelData.icon)
                                size: 22
                                color: Colours.palette.m3primary
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            PanelText {
                                text: card.modelData.name
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
                                    text: card.nameCopied ? qsTr("Nom copié") : qsTr("Connecté")
                                    size: 8.5
                                    color: Colours.palette.m3primary
                                }
                            }
                        }
                    }

                    Flow {
                        Layout.fillWidth: true
                        spacing: 6

                        Repeater {
                            model: [card.modelData.batteryAvailable ? qsTr("Batterie") + " " + Math.round(card.modelData.battery * 100) + " %" : "", card.modelData.paired ? qsTr("Appairé") : "", card.modelData.trusted ? qsTr("De confiance") : ""].filter(t => t.length > 0)

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

            // --- Informations (un clic copie la valeur) ---
            PanelCard {
                Layout.fillWidth: true

                PanelInfoRow {
                    Layout.fillWidth: true
                    icon: "tag"
                    label: qsTr("Adresse")
                    value: card.modelData.address
                }

                PanelDivider {}

                PanelInfoRow {
                    Layout.fillWidth: true
                    icon: "link"
                    label: qsTr("Appairé")
                    value: card.modelData.paired ? qsTr("Oui") : qsTr("Non")
                    copyText: ""
                }

                PanelDivider {}

                PanelInfoRow {
                    Layout.fillWidth: true
                    icon: "verified_user"
                    label: qsTr("De confiance")
                    value: card.modelData.trusted ? qsTr("Oui") : qsTr("Non")
                    copyText: ""
                }
            }

            PanelButton {
                Layout.fillWidth: true
                text: qsTr("Se déconnecter")
                icon: "link_off"
                tint: Colours.palette.m3error
                onClicked: card.modelData.disconnect()
            }
        }
    }
}
