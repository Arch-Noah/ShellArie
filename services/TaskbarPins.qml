pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

// Applications épinglées dans la seconde barre. Liste d'appId (classe de fenêtre)
// sauvegardée sur disque : ~/.local/state/shellarie/taskbar-pins.json, donc elle
// survit aux redémarrages du shell et de la machine.
Singleton {
    id: root

    property var pins: []

    function normalize(id: string): string {
        return (id ?? "").trim().toLowerCase();
    }

    function isPinned(id: string): bool {
        const n = normalize(id);
        return n !== "" && pins.indexOf(n) !== -1;
    }

    function toggle(id: string): void {
        const n = normalize(id);
        if (n === "")
            return;
        const next = pins.slice();
        const i = next.indexOf(n);
        if (i === -1)
            next.push(n);
        else
            next.splice(i, 1);
        pins = next;
        save();
    }

    function save(): void {
        file.setText(JSON.stringify(pins, null, 2) + "\n");
    }

    Component.onCompleted: Quickshell.execDetached(["mkdir", "-p", Paths.shellarieState])

    FileView {
        id: file
        path: Paths.pinsFile
        atomicWrites: true
        printErrors: false
        onLoaded: {
            try {
                const data = JSON.parse(text());
                if (Array.isArray(data))
                    root.pins = data.map(x => root.normalize(String(x))).filter(x => x !== "");
            } catch (e) {
                console.warn("TaskbarPins: invalid", Paths.pinsFile, e);
            }
        }
        onLoadFailed: error => {
            // Premier lancement : pas encore de fichier, ce n'est pas une erreur
            if (error !== FileViewError.FileNotFound)
                console.warn("TaskbarPins: cannot read", Paths.pinsFile, error);
        }
    }
}
