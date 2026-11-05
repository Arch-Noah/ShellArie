import QtQuick
import QtQuick.Layouts
import qs.services

// Vue « Enregistrés » : réseaux Wi-Fi mémorisés par NetworkManager.
ColumnLayout {
    id: root

    spacing: 0

    WifiText {
        visible: Nmcli.savedConnectionSsids.length === 0
        text: qsTr("Aucun réseau enregistré")
        color: Colours.palette.m3onSurfaceVariant
        Layout.fillWidth: true
        Layout.margins: 6
    }

    Repeater {
        model: Nmcli.savedConnectionSsids

        delegate: SavedRow {
            required property string modelData

            ssid: modelData
            Layout.fillWidth: true
        }
    }
}
