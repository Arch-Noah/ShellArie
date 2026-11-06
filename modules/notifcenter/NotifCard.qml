pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.components.panel
import qs.services

// Une notification : pastille, application, heure, titre, corps, actions, fermeture.
Rectangle {
    id: root

    required property var notif

    // Nombre de notifications identiques regroupées derrière cette carte (1 = pas de groupe)
    property int groupCount: 1
    property bool groupExpanded

    signal clicked
    signal closeRequested

    // Boutons d'action : on ignore ceux sans libellé (ils s'afficheraient en pastille vide)
    readonly property var visibleActions: notif.actions.filter(a => a.text && a.text.trim().length > 0)

    readonly property bool critical: notif.urgency === 2
    readonly property bool hasImage: !!notif.image && notif.image.length > 0
    property bool expanded

    implicitHeight: col.implicitHeight + 24
    radius: 16
    color: critical ? Qt.alpha(Colours.palette.m3error, 0.12) : Colours.tPalette.m3surfaceContainer

    // Un clic sur la carte déplie ou replie le corps (ou le groupe, géré par le parent)
    StateLayer {
        anchors.fill: parent
        radius: root.radius
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.groupCount <= 1)
                root.expanded = !root.expanded;
            root.clicked();
        }
    }

    RowLayout {
        id: col
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        // Pastille : image de la notification ou icône de repli
        Rectangle {
            Layout.alignment: Qt.AlignTop
            implicitWidth: 36
            implicitHeight: 36
            radius: 18
            clip: true
            color: root.critical ? Qt.alpha(Colours.palette.m3error, 0.2) : Qt.alpha(Colours.palette.m3onSurface, 0.08)

            Image {
                id: img
                anchors.fill: parent
                visible: root.hasImage && status === Image.Ready
                fillMode: Image.PreserveAspectCrop
                source: {
                    if (!root.hasImage)
                        return "";
                    return root.notif.image.startsWith("/") ? "file://" + root.notif.image : root.notif.image;
                }
            }

            PanelIcon {
                anchors.centerIn: parent
                visible: !img.visible
                text: root.critical ? "priority_high" : "notifications"
                size: 17
                color: root.critical ? Colours.palette.m3error : Colours.palette.m3onSurface
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                PanelText {
                    text: root.notif.appName || qsTr("Système")
                    size: 8
                    color: Colours.palette.m3onSurfaceVariant
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                PanelText {
                    text: root.notif.timeStr
                    size: 8
                    color: Colours.palette.m3onSurfaceVariant
                }

                // Badge du groupe : nombre de notifications et chevron qui pivote
                Rectangle {
                    visible: root.groupCount > 1
                    implicitWidth: badge.implicitWidth + 12
                    implicitHeight: 20
                    radius: 10
                    color: Qt.alpha(Colours.palette.m3primary, 0.2)

                    RowLayout {
                        id: badge
                        anchors.centerIn: parent
                        spacing: 2

                        PanelText {
                            text: "×" + root.groupCount
                            size: 8
                            weight: Font.DemiBold
                            color: Colours.palette.m3primary
                        }

                        PanelIcon {
                            text: "expand_more"
                            size: 12
                            color: Colours.palette.m3primary
                            rotation: root.groupExpanded ? 180 : 0

                            Behavior on rotation {
                                NumberAnimation {
                                    duration: 280
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                    }
                }

                PanelButton {
                    icon: "close"
                    tint: Colours.palette.m3onSurfaceVariant
                    implicitWidth: 22
                    implicitHeight: 22
                    onClicked: root.closeRequested()
                }
            }

            PanelText {
                text: root.notif.summary
                size: 10
                weight: Font.DemiBold
                wrapMode: Text.Wrap
                maximumLineCount: root.expanded ? 6 : 2
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            PanelText {
                visible: root.notif.body !== ""
                text: root.notif.body
                size: 9
                color: Colours.palette.m3onSurfaceVariant
                wrapMode: Text.Wrap
                textFormat: Text.StyledText
                maximumLineCount: root.expanded ? 30 : 3
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            // Boutons d'action
            RowLayout {
                visible: root.visibleActions.length > 0
                Layout.fillWidth: true
                Layout.topMargin: 4
                spacing: 6

                Repeater {
                    model: root.visibleActions

                    delegate: PanelButton {
                        required property int index
                        required property var modelData

                        Layout.fillWidth: true
                        text: modelData.text
                        filled: index === 0
                        textSize: 8.5
                        implicitHeight: 28
                        onClicked: modelData.invoke()
                    }
                }
            }
        }
    }
}
