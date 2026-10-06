import QtQuick
import Quickshell
import Quickshell.Io
import "../" // Import CustomRevealer

CustomRevealer {
    id: root
    
    iconText: "󱗼"
    labelText: tsConnected ? "Connected" : "Disconnected"
    
    property bool tsConnected: false
    
    Process {
        id: tsProcess
        command: ["bash", "-c", "export LC_ALL=C; out=$(tailscale status 2>/dev/null); if [ -z \"$out\" ] || echo \"$out\" | grep -iqE 'stopped|not logged in|tailscaled|no state'; then echo 'no'; else echo 'yes'; fi"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text) {
                    root.tsConnected = (this.text.trim() === 'yes');
                }
            }
        }
    }
    
    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: tsProcess.running = true
    }
    
    onClickCommand: "if [ \"$(tailscale status 2>/dev/null | grep -iE 'stopped|not logged in')\" ]; then tailscale up; else tailscale down; fi; sleep 1"
    onRightClickCommand: "xdg-open https://login.tailscale.com/admin/machines"
}
