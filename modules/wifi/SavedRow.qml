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

    spacing: 2

    Component.onCompleted: Nmcli.getAutoconnect(connectionName, value => root.autoconnect = value)
    onConnectionNameChanged: Nmcli.getAutoconnect(connectionName, value => root.autoconnect = value)

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 8
        Layout.rightMargin: 8
        spacing: 10

        StyledText {
            text: root.ssid
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        StyledText {
            visible: !root.confirmingForget
            text: qsTr("Auto")
            color: Colours.palette.m3onSurfaceVariant
        }

        StyledSwitch {
            visible: !root.confirmingForget
            checked: root.autoconnect
            onToggled: {
                const wanted = checked;
                root.errorText = "";
                Nmcli.setAutoconnect(root.connectionName, wanted, result => {
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
            onClicked: root.confirmingForget = true
        }

        TextButton {
            visible: root.confirmingForget
            text: qsTr("Oublier")
            type: TextButton.Filled
            onClicked: {
                root.errorText = "";
                Nmcli.forgetNetwork(root.ssid, result => {
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
            onClicked: root.confirmingForget = false
        }
    }

    StyledText {
        visible: root.errorText !== ""
        text: root.errorText
        color: Colours.palette.m3error
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        Layout.leftMargin: 8
        Layout.rightMargin: 8
    }
}
