pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services
import qs.components
import "../../commons"

// Centre de notifications : colonne flottante à droite, détachée de la barre, une par écran.
Variants {
    model: Quickshell.screens

    Scope {
        id: scope

        required property var modelData

        readonly property var screenState: ShellState.forScreen(modelData)
        readonly property bool open: screenState?.notifCenter ?? false

        // 0 = fermé, 1 = ouvert (animé)
        property real progress: open ? 1 : 0

        Behavior on progress {
            NumberAnimation {
                duration: 260
                easing.type: Easing.OutCubic
            }
        }

        PanelWindow {
            id: window

            screen: scope.modelData
            visible: scope.progress > 0.001
            color: "transparent"

            anchors {
                top: true
                bottom: true
                right: true
            }

            // La fenêtre glisse depuis le bord droit
            margins {
                top: 55
                bottom: 20
                right: 20 - (1 - scope.progress) * (width + 20)
            }

            implicitWidth: 380
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "qs-notifcenter"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            HyprlandFocusGrab {
                active: scope.open
                windows: [window]
                onCleared: {
                    if (scope.screenState) {
                        scope.screenState.notifCenterClosedAt = Date.now();
                        scope.screenState.notifCenter = false;
                    }
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: Styles.borderRadius * 1.5
                color: Styles.mixAlpha(Styles.background, 0.92)
                opacity: scope.progress

                Loader {
                    anchors.fill: parent
                    active: window.visible

                    sourceComponent: NotifCenterContent {
                        screenState: scope.screenState
                    }
                }
            }
        }
    }
}
