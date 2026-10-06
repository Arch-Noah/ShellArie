pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia
import Caelestia.Config
import qs.components
import qs.components.filedialog
import qs.utils
import "../../commons"

Item {
    id: root

    required property ScreenState screenState
    readonly property FileDialog facePicker: FileDialog {
        title: qsTr("Select a profile picture")
        filterLabel: qsTr("Image files")
        filters: Images.validImageExtensions
        onAccepted: path => {
            if (CUtils.copyFile(Qt.resolvedUrl(path), Qt.resolvedUrl(`${Paths.home}/.face`)))
                Quickshell.execDetached(["notify-send", "-a", "caelestia-shell", "-u", "low", "-h", `STRING:image-path:${path}`, "Profile picture changed", `Profile picture changed to ${Paths.shortenHome(path)}`]);
            else
                Quickshell.execDetached(["notify-send", "-a", "caelestia-shell", "-u", "critical", "Unable to change profile picture", `Failed to change profile picture to ${Paths.shortenHome(path)}`]);
        }
    }

    readonly property real nonAnimHeight: (content.item as Content)?.nonAnimHeight ?? 0
    readonly property bool shouldBeActive: (screenState?.dashboard ?? false) && Config.dashboard.enabled
    property real offsetScale: shouldBeActive ? 0 : 1

    visible: offsetScale < 1 || height > 0
    property int overlapAmount: 0 
    property int topPadding: 0
    property int notchRadius: 60

    // Root must be wide enough to include the notches so clip: true doesn't chop them off horizontally
    implicitWidth: (content.implicitWidth || 854) + notchRadius * 2
    
    // Animate the height of the wrapper
    height: implicitHeight * (1 - offsetScale)
    implicitHeight: (content.implicitHeight ? content.implicitHeight + overlapAmount + topPadding : 800)
    
    // We don't strictly need clip anymore since it scales from the top, but keeping it is safe
    clip: true

    Behavior on offsetScale {
        Anim { type: Anim.SlowSpatial }
    }

    // Container for the dashboard
    Item {
        width: parent.width
        height: root.implicitHeight
        anchors.top: parent.top // Anchor to TOP so it expands downwards
        
        opacity: 1 - root.offsetScale

        // The actual dashboard content centered
        Item {
            id: innerContent
            width: content.implicitWidth || 854
            height: parent.height
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top

            // Squish the widget vertically!
            transform: Scale {
                yScale: 1 - root.offsetScale
                origin.y: 0 // Scale from the top edge
            }

            // Background container using clip to square off the top corners without opacity stacking
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
                    border.width: 0
                }
            }

            // Left inverted corner (fillet) using Scene Graph for perfect opacity matching
            Item {
                id: leftNotch
                width: notchRadius
                height: notchRadius
                anchors.right: parent.left
                anchors.top: parent.top
                clip: true
                
                Rectangle {
                    width: notchRadius * 4
                    height: notchRadius * 4
                    radius: notchRadius * 2
                    border.width: notchRadius
                    border.color: Styles.mixAlpha(Styles.background, 0.90)
                    color: "transparent"
                    
                    // Center of rectangle should be at (0, notchRadius)
                    x: -notchRadius * 2
                    y: -notchRadius
                }
            }

            // Right inverted corner (fillet) using Scene Graph for perfect opacity matching
            Item {
                id: rightNotch
                width: notchRadius
                height: notchRadius
                anchors.left: parent.right
                anchors.top: parent.top
                clip: true
                
                Rectangle {
                    width: notchRadius * 4
                    height: notchRadius * 4
                    radius: notchRadius * 2
                    border.width: notchRadius
                    border.color: Styles.mixAlpha(Styles.background, 0.90)
                    color: "transparent"
                    
                    // Center of rectangle should be at (notchRadius, notchRadius)
                    x: -notchRadius
                    y: -notchRadius
                }
            }

            Loader {
                id: content
                anchors.fill: parent
                active: root.shouldBeActive

                sourceComponent: Content {
                    screenState: root.screenState
                    facePicker: root.facePicker
                }
            }
        }
    }
}
