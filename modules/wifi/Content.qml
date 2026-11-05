pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

Item {
    id: root

    required property ScreenState screenState

    readonly property int margin: 16
    readonly property int maxContentHeight: 640

    implicitWidth: 420
    implicitHeight: Math.min(column.implicitHeight + margin * 2, maxContentHeight)

    Component.onCompleted: {
        Nmcli.rescanWifi();
        Nmcli.loadSavedConnections(null);
    }

    Flickable {
        id: flick
        anchors.fill: parent
        anchors.margins: root.margin
        clip: true
        contentWidth: width
        contentHeight: column.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: column
            width: flick.width
            spacing: 12

            // --- En-tête : titre, interrupteur, scan ---
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                StyledText {
                    text: qsTr("Wi-Fi")
                    font: Tokens.font.title.small
                    Layout.fillWidth: true
                }

                IconButton {
                    icon: "refresh"
                    type: IconButton.Text
                    disabled: !Nmcli.wifiEnabled
                    opacity: Nmcli.scanning ? 0.5 : 1
                    onClicked: Nmcli.rescanWifi()
                }

                StyledSwitch {
                    checked: Nmcli.wifiEnabled
                    onToggled: Nmcli.toggleWifi(null)
                }
            }

            StyledText {
                visible: !Nmcli.wifiEnabled
                text: qsTr("Wi-Fi désactivé")
                color: Colours.palette.m3onSurfaceVariant
                Layout.fillWidth: true
            }
        }
    }
}
