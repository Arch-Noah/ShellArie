pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

// Client unique du démon metricd (socket Unix, flux JSON ligne par ligne).
// Tous les widgets lisent ces propriétés au lieu d'ouvrir leur propre connexion.
Singleton {
    id: root

    property real cpuPercent: 0
    property real memPercent: 0
    property real diskPercent: 0
    // Débit de l'interface principale (celle qui a le plus de trafic cumulé), en ko/s
    property real uploadKBs: 0
    property real downloadKBs: 0

    function handleMessage(msg: var): void {
        switch (msg.type) {
        case "cpu":
            cpuPercent = msg.cpu_usage_percent ?? 0;
            break;
        case "memory":
            memPercent = msg.used_percent ?? 0;
            break;
        case "disk": {
            const fs = (msg.filesystems ?? []).find(f => f.mount === "/");
            if (fs)
                diskPercent = fs.used_percent ?? 0;
            break;
        }
        case "network": {
            const ifaces = (msg.interfaces ?? []).filter(i => i.name !== "lo");
            if (ifaces.length === 0)
                break;
            const total = i => (i.tx_bytes_cumulative || 0) + (i.rx_bytes_cumulative || 0);
            const main = ifaces.reduce((a, b) => total(b) > total(a) ? b : a);
            uploadKBs = (main.upload_speed_bps || 0) / 1024;
            downloadKBs = (main.download_speed_bps || 0) / 1024;
            break;
        }
        }
    }

    Process {
        id: proc
        command: ["nc", "-U", Paths.metricdSocket]
        running: true
        // Relance si metricd redémarre
        onRunningChanged: if (!running) restartTimer.start()

        stdout: SplitParser {
            onRead: data => {
                const line = data.trim();
                if (line === "")
                    return;
                try {
                    root.handleMessage(JSON.parse(line));
                } catch (e) {
                    // ligne partielle : ignorée
                }
            }
        }
    }

    Timer {
        id: restartTimer
        interval: 2000
        onTriggered: root.restart()
    }

    function restart(): void {
        proc.running = true;
    }
}
