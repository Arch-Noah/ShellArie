import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import "../../commons"

Rectangle {
    id: root
    
    height: 30
    radius: Styles.pillRadius
    color: Styles.foreground
    
    property string timeString: ""
    property string dateString: ""
    
    property bool isHovered: ma.containsMouse
    property bool isPressed: ma.pressed
    
    scale: isPressed ? 0.95 : (isHovered ? 1.02 : 1.0)
    property int offsetY: isPressed ? 0 : (isHovered ? -2 : 0)
    transform: Translate { y: root.offsetY }
    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on offsetY { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    
    Timer {
        interval: 1000 // Update every second to ensure clock ticks over on the exact minute
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            var now = new Date();
            root.timeString = Qt.formatDateTime(now, "HH:mm");
            // Add leading/trailing spaces for visual padding when revealed, similar to AGS " %A ·%e %b %Y "
            root.dateString = Qt.formatDateTime(now, " dddd · d MMM yyyy ");
        }
    }
    
    property int targetDateWidth: dateText.implicitWidth
    property int dateRevealerWidth: isHovered ? targetDateWidth : 0
    Behavior on dateRevealerWidth { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } }
    
    implicitWidth: timeText.implicitWidth + dateRevealerWidth + 30 // padding
    implicitHeight: 30
    
    Row {
        anchors.centerIn: parent
        spacing: 0
        
        Text {
            id: timeText
            text: root.timeString
            color: Styles.background
            font.bold: true
            font.pixelSize: 13
            font.family: "JetBrainsMono NFP"
            anchors.verticalCenter: parent.verticalCenter
        }

        Item {
            // Clip container for the revealer text
            id: dateContainer
            width: root.dateRevealerWidth
            height: timeText.height
            clip: true
            anchors.verticalCenter: parent.verticalCenter

            Text {
                id: dateText
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: root.dateString
                color: Styles.background
                font.pixelSize: 13
                font.bold: true
                font.family: "JetBrainsMono NFP"
                
                // Fade in text as well
                visible: root.isHovered || opacity > 0
                opacity: root.isHovered ? 1.0 : 0.0
                
                Behavior on opacity {
                    NumberAnimation { duration: 200 }
                }
            }
        }
    }
    
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
            var state = ShellState.forActive();
            if (state) {
                state.dashboardTab = 0;
                state.dashboard = true;
            }
        }
    }
}
