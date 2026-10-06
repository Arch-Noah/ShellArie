pragma Singleton
import QtQuick
import Quickshell.Io
import qs.utils

Item {
    id: root

    property color background: "#08080c"
    property color foreground: "#aaabb2"
    property color secondary: "#413945"
    property color tertiary: "#4e505d"
    
    // Mix with opacity for transparent background
    property color backgroundTransparent: Qt.rgba(8/255, 8/255, 12/255, 0.618)
    
    property color red: Qt.rgba(169/255, 69/255, 69/255, 1.0)
    property color green: Qt.rgba(153/255, 255/255, 153/255, 1.0)
    property color blue: Qt.rgba(102/255, 153/255, 255/255, 1.0)
    property color orange: Qt.rgba(255/255, 139/255, 23/255, 1.0)
    property color yellow: Qt.rgba(255/255, 215/255, 0/255, 1.0)
    
    // UI Constants
    readonly property int borderRadius: 10
    readonly property int pillRadius: 50
    readonly property int barMargin: 5
    readonly property int globalMargin: 5
    readonly property string fontFamily: "sans-serif" // Can be configured later
    
    function mixAlpha(hexColor, alpha) {
        var c = Qt.color(hexColor);
        c.a = alpha;
        return c;
    }

    function applyColors(jsonStr) {
        try {
            var data = JSON.parse(jsonStr);
            if (data.base) root.background = data.base;
            if (data.text) root.foreground = data.text;
            if (data.secondary) root.secondary = data.secondary;
            if (data.tertiary) root.tertiary = data.tertiary;
            if (data.materialRed) root.red = data.materialRed;
            if (data.materialGreen) root.green = data.materialGreen;
            if (data.materialBlue) root.blue = data.materialBlue;
            if (data.materialOrange) root.orange = data.materialOrange;
            if (data.materialYellow) root.yellow = data.materialYellow;
            
            if (data.base) {
                root.backgroundTransparent = root.mixAlpha(data.base, 0.618);
            }
        } catch (e) {
            console.warn("Styles.qml: Failed to parse colors JSON: " + e);
        }
    }

    Process {
        id: readerProcess
        command: ["cat", Paths.colorsFile]
        stdout: SplitParser {
            property string buffer: ""
            onRead: (data) => {
                buffer += data + "\n";
            }
        }
        onRunningChanged: {
            if (!running) {
                if (stdout.buffer.trim() !== "") {
                    applyColors(stdout.buffer);
                }
                stdout.buffer = "";
            }
        }
    }

    Timer {
        id: debounceTimer
        interval: 50
        repeat: false
        onTriggered: {
            if (!readerProcess.running) {
                readerProcess.running = true;
            }
        }
    }

    Process {
        id: watcherProcess
        command: ["inotifywait", "-q", "-m", "-e", "close_write,moved_to,create", "--include", Paths.colorsRegex, Paths.colorsDir]
        running: true
        stdout: SplitParser {
            onRead: (data) => {
                if (data.indexOf(Paths.colorsName) !== -1) {
                    debounceTimer.restart();
                }
            }
        }
    }

    Component.onCompleted: {
        readerProcess.running = true;
    }
}
