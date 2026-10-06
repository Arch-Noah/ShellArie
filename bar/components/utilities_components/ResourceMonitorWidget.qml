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

    // CPU / RAM : lecture directe de /proc (pas de processus externe)
    property var _prevCpu: null

    FileView { id: cpuFile; path: "/proc/stat" }
    FileView { id: memFile; path: "/proc/meminfo" }

    function updateCpuRam() {
        cpuFile.reload();
        memFile.reload();
        const cpuLine = (cpuFile.text() || "").split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
        const mem = memFile.text() || "";
        const next = JSON.parse(JSON.stringify(stats));

        if (cpuLine.length >= 5) {
            const idle = cpuLine[3] + cpuLine[4];
            const total = cpuLine.reduce((x, y) => x + y, 0);
            if (_prevCpu && total > _prevCpu.total)
                next.cpu.load = 100 * (1 - (idle - _prevCpu.idle) / (total - _prevCpu.total));
            _prevCpu = { idle: idle, total: total };
        }

        const memTotal = /MemTotal:\s+(\d+)/.exec(mem);
        const memAvail = /MemAvailable:\s+(\d+)/.exec(mem);
        if (memTotal && memAvail) {
            const t = Number(memTotal[1]);
            next.ram.total = t / 1048576;
            next.ram.used = (t - Number(memAvail[1])) / 1048576;
            next.ram.free = Number(memAvail[1]) / 1048576;
            next.ram.pct = (t - Number(memAvail[1])) / t;
        }
        stats = next;
    }

    // Disque : change rarement, df est lancé seulement toutes les 30 s
    Process {
        id: diskProcess
        command: ["df", "-P", "/"]
        stdout: StdioCollector {
            onStreamFinished: {
                const cols = (this.text.trim().split("\n")[1] || "").trim().split(/\s+/);
                if (cols.length >= 5 && Number(cols[1]) > 0) {
                    const next = JSON.parse(JSON.stringify(root.stats));
                    next.rom.pct = Number(cols[2]) / Number(cols[1]);
                    root.stats = next;
                }
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.updateCpuRam()
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: diskProcess.running = true
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
