import QtQuick
import Quickshell
import Quickshell.Io
import "WindowRegistry.js" as LayoutMath 
import qs.utils

Item {
    id: root
    visible: false

    property real currentWidth: 1920.0
    property real currentHeight: 1080.0 // <-- ADDED
    property real uiScale: 1.0

    // FIXED: Now passes both Width and Height to respect aspect ratio
    property real baseScale: LayoutMath.getScale(currentWidth, currentHeight, uiScale)
    
    function s(val) { 
        return LayoutMath.s(val, baseScale); 
    }

    function applySettings(txt) {
        if (!txt || txt.trim().length === 0)
            return;
        try {
            const parsed = JSON.parse(txt);
            if (parsed.uiScale !== undefined && root.uiScale !== parsed.uiScale)
                root.uiScale = parsed.uiScale;
        } catch (e) {
            console.warn("Scaler: invalid settings.json:", e);
        }
    }

    // Absence du fichier = échelle par défaut, sans erreur
    FileView {
        id: scaleReader
        path: Paths.hyprSettings
        onLoaded: root.applySettings(text())
    }

    // Watcher événementiel sur le dossier (le fichier peut ne pas encore exister),
    // relancé s'il meurt : plus de boucle `sleep 1` active.
    Process {
        id: scaleWatcher
        command: ["inotifywait", "-q", "-m", "-e", "close_write,moved_to,create", "--include",
                  "^" + Paths.hyprSettings.replace(/[.*+?^${}()|[\]\\]/g, "\\$&") + "$", Paths.hyprConfig]
        running: true
        onRunningChanged: if (!running) watcherRestart.start()
        stdout: SplitParser {
            onRead: scaleReader.reload()
        }
    }

    Timer {
        id: watcherRestart
        interval: 2000
        onTriggered: scaleWatcher.running = true
    }
}
