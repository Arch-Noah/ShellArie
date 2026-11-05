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
    readonly property int maxContentHeight: 480

    // 0 = Connecté, 1 = Disponibles, 2 = Enregistrés, 3 = Caché
    readonly property var tabIcons: ["wifi", "list", "bookmark", "visibility_off"]
    // Le panneau s'ouvre toujours sur la vue « Connecté »
    property int currentTab: 0

    // Flèches gauche / droite : changer de vue
    focus: true
    Keys.onEscapePressed: screenState.wifi = false
    Keys.onLeftPressed: currentTab = Math.max(0, currentTab - 1)
    Keys.onRightPressed: currentTab = Math.min(tabIcons.length - 1, currentTab + 1)

    // Après un changement de vue, l'éventuel champ de saisie détruit rend le focus : on le reprend
    onCurrentTabChanged: Qt.callLater(() => {
        if (!root.activeFocus)
            root.forceActiveFocus();
    })

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
        forceActiveFocus();
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
            icons: root.tabIcons
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
