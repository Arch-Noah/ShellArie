pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.components.panel
import qs.services

// Un groupe de notifications identiques (même application, même titre, même corps).
// Replié : la plus récente en carte, avec une pile derrière. Déplié : les plus anciennes glissent
// en dessous, l'une après l'autre. Un groupe d'une seule notification se comporte comme une carte.
Item {
    id: root

    // { key, items: [NotifData…] }, la plus récente en premier
    required property var group
    property bool expanded

    signal toggleRequested

    readonly property var items: group.items
    readonly property int count: items.length
    readonly property var older: items.slice(1)
    readonly property real peekHeight: 16

    // Avancement de l'animation : 0 replié, 1 déplié
    property real p: expanded ? 1 : 0

    Behavior on p {
        NumberAnimation {
            duration: 320
            easing.type: Easing.OutCubic
        }
    }

    function closeAll(): void {
        for (const n of items.slice())
            n.close();
    }

    implicitHeight: head.height + wrap.height

    // --- La plus récente, avec la pile derrière ---
    Item {
        id: head

        width: root.width
        height: card.implicitHeight + (root.count > 1 ? root.peekHeight * (1 - root.p) : 0)

        // Deux fines couches qui dépassent sous la carte : la pile
        Repeater {
            model: root.count > 1 ? 2 : 0

            delegate: Item {
                id: layer

                required property int index

                x: 10 * (index + 1)
                y: card.implicitHeight
                width: head.width - 20 * (index + 1)
                height: 10 + index * 6
                clip: true
                opacity: (1 - root.p) * (1 - index * 0.35)

                // Le haut du rectangle reste caché sous la carte : seul le bas dépasse
                Rectangle {
                    y: -30
                    width: parent.width
                    height: 30 + layer.height
                    radius: 14
                    // Plus claire que la carte pour qu'on devine la pile derrière
                    color: Qt.alpha(Colours.palette.m3onSurface, 0.1)
                }
            }
        }

        NotifCard {
            id: card

            width: head.width
            notif: root.items[0]
            groupCount: root.count
            groupExpanded: root.expanded
            onClicked: if (root.count > 1)
                root.toggleRequested()
            onCloseRequested: root.closeAll()
        }
    }

    // --- Les plus anciennes : apparition échelonnée ---
    Item {
        id: wrap

        y: head.height
        width: root.width
        height: root.count > 1 ? root.p * (olderCol.implicitHeight + 8) : 0
        visible: height > 0.5
        clip: true

        ColumnLayout {
            id: olderCol

            y: 8
            width: wrap.width
            spacing: 8

            Repeater {
                model: root.older

                delegate: NotifCard {
                    id: oldCard

                    required property int index
                    required property var modelData

                    // Chaque carte démarre un peu après la précédente (au plus 5 crans)
                    readonly property real appear: Math.max(0, Math.min(1, (root.p - Math.min(index, 5) * 0.1) / 0.5))

                    Layout.fillWidth: true
                    notif: modelData
                    opacity: appear
                    transform: Translate {
                        y: (1 - oldCard.appear) * -16
                    }
                    onCloseRequested: modelData.close()
                }
            }

            PanelButton {
                id: collapse

                readonly property real appear: Math.max(0, Math.min(1, (root.p - Math.min(root.older.length, 5) * 0.1) / 0.5))

                Layout.fillWidth: true
                text: qsTr("Réduire")
                icon: "expand_less"
                tint: Colours.palette.m3onSurfaceVariant
                textSize: 8.5
                implicitHeight: 28
                opacity: appear
                onClicked: root.toggleRequested()
            }
        }
    }
}
