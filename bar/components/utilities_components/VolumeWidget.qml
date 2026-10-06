import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Io
import "../../commons"
import qs.utils

Rectangle {
    id: root
    
    property int volumePct: 0
    property bool isMuted: false
    property string desc: ""
    
    property bool isHovered: ma.containsMouse || volSlider.hovered || volSlider.pressed
    property bool isExpanded: false
    
    // For auto-reveal on volume change
    property int lastPct: volumePct
    
    onVolumePctChanged: {
        if (volumePct !== lastPct) {
            lastPct = volumePct;
            if (!isHovered) {
                isExpanded = true;
                autoHideTimer.restart();
            }
        }
    }
    
    Timer {
        id: autoHideTimer
        interval: 2000
        onTriggered: {
            if (!root.isHovered) root.isExpanded = false;
        }
    }
    
    Timer {
        id: expandTimer
        interval: 500
        running: root.isHovered && !root.isExpanded
        onTriggered: root.isExpanded = true
    }
    
    Timer {
        id: collapseTimer
        interval: 500
        running: !root.isHovered && root.isExpanded && !autoHideTimer.running
        onTriggered: root.isExpanded = false
    }
    
    Process {
        id: volMonitor
        command: ["bash", "-c", "get_vol() { VOL=$(wpctl get-volume @DEFAULT_AUDIO_SINK@); V=$(echo \"$VOL\" | awk '{print $2}'); if echo \"$VOL\" | grep -q \"MUTED\"; then M=\"MUTED\"; else M=\"UNMUTED\"; fi; DESC=$(pactl get-default-sink); echo \"$V|$M|$DESC\"; }; get_vol; pactl subscribe | grep --line-buffered \"sink\" | while read -r line; do get_vol; done"]
        running: true
        stdout: SplitParser {
            onRead: function(data) {
                var lines = data.split("\n");
                for (var i = 0; i < lines.length; i++) {
                    var val = lines[i].trim();
                    if (val === "") continue;
                    var parts = val.split("|");
                    if (parts.length >= 3) {
                        var v = parseFloat(parts[0]);
                        if (!isNaN(v)) {
                            if (!volSlider.pressed) {
                                root.volumePct = Math.round(v * 100);
                            }
                        }
                        root.isMuted = (parts[1] === "MUTED");
                        root.desc = parts[2].toLowerCase();
                    }
                }
            }
        }
    }
    
    Process {
        id: volSetter
        property int targetPct: 50
        command: ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", targetPct + "%"]
        running: false
    }
    
    implicitWidth: layout.implicitWidth + 10
    height: 30
    radius: Styles.pillRadius
    color: root.isHovered ? Styles.background : "transparent"
    
    scale: ma.pressed ? 0.95 : (root.isHovered ? 1.02 : 1.0)
    property int offsetY: ma.pressed ? 0 : (root.isHovered ? -2 : 0)
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
                if (root.desc.indexOf("headphone") !== -1 || root.desc.indexOf("casque") !== -1) {
                    return "󰋋";
                }
                return root.isMuted || root.volumePct === 0 ? "󰝟" : "󰕾";
            }
            color: Styles.foreground
            font.pixelSize: 17
            Layout.alignment: Qt.AlignVCenter
        }
        
        Text {
            id: labelElement
            text: root.volumePct + "%"
            color: Styles.foreground
            font.pixelSize: 13
            font.bold: true
            Layout.alignment: Qt.AlignVCenter
        }
        
        Item {
            id: sliderContainer
            Layout.preferredWidth: root.isExpanded ? 75 : 0
            Layout.fillHeight: true
            clip: true
            
            Behavior on Layout.preferredWidth {
                NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
            }
            
            RowLayout {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 5
                
                Slider {
                    id: volSlider
                    Layout.preferredWidth: 70
                    from: 0
                    to: 100
                    value: root.volumePct
                    
                    onMoved: {
                        root.volumePct = Math.round(value);
                        volSetter.targetPct = root.volumePct;
                        volSetter.running = true;
                    }
                    
                    background: Rectangle {
                        x: volSlider.leftPadding
                        y: volSlider.topPadding + volSlider.availableHeight / 2 - height / 2
                        implicitWidth: 70
                        implicitHeight: 10
                        width: volSlider.availableWidth
                        height: implicitHeight
                        radius: 2
                        color: Styles.backgroundTransparent

                        Rectangle {
                            width: volSlider.visualPosition * parent.width
                            height: parent.height
                            color: Styles.secondary
                            radius: 2
                        }
                    }
                    
                    handle: Item {
                        x: volSlider.leftPadding + volSlider.visualPosition * (volSlider.availableWidth - width)
                        y: volSlider.topPadding + volSlider.availableHeight / 2 - height / 2
                        width: 0
                        height: 0
                    }
                    
                    visible: root.isExpanded || opacity > 0
                    opacity: root.isExpanded ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }
            }
        }
    }
    
    Process {
        id: clickProcess
        command: [Paths.qsManager, "toggle", "volume"]
    }
    
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        propagateComposedEvents: true
        onPressed: mouse.accepted = false
        onReleased: mouse.accepted = false
        onClicked: clickProcess.running = true
        z: -1
    }
}
