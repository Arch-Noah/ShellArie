pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.components.panel
import qs.services

// Contenu du panneau Son : en-tête fixe, onglets en icônes, une seule vue à la fois
// (Sortie / Entrée) dans une zone défilante.
Item {
    id: root

    required property ScreenState screenState

    readonly property int margin: 10
    readonly property int maxContentHeight: 480

    // 0 = Sortie, 1 = Entrée
    readonly property var tabIcons: ["volume_up", "mic"]
    // Le panneau s'ouvre toujours sur la vue « Sortie »
    property int currentTab: 0

    implicitWidth: 340
    implicitHeight: Math.min(column.implicitHeight + margin * 2, maxContentHeight)

    // Flèches gauche / droite : changer de vue ; Échap : fermer
    focus: true
    Keys.onEscapePressed: screenState.audio = false
    Keys.onLeftPressed: currentTab = Math.max(0, currentTab - 1)
    Keys.onRightPressed: currentTab = Math.min(tabIcons.length - 1, currentTab + 1)

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

        PanelText {
            text: qsTr("Son")
            size: 11
            weight: Font.Medium
            Layout.fillWidth: true
        }

        PanelTabs {
            Layout.fillWidth: true
            icons: root.tabIcons
            currentIndex: root.currentTab
            onCurrentIndexChanged: root.currentTab = currentIndex
        }

        Flickable {
            id: flick
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitHeight: view.implicitHeight
            contentWidth: width
            contentHeight: view.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Loader {
                id: view
                width: flick.width

                sourceComponent: root.currentTab === 0 ? outputView : inputView
            }
        }
    }

    Component {
        id: outputView

        DeviceView {
            output: true
        }
    }

    Component {
        id: inputView

        DeviceView {
            output: false
        }
    }
}
