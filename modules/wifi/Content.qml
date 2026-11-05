pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

// Contenu du panneau Wi-Fi : en-tête fixe, onglets, et une seule vue à la fois
// (Connecté / Disponibles / Enregistrés / Caché) dans une zone défilante.
Item {
    id: root

    required property ScreenState screenState

    readonly property int margin: 10
    readonly property int maxContentHeight: 440

    // 0 = Connecté, 1 = Disponibles, 2 = Enregistrés, 3 = Caché
    property int currentTab: 1

    implicitWidth: 340
    implicitHeight: Math.min(column.implicitHeight + margin * 2, maxContentHeight)

    // Les détails IP/DNS/MAC suivent le réseau actif
    Connections {
        target: Nmcli

        function onActiveChanged(): void {
            Nmcli.getWirelessDeviceDetails("", null);
        }
    }

    Component.onCompleted: {
        // Connecté d'abord s'il y a un réseau actif, sinon la liste des réseaux
        currentTab = Nmcli.active ? 0 : 1;
        Nmcli.getWirelessDeviceDetails("", null);
        Nmcli.rescanWifi();
        Nmcli.loadSavedConnections(null);
    }

    ColumnLayout {
        id: column
        anchors.fill: parent
        anchors.margins: root.margin
        spacing: 6

        // --- En-tête : titre, scan, interrupteur ---
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            WifiText {
                text: qsTr("Wi-Fi")
                size: 11
                weight: Font.Medium
                Layout.fillWidth: true
            }

            IconButton {
                icon: "refresh"
                type: IconButton.Text
                font: Tokens.font.icon.builders.medium.size(13).build()
                disabled: !Nmcli.wifiEnabled
                opacity: Nmcli.scanning ? 0.5 : 1
                onClicked: Nmcli.rescanWifi()
            }

            CompactSwitch {
                checked: Nmcli.wifiEnabled
                onToggled: Nmcli.toggleWifi(null)
            }
        }

        WifiText {
            visible: !Nmcli.wifiEnabled
            text: qsTr("Wi-Fi désactivé")
            color: Colours.palette.m3onSurfaceVariant
            Layout.fillWidth: true
        }

        // --- Onglets ---
        WifiTabs {
            visible: Nmcli.wifiEnabled
            Layout.fillWidth: true
            tabs: [qsTr("Connecté"), qsTr("Disponibles"), qsTr("Enregistrés"), qsTr("Caché")]
            currentIndex: root.currentTab
            onCurrentIndexChanged: root.currentTab = currentIndex
        }

        // --- Vue courante (défile si elle dépasse la hauteur maximale) ---
        Flickable {
            id: flick
            visible: Nmcli.wifiEnabled
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitHeight: Nmcli.wifiEnabled ? view.implicitHeight : 0
            contentWidth: width
            contentHeight: view.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Loader {
                id: view
                width: flick.width

                sourceComponent: {
                    switch (root.currentTab) {
                    case 0:
                        return connectedView;
                    case 1:
                        return availableView;
                    case 2:
                        return savedView;
                    default:
                        return hiddenView;
                    }
                }
            }
        }
    }

    Component {
        id: connectedView

        ActiveDetails {
            network: Nmcli.active
        }
    }

    Component {
        id: availableView

        AvailableList {}
    }

    Component {
        id: savedView

        SavedList {}
    }

    Component {
        id: hiddenView

        HiddenNetworkForm {
            onClosed: root.currentTab = 0
        }
    }
}
