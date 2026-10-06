import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Io
import "../../commons"

Rectangle {
    id: root
    
    property int brightnessPct: 0
    property bool hasBacklight: true
    property bool isHovered: ma.containsMouse || brightSlider.hovered || brightSlider.pressed
    property bool isExpanded: false
    
    // For auto-reveal on brightness change
    property int lastPct: brightnessPct
    
    onBrightnessPctChanged: {
        if (brightnessPct !== lastPct) {
            lastPct = brightnessPct;
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
    
    visible: hasBacklight
    
    Process {
        id: brightMonitor
        command: ["bash", "-c", "DIR=$(ls -1 /sys/class/backlight | head -n1); if [ -z \"$DIR\" ]; then echo 'NO_BACKLIGHT'; exit 0; fi; MAX=$(cat /sys/class/backlight/$DIR/max_brightness); while true; do CUR=$(cat /sys/class/backlight/$DIR/brightness); echo $(( CUR * 100 / MAX )); inotifywait -q -e modify /sys/class/backlight/$DIR/brightness >/dev/null 2>&1; done"]
        running: true
        stdout: SplitParser {
            onRead: function(data) {
                var lines = data.split("\n");
                for (var i = 0; i < lines.length; i++) {
                    var val = lines[i].trim();
                    if (val === "") continue;
                    if (val === "NO_BACKLIGHT") {
                        root.hasBacklight = false;
                    } else {
                        root.hasBacklight = true;
                        var p = parseInt(val);
                        if (!isNaN(p)) {
                            // Don't update if slider is currently being dragged to avoid fighting
                            if (!brightSlider.pressed) {
                                root.brightnessPct = p;
                            }
                        }
                    }
                }
            }
        }
    }
    
    Process {
        id: brightSetter
        property int targetPct: 50
        command: ["brightnessctl", "s", targetPct + "%", "-q"]
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
                if (root.brightnessPct > 75) return "󰃠";
                if (root.brightnessPct > 50) return "󰃟";
                return "󰃞";
            }
            color: Styles.foreground
            font.pixelSize: 17
            Layout.alignment: Qt.AlignVCenter
        }
        
        Text {
            id: labelElement
            text: root.brightnessPct + "%"
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
                    id: brightSlider
                    Layout.preferredWidth: 70
                    from: 0
                    to: 100
                    value: root.brightnessPct
                    
                    onMoved: {
                        root.brightnessPct = Math.round(value);
                        brightSetter.targetPct = root.brightnessPct;
                        brightSetter.running = true;
                    }
                    
                    background: Rectangle {
                        x: brightSlider.leftPadding
                        y: brightSlider.topPadding + brightSlider.availableHeight / 2 - height / 2
                        implicitWidth: 70
                        implicitHeight: 10
                        width: brightSlider.availableWidth
                        height: implicitHeight
                        radius: 2
                        color: Styles.backgroundTransparent

                        Rectangle {
                            width: brightSlider.visualPosition * parent.width
                            height: parent.height
                            color: Styles.secondary
                            radius: 2
                        }
                    }
                    
                    handle: Item {
                        x: brightSlider.leftPadding + brightSlider.visualPosition * (brightSlider.availableWidth - width)
                        y: brightSlider.topPadding + brightSlider.availableHeight / 2 - height / 2
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
    
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        
        // Pass slider interactions to the Slider below!
        // For QML MouseArea covering a Slider, we usually don't want to cover the Slider directly,
        // or we need to allow events to pass through, but wait...
        // Actually, placing the MouseArea under the RowLayout is better, but since it's the root item's area,
        // putting it above the Slider consumes clicks.
        // Let's modify its layout so it's a sibling that acts as a background hover catcher.
        z: -1
    }
}
