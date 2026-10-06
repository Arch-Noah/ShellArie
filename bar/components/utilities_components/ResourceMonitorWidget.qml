import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Io
import "../../commons"
import qs.utils
import qs.services

Rectangle {
    id: root
    
    // Données fournies par le démon metricd (voir services/Metricd.qml)
    readonly property var stats: ({
        cpu: { load: Metricd.cpuPercent },
        ram: { pct: Metricd.memPercent / 100 },
        rom: { pct: Metricd.diskPercent / 100 }
    })
    
    property bool isHovered: ma.containsMouse
    
    implicitWidth: layout.implicitWidth + 20
    height: 30
    radius: Styles.pillRadius
    color: isHovered ? Styles.background : "transparent"
    
    scale: ma.pressed ? 0.95 : (isHovered ? 1.02 : 1.0)
    property int offsetY: ma.pressed ? 0 : (isHovered ? -2 : 0)
    transform: Translate { y: root.offsetY }
    
    Behavior on color { ColorAnimation { duration: 200 } }
    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on offsetY { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 10
        
        CircularProgress {
            value: root.stats.cpu.load / 100.0
            icon: ""
            MouseArea { id: cpuMa; anchors.fill: parent; hoverEnabled: true }
        }
        
        CircularProgress {
            value: root.stats.ram.pct
            icon: "󰍛"
            MouseArea { id: ramMa; anchors.fill: parent; hoverEnabled: true }
        }
        
        CircularProgress {
            value: root.stats.rom.pct
            icon: "󰋊"
            MouseArea { id: romMa; anchors.fill: parent; hoverEnabled: true }
        }
    }
    
    Process {
        id: clickProcess
        command: [Paths.qsManager, "toggle", "focustime"]
    }
    
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        propagateComposedEvents: true
        z: -1
        onClicked: clickProcess.running = true
    }
}
