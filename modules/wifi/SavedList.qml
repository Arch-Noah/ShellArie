import qs.components.panel
import QtQuick
import QtQuick.Layouts
import qs.services

// Vue « Enregistrés » : réseaux Wi-Fi mémorisés par NetworkManager.
ColumnLayout {
    id: root

    spacing: 0

    PanelCard {
        Layout.fillWidth: true

        ColumnLayout {
            visible: Nmcli.savedConnectionSsids.length === 0
            Layout.fillWidth: true
            Layout.margins: 18
            spacing: 8

            PanelIcon {
                text: "bookmark"
                size: 22
                color: Colours.palette.m3onSurfaceVariant
                Layout.alignment: Qt.AlignHCenter
            }

            PanelText {
                text: qsTr("Aucun réseau enregistré")
                color: Colours.palette.m3onSurfaceVariant
                Layout.alignment: Qt.AlignHCenter
            }
        }

        Repeater {
            model: Nmcli.savedConnectionSsids

            delegate: ColumnLayout {
                id: item

                required property int index
                required property string modelData

                Layout.fillWidth: true
                spacing: 0

                PanelDivider {
                    visible: item.index > 0
                }

                SavedRow {
                    Layout.fillWidth: true
                    ssid: item.modelData
                }
            }
        }
    }
}
