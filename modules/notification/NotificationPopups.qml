import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs.services
import "."
import "WindowRegistry.js" as Registry

PanelWindow {
    id: popupWindow

    Caching { id: paths }

    property real uiScale: 1.0
    property color accentColor: _theme.sapphire

    property var layoutConfig: Registry.getPopupLayout(Screen.width, popupWindow.uiScale)

    WlrLayershell.namespace: "qs-popups"
    WlrLayershell.layer: WlrLayer.Overlay

    anchors {
        top: true
        right: true
    }

    margins {
        top: popupWindow.layoutConfig.marginTop
        right: popupWindow.layoutConfig.marginRight
    }

    exclusionMode: ExclusionMode.Ignore
    focusable: false
    color: "transparent"

    width: popupWindow.layoutConfig.w
    height: Math.min(popupList.contentHeight, Screen.height * 0.8)

    Item {
        id: contentWrapper
        anchors.fill: parent

        // We use Notifs.dnd natively now!
        opacity: Notifs.dnd ? 0.0 : 1.0
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: 300 } }

        MatugenColors { id: _theme }

        ListView {
            id: popupList
            anchors.fill: parent
            model: Notifs.popups
            spacing: popupWindow.layoutConfig.spacing
            interactive: false
            clip: false

            add: Transition {
                ParallelAnimation {
                    NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 400; easing.type: Easing.OutQuint }
                    NumberAnimation { property: "x"; from: popupWindow.width * 0.4; to: 0; duration: 500; easing.type: Easing.OutQuint }
                }
            }

            remove: Transition {
                ParallelAnimation {
                    NumberAnimation { property: "opacity"; to: 0.0; duration: 350; easing.type: Easing.OutQuint }
                    NumberAnimation { property: "x"; to: popupWindow.width * 0.4; duration: 400; easing.type: Easing.OutQuint }
                }
            }

            displaced: Transition {
                NumberAnimation { properties: "x,y"; duration: 450; easing.type: Easing.OutQuint }
            }

            delegate: Item {
                id: delegateRoot
                width: ListView.view.width
                height: contentCol.height + Math.round(24 * popupWindow.uiScale)

                property var notifData: modelData
                property string fullSummary: modelData.summary || ""
                property string fullBody: modelData.body || ""
                property int typeLenSum: 0
                property int typeLenBody: 0

                property var actionArray: modelData.actions || []

                ParallelAnimation {
                    running: true
                    NumberAnimation {
                        target: delegateRoot; property: "typeLenSum"
                        from: 0; to: fullSummary.length
                        duration: Math.min(fullSummary.length * 20, 600)
                        easing.type: Easing.OutCubic
                    }
                    SequentialAnimation {
                        PauseAnimation { duration: 150 }
                        NumberAnimation {
                            target: delegateRoot; property: "typeLenBody"
                            from: 0; to: fullBody.length
                            duration: Math.min(fullBody.length * 15, 1200)
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                Rectangle {
                    id: popupCard
                    anchors.fill: parent
                    radius: popupWindow.layoutConfig.radius
                    color: _theme.base
                    border.color: _theme.surface1
                    border.width: 1
                    clip: true

                    // Card body click
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            if (delegateRoot.actionArray.length > 0) {
                                // Try to invoke default action
                                let invoked = false;
                                for (var i = 0; i < delegateRoot.actionArray.length; i++) {
                                    if (delegateRoot.actionArray[i].identifier === "default") {
                                        delegateRoot.actionArray[i].invoke();
                                        invoked = true;
                                        break;
                                    }
                                }
                            }
                            delegateRoot.notifData.popup = false;
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: popupCard.radius
                            color: _theme.surface0
                            opacity: parent.containsMouse ? 0.3 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 250 } }
                        }
                    }

                    ColumnLayout {
                        id: contentCol
                        z: 1
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.leftMargin: popupWindow.layoutConfig.padding + 6
                        anchors.rightMargin: popupWindow.layoutConfig.padding
                        anchors.topMargin: popupWindow.layoutConfig.padding
                        spacing: 4 * popupWindow.uiScale

                        // Header: app name + time
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6 * popupWindow.uiScale

                            Text {
                                text: delegateRoot.notifData.appName || "System"
                                font.family: "JetBrains Mono"
                                font.weight: Font.Medium
                                font.pixelSize: 11 * popupWindow.uiScale
                                color: _theme.overlay1
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Text {
                                text: delegateRoot.notifData.timeStr || "now"
                                font.family: "JetBrains Mono"
                                font.pixelSize: 10 * popupWindow.uiScale
                                color: _theme.surface2
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.topMargin: 4 * popupWindow.uiScale
                            spacing: 8 * popupWindow.uiScale

                            Rectangle {
                                readonly property bool hasImage: delegateRoot.notifData.image && delegateRoot.notifData.image.length > 0
                                Layout.preferredWidth: hasImage ? 48 * popupWindow.uiScale : 0
                                Layout.preferredHeight: hasImage ? 48 * popupWindow.uiScale : 0
                                Layout.alignment: Qt.AlignTop
                                visible: hasImage
                                radius: 8 * popupWindow.uiScale
                                color: _theme.surface0
                                clip: true

                                Image {
                                    id: notifImg
                                    anchors.fill: parent
                                    source: {
                                        if (delegateRoot.notifData.image && delegateRoot.notifData.image.length > 0) {
                                            return delegateRoot.notifData.image.startsWith("/") ? "file://" + delegateRoot.notifData.image : delegateRoot.notifData.image;
                                        }
                                        return "";
                                    }
                                    fillMode: Image.PreserveAspectCrop
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰎞"
                                    color: _theme.overlay1
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: 22 * popupWindow.uiScale
                                    visible: notifImg.status === Image.Error || notifImg.status === Image.Null
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2 * popupWindow.uiScale

                                Item {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: hiddenSummary.implicitHeight

                                    Text {
                                        id: hiddenSummary
                                        text: delegateRoot.fullSummary
                                        width: parent.width
                                        font.family: "JetBrains Mono"
                                        font.weight: Font.Bold
                                        font.pixelSize: 14 * popupWindow.uiScale
                                        wrapMode: Text.Wrap
                                        visible: false
                                    }

                                    Text {
                                        anchors.fill: parent
                                        text: delegateRoot.fullSummary.substring(0, delegateRoot.typeLenSum)
                                        font: hiddenSummary.font
                                        color: _theme.text
                                        wrapMode: Text.Wrap
                                    }
                                }

                                Item {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: hiddenBody.implicitHeight
                                    visible: delegateRoot.fullBody !== ""

                                    Text {
                                        id: hiddenBody
                                        text: delegateRoot.fullBody
                                        width: parent.width
                                        font.family: "JetBrains Mono"
                                        font.weight: Font.Normal
                                        font.pixelSize: 12 * popupWindow.uiScale
                                        wrapMode: Text.Wrap
                                        textFormat: Text.StyledText
                                        visible: false
                                    }

                                    Text {
                                        anchors.fill: parent
                                        text: delegateRoot.fullBody.substring(0, delegateRoot.typeLenBody)
                                        font: hiddenBody.font
                                        color: _theme.subtext0
                                        wrapMode: Text.Wrap
                                        lineHeight: 1.4
                                        textFormat: Text.StyledText
                                    }
                                }
                            }
                        }

                        // Inline action buttons
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.topMargin: delegateRoot.actionArray.length > 0 ? (6 * popupWindow.uiScale) : 0
                            spacing: 6 * popupWindow.uiScale
                            visible: delegateRoot.actionArray.length > 0

                            Repeater {
                                model: delegateRoot.actionArray
                                delegate: Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 28 * popupWindow.uiScale
                                    radius: 6 * popupWindow.uiScale

                                    property bool isPrimary: index === 0

                                    color: {
                                        if (isPrimary) {
                                            return actionMouseArea.containsMouse ? Qt.lighter(_theme.sapphire, 1.15) : Qt.darker(_theme.sapphire, 1.1)
                                        } else {
                                            return actionMouseArea.containsMouse ? _theme.surface2 : _theme.surface1
                                        }
                                    }

                                    Behavior on color { ColorAnimation { duration: 150 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.text || "Action"
                                        font.family: "JetBrains Mono"
                                        font.weight: Font.Bold
                                        font.pixelSize: 11 * popupWindow.uiScale
                                        color: isPrimary ? _theme.crust : _theme.text
                                    }

                                    MouseArea {
                                        id: actionMouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        z: 10

                                        onClicked: {
                                            modelData.invoke();
                                            delegateRoot.notifData.popup = false;
                                        }
                                    }
                                }
                            }
                        }

                        Item { Layout.preferredHeight: Math.round(16 * popupWindow.uiScale) }
                    }
                }
            }
        }
    }
}
