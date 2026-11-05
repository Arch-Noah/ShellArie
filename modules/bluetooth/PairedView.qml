import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs.components.panel
import qs.services

// Vue « Appairés » : appareils mémorisés, connectés en premier.
ColumnLayout {
    id: root

    // Modèle du Repeater : remplacé seulement si la liste d'adresses change (ordre compris),
    // pour ne pas détruire l'état d'une ligne (confirmation d'oubli) à chaque mise à jour.
    readonly property var pairedRaw: {
        const list = Bluetooth.devices.values.filter(d => d.paired);
        list.sort((a, b) => (b.connected ? 1 : 0) - (a.connected ? 1 : 0) || a.name.localeCompare(b.name));
        return list;
    }
    property var paired: []
    property string pairedKey

    onPairedRawChanged: {
        const key = pairedRaw.map(d => d.address).join(",");
        if (key !== pairedKey) {
            pairedKey = key;
            paired = pairedRaw;
        }
    }

    Component.onCompleted: pairedRawChanged()

    spacing: 0

    PanelCard {
        Layout.fillWidth: true

        PanelEmpty {
            visible: root.paired.length === 0
            icon: "devices"
            text: qsTr("Aucun appareil appairé")
        }

        Repeater {
            model: root.paired

            delegate: ColumnLayout {
                id: item

                required property int index
                required property var modelData

                Layout.fillWidth: true
                spacing: 0

                PanelDivider {
                    visible: item.index > 0
                }

                PairedRow {
                    Layout.fillWidth: true
                    device: item.modelData
                }
            }
        }
    }
}
