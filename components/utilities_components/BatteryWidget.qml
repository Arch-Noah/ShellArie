import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import Quickshell.Io
import "../../commons"

Rectangle {
    id: root
    
    // Check if battery exists
    visible: UPower.displayDevice !== null
    
    property var device: UPower.displayDevice
    property real percentage: device ? device.percentage : 0
    property int percentInt: Math.floor(percentage * 100)
    property bool isCharging: device ? (device.state === UPowerDeviceState.Charging) : false
    
    // Color logic
    property color contentColor: {
        if (isCharging) return Styles.green;
        if (percentInt <= 10) return Styles.red;
        if (percentInt <= 20) return Styles.yellow;
        return Styles.foreground;
    }
    
    property string activeProfile: "Balanced"
    
    // Fetch power profile for tooltip
    Process {
        command: ["powerprofilesctl", "get"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text) {
                    root.activeProfile = this.text.trim();
                }
            }
        }
    }
    
    // Dimensions and style
    implicitWidth: layout.implicitWidth + 10 // Padding
    height: 30
    radius: Styles.pillRadius
    color: ma.containsMouse ? Styles.background : "transparent"
    
    scale: ma.pressed ? 0.95 : (ma.containsMouse ? 1.02 : 1.0)
    property int offsetY: ma.pressed ? 0 : (ma.containsMouse ? -2 : 0)
    transform: Translate { y: root.offsetY }
    
    Behavior on color { ColorAnimation { duration: 200 } }
    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on offsetY { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 5
        
        Text {
            id: iconElement
            text: {
                if (root.isCharging) return "󰂄";
                var icons = ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"];
                var index = Math.floor(root.percentInt / 10);
                return icons[Math.min(index, 10)];
            }
            color: root.contentColor
            font.pixelSize: 17
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            id: labelElement
            text: root.percentInt + "%"
            color: root.contentColor
            font.pixelSize: 13
            font.bold: true
            Layout.alignment: Qt.AlignVCenter
        }
    }
    
    Process {
        id: clickProcess
        command: ["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle battery"]
    }
    
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        onClicked: clickProcess.running = true
    }
}
