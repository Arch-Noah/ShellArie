import QtQuick
import Quickshell.Io
import "../" // Import CustomRevealer

// Active / désactive hypridle (mise en veille automatique : luminosité, verrouillage, extinction écran).
CustomRevealer {
    id: root

    property bool idleEnabled: true

    iconText: idleEnabled ? "󰒲" : "󰒳"
    labelText: idleEnabled ? "Auto-idle on" : "Auto-idle off"
    isWarning: !idleEnabled

    Process {
        id: idleProcess
        command: ["pidof", "hypridle"]
        running: true
        onExited: (exitCode) => root.idleEnabled = (exitCode === 0)
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: idleProcess.running = true
    }

    onClickCommand: "if pidof hypridle >/dev/null; then pkill -x hypridle; else setsid -f hypridle >/dev/null 2>&1; fi"
}
