import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs.components.panel
import qs.services
import "deviceIcon.js" as DeviceIcon

// Vue « Découverte » : le scan tourne tant que la vue est affichée.
ColumnLayout {
    id: root

    // Adresses en cours d'appairage : la ligne reste affichée jusqu'à la fin (confiance + connexion)
    property var pending: ({})

    // Appareils non appairés (ou en cours d'appairage), nommés d'abord
    readonly property var foundRaw: {
        const list = Bluetooth.devices.values.filter(d => !d.paired || root.pending[d.address]);
        list.sort((a, b) => (DeviceIcon.isAddressName(a.name) ? 1 : 0) - (DeviceIcon.isAddressName(b.name) ? 1 : 0) || a.name.localeCompare(b.name));
        return list;
    }
    property var found: []
    property string foundKey

    onFoundRawChanged: {
        const key = foundRaw.map(d => d.address).join(",");
        if (key !== foundKey) {
            foundKey = key;
            found = foundRaw;
        }
    }

    function setPending(address: string, value: bool): void {
        const copy = Object.assign({}, pending);
        if (value)
            copy[address] = true;
        else
            delete copy[address];
        pending = copy;
    }

    Component.onCompleted: {
        foundRawChanged();
        if (Bluetooth.defaultAdapter)
            Bluetooth.defaultAdapter.discovering = true;
    }

    // Quitter la vue ou fermer le panneau arrête le scan
    Component.onDestruction: {
        if (Bluetooth.defaultAdapter)
            Bluetooth.defaultAdapter.discovering = false;
    }

    spacing: 0

    PanelCard {
        Layout.fillWidth: true

        PanelEmpty {
            visible: root.found.length === 0
            icon: "bluetooth_searching"
            text: Bluetooth.defaultAdapter?.discovering ? qsTr("Recherche en cours…") : qsTr("Aucun appareil trouvé")
        }

        Repeater {
            model: root.found

            delegate: ColumnLayout {
                id: item

                required property int index
                required property var modelData

                Layout.fillWidth: true
                spacing: 0

                PanelDivider {
                    visible: item.index > 0
                }

                DiscoveryRow {
                    Layout.fillWidth: true
                    device: item.modelData
                    onAttemptingChanged: root.setPending(item.modelData.address, attempting)
                    onFinished: root.setPending(item.modelData.address, false)
                }
            }
        }
    }
}
