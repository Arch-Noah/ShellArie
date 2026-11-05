pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs.components
import qs.components.panel
import qs.services

// Contenu du panneau Bluetooth : en-tête fixe, onglets en icônes, une seule vue à la fois
// (Connecté / Appairés / Découverte / Réglages) dans une zone défilante.
Item {
    id: root

    required property ScreenState screenState

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool ready: !!adapter && adapter.enabled
    readonly property int margin: 10
    readonly property int maxContentHeight: 480

    // 0 = Connecté, 1 = Appairés, 2 = Découverte, 3 = Réglages
    readonly property var tabIcons: ["bluetooth_connected", "devices", "bluetooth_searching", "tune"]
    // Le panneau s'ouvre toujours sur la vue « Connecté »
    property int currentTab: 0

    implicitWidth: 340
    implicitHeight: Math.min(column.implicitHeight + margin * 2, maxContentHeight)

    // Flèches gauche / droite : changer de vue ; Échap : fermer
    focus: true
    Keys.onEscapePressed: screenState.bluetooth = false
    Keys.onLeftPressed: currentTab = Math.max(0, currentTab - 1)
    Keys.onRightPressed: currentTab = Math.min(tabIcons.length - 1, currentTab + 1)

    // Après un changement de vue, l'éventuel champ détruit rend le focus : on le reprend
    onCurrentTabChanged: Qt.callLater(() => {
        if (!root.activeFocus)
            root.forceActiveFocus();
    })

    Component.onCompleted: forceActiveFocus()

    ColumnLayout {
        id: column
        anchors.fill: parent
        anchors.margins: root.margin
        spacing: 6

        // --- En-tête : titre, interrupteur d'alimentation ---
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            PanelText {
                text: qsTr("Bluetooth")
                size: 11
                weight: Font.Medium
                Layout.fillWidth: true
            }

            PanelSwitch {
                id: power
                visible: !!root.adapter
                onToggled: if (root.adapter)
                    root.adapter.enabled = checked
            }

            // Garde l'interrupteur aligné sur l'état réel de l'adaptateur
            Binding {
                target: power
                property: "checked"
                value: root.adapter?.enabled ?? false
            }
        }

        PanelText {
            visible: !root.ready
            text: root.adapter ? qsTr("Bluetooth désactivé") : qsTr("Aucun adaptateur Bluetooth")
            color: Colours.palette.m3onSurfaceVariant
            Layout.fillWidth: true
        }

        // --- Onglets ---
        PanelTabs {
            visible: root.ready
            Layout.fillWidth: true
            icons: root.tabIcons
            currentIndex: root.currentTab
            onCurrentIndexChanged: root.currentTab = currentIndex
        }

        // --- Vue courante (défile si elle dépasse la hauteur maximale) ---
        Flickable {
            id: flick
            visible: root.ready
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitHeight: root.ready ? view.implicitHeight : 0
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
                        return pairedView;
                    case 2:
                        return discoveryView;
                    default:
                        return settingsView;
                    }
                }
            }
        }
    }

    Component {
        id: connectedView

        ConnectedView {}
    }

    Component {
        id: pairedView

        PairedView {}
    }

    Component {
        id: discoveryView

        DiscoveryView {}
    }

    Component {
        id: settingsView

        SettingsView {}
    }
}
