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

        PanelEmpty {
            visible: Nmcli.savedConnectionSsids.length === 0
            icon: "bookmark"
            text: qsTr("Aucun réseau enregistré")
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
