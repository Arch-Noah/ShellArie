import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import qs.services
import "../modules/dashboard" as Dashboard
import "commons"
import "components"

Scope {
    id: root

    property bool isBarLocked: true
    // Seconde barre (icônes des applications) : bascule via `qs ipc call taskbar toggle`
    property bool taskbarEnabled: true

    IpcHandler {
        target: "taskbar"
        function toggle(): void {
            root.taskbarEnabled = !root.taskbarEnabled;
        }
    }

    Instantiator {
        model: Quickshell.screens
        delegate: Scope {
            id: screenScope
            property bool isBarHovered: false
            property bool isBarVisible: root.isBarLocked || screenScope.isBarHovered

            // BarHover: Invisible overlay at the top to detect mouse enter when unlocked
            PanelWindow {
                id: hoverTrigger
                screen: modelData
                visible: !root.isBarLocked
                color: "transparent"
                
                anchors {
                    top: true
                    left: true
                    right: true
                }
                
                implicitHeight: 5
                exclusiveZone: 0
                
                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(0, 0, 0, 0.01) // minimal opacity to catch mouse
                    
                    HoverHandler {
                        onHoveredChanged: {
                            if (hovered && !root.isBarLocked) {
                                screenScope.isBarHovered = true;
                            }
                        }
                    }
                }
            }

            PanelWindow {
                id: barWindow
                screen: modelData
                color: "transparent"
                visible: screenScope.isBarVisible

                anchors {
                    top: true
                    left: true
                    right: true
                }

                margins {
                    top: Styles.globalMargin
                    left: Styles.globalMargin
                    right: Styles.globalMargin
                }

                implicitHeight: Math.max(dashWrapper.implicitHeight + 60, 850)
                
                exclusiveZone: screenScope.isBarVisible ? 40 : 0

                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

                mask: inputMask
                Region {
                    id: inputMask
                    x: 0; y: 0
                    width: barWindow.width
                    height: dashWrapper.visible ? (barRect.height + 10 + dashWrapper.implicitHeight) : barRect.height
                    // Zone cliquable de la seconde barre (union avec le rectangle ci-dessus)
                    regions: [
                        Region {
                            x: taskbar.x
                            y: taskbar.y
                            width: taskbar.width
                            height: taskbar.height
                        }
                    ]
                }

                HyprlandFocusGrab {
                    active: dashWrapper.shouldBeActive
                    windows: [barWindow]
                    onCleared: {
                        dashWrapper.screenState.dashboard = false;
                    }
                }

                Item {
                    anchors.fill: parent

                    Dashboard.Wrapper {
                        id: dashWrapper
                        screenState: ShellState.forScreen(modelData)
                        anchors.top: barRect.bottom
                        // No anchors.topMargin here because Wrapper.qml defines its own animated anchors.topMargin!
                        anchors.horizontalCenter: parent.horizontalCenter
                        z: -1 // Behind the bar
                    }

                    Taskbar {
                        id: taskbar
                        screen: modelData
                        barHeight: barRect.height
                        suppressed: dashWrapper.visible || !root.taskbarEnabled
                        anchors.top: barRect.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        z: -1 // Derrière la barre, comme le dashboard
                    }

                    Rectangle {
                        id: barRect
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 40
                        color: "transparent"
                        radius: Styles.borderRadius
                        
                        HoverHandler {
                            onHoveredChanged: {
                                if (!hovered && !root.isBarLocked) {
                                    screenScope.isBarHovered = false;
                                }
                            }
                        }

                        // The main inner box matching `.bar.full`
                        Rectangle {
                            anchors.fill: parent
                            color: Styles.mixAlpha(Styles.background, 0.90)
                            radius: Styles.borderRadius

                            RowLayout {
                            anchors.fill: parent
                            anchors.margins: 5
                            spacing: 0

                            Item {
                                Layout.fillWidth: true
                                Workspaces {
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    targetMonitorName: modelData.name
                                    isBarLocked: root.isBarLocked
                                    onToggleLockRequested: root.isBarLocked = !root.isBarLocked
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                                Information {
                                    anchors.centerIn: parent
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                                Utilities {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
    }
