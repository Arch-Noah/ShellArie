import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs.components.panel
import qs.services

// Vue « Réglages » : nom de l'adaptateur, visibilité, appairage.
ColumnLayout {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property int pairedCount: Bluetooth.devices.values.filter(d => d.paired).length

    spacing: 10

    PanelCard {
        Layout.fillWidth: true

        PanelInfoRow {
            Layout.fillWidth: true
            icon: "bluetooth"
            label: qsTr("Nom")
            value: root.adapter?.name ?? "—"
        }

        PanelDivider {}

        PanelInfoRow {
            Layout.fillWidth: true
            icon: "devices"
            label: qsTr("Appareils appairés")
            value: String(root.pairedCount)
            copyText: ""
        }
    }

    PanelCard {
        Layout.fillWidth: true

        Repeater {
            model: [
                {
                    key: "discoverable",
                    icon: "visibility",
                    title: qsTr("Visible"),
                    sub: qsTr("Visible par les autres appareils")
                },
                {
                    key: "pairable",
                    icon: "link",
                    title: qsTr("Appairable"),
                    sub: qsTr("Accepter les demandes d'appairage")
                }
            ]

            delegate: ColumnLayout {
                id: setting

                required property int index
                required property var modelData

                Layout.fillWidth: true
                spacing: 0

                PanelDivider {
                    visible: setting.index > 0
                }

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

                        PanelIcon {
                            anchors.centerIn: parent
                            text: setting.modelData.icon
                            size: 15
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        PanelText {
                            text: setting.modelData.title
                            size: 10
                            weight: Font.Medium
                        }

                        PanelText {
                            text: setting.modelData.sub
                            size: 8
                            color: Colours.palette.m3onSurfaceVariant
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    PanelSwitch {
                        id: toggle
                        onToggled: if (root.adapter)
                            root.adapter[setting.modelData.key] = checked
                    }

                    Binding {
                        target: toggle
                        property: "checked"
                        value: root.adapter ? root.adapter[setting.modelData.key] : false
                    }
                }
            }
        }
    }
}
