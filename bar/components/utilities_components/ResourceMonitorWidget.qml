import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Io
import "../../commons"
import qs.utils

Rectangle {
    id: root
    
    property var stats: ({
        cpu: { load: 0, clock: 0, temp: 0 },
        ram: { total: 0, used: 0, free: 0, pct: 0 },
        rom: { total: "0", used: "0", free: "0", pct: 0 }
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

    Process {
        id: statsProcess
        command: ["bash", "-c", "cpu_load=$(top -bn1 | grep 'Cpu(s)' | awk '{print $2 + $4}'); cpu_clock=$(lscpu | grep 'MHz' | awk '{print $3/1000}' | head -n1 || echo '0'); cpu_temp=$(cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | head -n1 | awk '{print $1/1000}' || echo '0'); ram_tot=$(free -m | grep Mem | awk '{print $2/1024}'); ram_used=$(free -m | grep Mem | awk '{print $3/1024}'); ram_free=$(free -m | grep Mem | awk '{print $4/1024}'); ram_pct=$(free | grep Mem | awk '{print $3/$2}'); rom_tot=$(df -h / | tail -1 | awk '{print $2}'); rom_used=$(df -h / | tail -1 | awk '{print $3}'); rom_free=$(df -h / | tail -1 | awk '{print $4}'); rom_pct=$(df / | tail -1 | awk '{print $3/$2}'); echo \"{\\\"cpu\\\":{\\\"load\\\":${cpu_load:-0},\\\"clock\\\":${cpu_clock:-0},\\\"temp\\\":${cpu_temp:-0}},\\\"ram\\\":{\\\"total\\\":${ram_tot:-0},\\\"used\\\":${ram_used:-0},\\\"free\\\":${ram_free:-0},\\\"pct\\\":${ram_pct:-0}},\\\"rom\\\":{\\\"total\\\":\\\"${rom_tot:-0}\\\",\\\"used\\\":\\\"${rom_used:-0}\\\",\\\"free\\\":\\\"${rom_free:-0}\\\",\\\"pct\\\":${rom_pct:-0}}}\""]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text) {
                    try {
                        root.stats = JSON.parse(this.text.trim());
                    } catch (e) {
                        console.log("Failed to parse stats:", e);
                    }
                }
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: statsProcess.running = true
    }

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
