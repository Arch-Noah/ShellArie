import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

// Un réseau enregistré : connexion automatique et oubli (avec confirmation).
ColumnLayout {
    id: root

    required property string ssid

    // Le nom de la connexion NetworkManager peut différer du SSID (ex. « Hotspot » → « archnoah »)
    readonly property string connectionName: Nmcli.savedConnectionNameBySsid[ssid.toLowerCase().trim()] ?? ssid

    property bool autoconnect: true
    property bool confirmingForget
    property string errorText

    spacing: 1

    // La ligne peut être détruite (liste rechargée) avant la réponse de nmcli
    function refreshAutoconnect(): void {
        Nmcli.getAutoconnect(connectionName, value => {
            if (root)
                root.autoconnect = value;
        });
    }

    Component.onCompleted: refreshAutoconnect()
    onConnectionNameChanged: refreshAutoconnect()

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 6
        Layout.rightMargin: 6
        spacing: 6

        WifiText {
            text: root.ssid
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        WifiText {
            visible: !root.confirmingForget
            size: 8
            text: qsTr("Auto")
            color: Colours.palette.m3onSurfaceVariant
        }

        CompactSwitch {
            visible: !root.confirmingForget
            checked: root.autoconnect
            onToggled: {
                const wanted = checked;
                root.errorText = "";
                Nmcli.setAutoconnect(root.connectionName, wanted, result => {
                    if (!root)
                        return;
                    if (result.success) {
                        root.autoconnect = wanted;
                    } else {
                        // On remet l'interrupteur à sa valeur précédente
                        checked = root.autoconnect;
                        root.errorText = result.error || qsTr("Impossible de modifier la connexion automatique");
                    }
                });
            }
        }

        IconButton {
            visible: !root.confirmingForget
            icon: "delete"
            type: IconButton.Text
            font: Tokens.font.icon.builders.medium.size(13).build()
            onClicked: root.confirmingForget = true
        }

        TextButton {
            visible: root.confirmingForget
            text: qsTr("Oublier")
            type: TextButton.Filled
            font: Tokens.font.body.builders.small.size(9).build()
            horizontalPadding: 8
            verticalPadding: 3
            onClicked: {
                root.errorText = "";
                Nmcli.forgetNetwork(root.ssid, result => {
                    if (!root)
                        return;
                    root.confirmingForget = false;
                    if (!result.success)
                        root.errorText = result.error || qsTr("Impossible d'oublier le réseau");
                });
            }
        }

        TextButton {
            visible: root.confirmingForget
            text: qsTr("Annuler")
            type: TextButton.Text
            font: Tokens.font.body.builders.small.size(9).build()
            horizontalPadding: 8
            verticalPadding: 3
            onClicked: root.confirmingForget = false
        }
    }

    WifiText {
        size: 8
        visible: root.errorText !== ""
        text: root.errorText
        color: Colours.palette.m3error
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        Layout.leftMargin: 6
        Layout.rightMargin: 6
    }
}
