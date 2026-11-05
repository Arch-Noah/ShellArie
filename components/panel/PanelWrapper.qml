pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import "../../commons"

// Enveloppe animée commune aux panneaux (Wi-Fi, Bluetooth) : même mécanique que
// modules/dashboard/Wrapper.qml (descente depuis la barre, fond arrondi, coins « notch »).
Item {
    id: root

    // Ouvert ou fermé (piloté par le drapeau de ScreenState du panneau)
    property bool shouldBeActive
    // Contenu à charger tant que le panneau est ouvert
    property Component contentComponent

    property real offsetScale: shouldBeActive ? 0 : 1
    property int notchRadius: 60

    visible: offsetScale < 1 || height > 0

    // Assez large pour contenir les notches, sinon clip: true les couperait
    implicitWidth: (content.implicitWidth || 420) + notchRadius * 2
    implicitHeight: content.implicitHeight || 200
    height: implicitHeight * (1 - offsetScale)
    clip: true

    Behavior on offsetScale {
        Anim { type: Anim.SlowSpatial }
    }

    Item {
        width: parent.width
        height: root.implicitHeight
        anchors.top: parent.top
        opacity: 1 - root.offsetScale

        Item {
            id: innerContent
            width: content.implicitWidth || 420
            height: parent.height
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top

            transform: Scale {
                yScale: 1 - root.offsetScale
                origin.y: 0
            }

            // Fond : le clip carre les coins du haut sans empiler les opacités
            Item {
                anchors.fill: parent
                z: -1
                clip: true

                Rectangle {
                    x: 0
                    y: -Styles.borderRadius * 1.5
                    width: parent.width
                    height: parent.height + Styles.borderRadius * 1.5
                    color: Styles.mixAlpha(Styles.background, 0.90)
                    radius: Styles.borderRadius * 1.5
                }
            }

            // Coin concave gauche
            Item {
                width: root.notchRadius
                height: root.notchRadius
                anchors.right: parent.left
                anchors.top: parent.top
                clip: true

                Rectangle {
                    width: root.notchRadius * 4
                    height: root.notchRadius * 4
                    radius: root.notchRadius * 2
                    border.width: root.notchRadius
                    border.color: Styles.mixAlpha(Styles.background, 0.90)
                    color: "transparent"
                    x: -root.notchRadius * 2
                    y: -root.notchRadius
                }
            }

            // Coin concave droit
            Item {
                width: root.notchRadius
                height: root.notchRadius
                anchors.left: parent.right
                anchors.top: parent.top
                clip: true

                Rectangle {
                    width: root.notchRadius * 4
                    height: root.notchRadius * 4
                    radius: root.notchRadius * 2
                    border.width: root.notchRadius
                    border.color: Styles.mixAlpha(Styles.background, 0.90)
                    color: "transparent"
                    x: -root.notchRadius
                    y: -root.notchRadius
                }
            }

            Loader {
                id: content
                anchors.fill: parent
                active: root.shouldBeActive

                sourceComponent: root.contentComponent
            }
        }
    }
}
