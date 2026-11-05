import qs.components.panel
import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

// Un réseau enregistré : connexion automatique et oubli (avec confirmation).
ColumnLayout {
    id: root

    required property string ssid

    // Le nom de la connexion NetworkManager peut différer du SSID (ex. « Hotspot » → « archnoah »)
    readonly property string connectionName: Nmcli.savedConnectionNameBySsid[ssid.toLowerCase().trim()] ?? ssid
    readonly property bool isActive: (Nmcli.active?.ssid ?? "") === ssid

    property bool autoconnect: true
    property bool confirmingForget
    property string errorText

    spacing: 0

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
        Layout.leftMargin: 10
        Layout.rightMargin: 10
        Layout.topMargin: 8
        Layout.bottomMargin: 8
        spacing: 10

        Rectangle {
            implicitWidth: 30
            implicitHeight: 30
            radius: 15
            color: root.isActive ? Qt.alpha(Colours.palette.m3primary, 0.2) : Qt.alpha(Colours.palette.m3onSurface, 0.08)

            PanelIcon {
                anchors.centerIn: parent
                text: root.isActive ? "wifi" : "bookmark"
                size: 15
                color: root.isActive ? Colours.palette.m3primary : Colours.palette.m3onSurface
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            PanelText {
                text: root.ssid
                size: 10
                weight: Font.Medium
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            PanelText {
                text: root.isActive ? qsTr("Connecté") : (root.autoconnect ? qsTr("Connexion automatique") : qsTr("Connexion manuelle"))
                size: 8
                color: root.isActive ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        PanelSwitch {
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

        PanelButton {
            visible: !root.confirmingForget
            icon: "delete"
            tint: Colours.palette.m3error
            onClicked: root.confirmingForget = true
        }

        PanelButton {
            visible: root.confirmingForget
            text: qsTr("Oublier")
            tint: Colours.palette.m3error
            onTint: Colours.palette.m3onError
            filled: true
            textSize: 8.5
            implicitHeight: 28
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

        PanelButton {
            visible: root.confirmingForget
            text: qsTr("Annuler")
            tint: Colours.palette.m3onSurfaceVariant
            textSize: 8.5
            implicitHeight: 28
            onClicked: root.confirmingForget = false
        }
    }

    PanelText {
        visible: root.errorText !== ""
        text: root.errorText
        size: 8.5
        color: Colours.palette.m3error
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        Layout.leftMargin: 50
        Layout.rightMargin: 10
        Layout.bottomMargin: 8
    }
}
