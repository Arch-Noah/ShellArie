pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.components.panel
import qs.services

// Contenu du centre de notifications : en-tête fixe, liste défilante.
Item {
    id: root

    required property var screenState

    readonly property var items: Notifs.notClosed

    focus: true
    Keys.onEscapePressed: {
        if (screenState)
            screenState.notifCenter = false;
    }

    Component.onCompleted: forceActiveFocus()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        // --- En-tête ---
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            PanelText {
                text: qsTr("Notifications")
                size: 12
                weight: Font.DemiBold
            }

            Rectangle {
                visible: root.items.length > 0
                implicitWidth: countText.implicitWidth + 14
                implicitHeight: countText.implicitHeight + 6
                radius: height / 2
                color: Qt.alpha(Colours.palette.m3primary, 0.2)

                PanelText {
                    id: countText
                    anchors.centerIn: parent
                    text: root.items.length
                    size: 8.5
                    weight: Font.Medium
                    color: Colours.palette.m3primary
                }
            }

            Item {
                Layout.fillWidth: true
            }

            PanelButton {
                visible: root.items.length > 0
                text: qsTr("Tout effacer")
                icon: "delete_sweep"
                tint: Colours.palette.m3error
                textSize: 8.5
                implicitHeight: 28
                onClicked: {
                    for (const n of Notifs.list.slice())
                        n.close();
                }
            }
        }

        // --- Ne pas déranger ---
        PanelCard {
            Layout.fillWidth: true

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                Layout.topMargin: 8
                Layout.bottomMargin: 8
                spacing: 10

                Rectangle {
                    implicitWidth: 30
                    implicitHeight: 30
                    radius: 15
                    color: Notifs.dnd ? Qt.alpha(Colours.palette.m3primary, 0.2) : Qt.alpha(Colours.palette.m3onSurface, 0.08)

                    PanelIcon {
                        anchors.centerIn: parent
                        text: Notifs.dnd ? "notifications_off" : "notifications_active"
                        size: 15
                        color: Notifs.dnd ? Colours.palette.m3primary : Colours.palette.m3onSurface
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    PanelText {
                        text: qsTr("Ne pas déranger")
                        size: 10
                        weight: Font.Medium
                    }

                    PanelText {
                        text: Notifs.dnd ? qsTr("Les popups sont désactivés") : qsTr("Les popups sont activés")
                        size: 8
                        color: Colours.palette.m3onSurfaceVariant
                    }
                }

                PanelSwitch {
                    id: dndSwitch
                    onToggled: Notifs.dnd = checked
                }

                Binding {
                    target: dndSwitch
                    property: "checked"
                    value: Notifs.dnd
                }
            }
        }

        // --- Liste ---
        PanelEmpty {
            visible: root.items.length === 0
            Layout.fillHeight: true
            icon: "notifications"
            text: qsTr("Aucune notification")
            iconSize: 30
        }

        Flickable {
            id: flick
            visible: root.items.length > 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: list.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: list
                width: flick.width
                spacing: 8

                Repeater {
                    model: root.items

                    delegate: NotifCard {
                        required property var modelData

                        Layout.fillWidth: true
                        notif: modelData
                    }
                }
            }
        }
    }
}
