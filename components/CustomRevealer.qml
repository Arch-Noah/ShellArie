import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../commons"

Rectangle {
    id: root
    
    property string iconText: ""
    property string labelText: ""
    property bool isWarning: false
    property string onClickCommand: ""
    property string onRightClickCommand: ""
    property string tooltipText: ""
    
    property bool isHovered: ma.containsMouse
    property bool isExpanded: false
    
    Timer {
        id: expandTimer
        interval: 500
        running: root.isHovered && !root.isExpanded
        onTriggered: root.isExpanded = true
    }
    
    Timer {
        id: collapseTimer
        interval: 100
        running: !root.isHovered && root.isExpanded
        onTriggered: root.isExpanded = false
    }
    
    // Derived properties
    property color baseColor: isWarning ? Styles.yellow : Styles.foreground
    
    height: 30
    radius: Styles.pillRadius
    color: isHovered ? Styles.background : "transparent"
    
    // Smooth hover behavior
    scale: isHovered ? 1.02 : 1.0
    property int offsetY: isHovered ? -2 : 0
    transform: Translate { y: root.offsetY }
    
    Behavior on color { ColorAnimation { duration: 200 } }
    Behavior on scale { NumberAnimation { duration: 200 } }
    Behavior on offsetY { NumberAnimation { duration: 200 } }

    // Width animation for revealer effect handled by inner Layout.preferredWidth
    implicitWidth: layout.implicitWidth + 10 // Padding

    // Delay for expansion (if we want to mimic the exact 500ms timeout)
    // For now, QML Behavior handles the smooth expansion.

    RowLayout {
        id: layout
        anchors.left: parent.left
        anchors.leftMargin: 5
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height
        spacing: 5
        
        Text {
            id: iconElement
            text: root.iconText
            color: root.baseColor
            font.pixelSize: 17
            Layout.alignment: Qt.AlignVCenter
        }

        Item {
            // Clip container for the revealer text
            id: textContainer
            Layout.preferredWidth: root.isExpanded ? labelElement.implicitWidth : 0
            Layout.fillHeight: true
            clip: true
            
            Behavior on Layout.preferredWidth {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutCubic
                }
            }

            Text {
                id: labelElement
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: root.labelText
                color: root.baseColor
                font.pixelSize: 13
                font.bold: true
                visible: root.isExpanded || opacity > 0
                opacity: root.isExpanded ? 1.0 : 0.0
                
                Behavior on opacity {
                    NumberAnimation { duration: 200 }
                }
            }
        }
    }

    Process {
        id: leftClickProcess
        command: ["bash", "-c", root.onClickCommand]
    }
    
    Process {
        id: rightClickProcess
        command: ["bash", "-c", root.onRightClickCommand]
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                if (root.onRightClickCommand !== "") {
                    rightClickProcess.running = true;
                }
            } else {
                if (root.onClickCommand !== "") {
                    leftClickProcess.running = true;
                }
            }
        }
    }
}
