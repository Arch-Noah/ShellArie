import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.services
import "../commons"

// Seconde barre collée sous la barre principale : icônes des applications ouvertes.
// Même hauteur que la barre principale, mêmes coins inversés que le dashboard.
Item {
    id: root

    required property var screen
    // Hauteur de la barre principale
    property real barHeight: 40
    // Masquée pendant que le dashboard est ouvert (il occupe la même place)
    property bool suppressed: false
    // Affichage demandé explicitement (raccourci, rofi...)
    property bool forceShow: false

    // Le workspace actif de cet écran n'a aucune fenêtre : on affiche la barre
    // pour pouvoir rejoindre une application ouverte ailleurs.
    readonly property var activeWs: Hyprland.monitorFor(root.screen)?.activeWorkspace ?? null
    readonly property bool onEmptyWorkspace: activeWs !== null
        && !activeWs.name.startsWith("special:")
        && activeWs.toplevels.values.length === 0

    readonly property real notchRadius: 20
    readonly property color fill: Styles.mixAlpha(Styles.background, 0.90)

    function classOf(t) {
        return (t.wayland?.appId || t.lastIpcObject?.class || "").toString();
    }

    // Fenêtres de cet écran, triées par adresse
    readonly property var windows: {
        const out = [];
        const list = Hyprland.toplevels.values;
        for (let i = 0; i < list.length; i++) {
            const t = list[i];
            const mon = t.workspace?.monitor?.name ?? "";
            if (mon !== "" && root.screen && mon !== root.screen.name)
                continue;
            out.push(t);
        }
        out.sort((a, b) => parseInt(a.address, 16) - parseInt(b.address, 16));
        return out;
    }

    // Entrées affichées : d'abord les applications épinglées (même fermées),
    // puis une entrée par fenêtre non épinglée.
    readonly property var items: {
        const out = [];
        const pins = TaskbarPins.pins;
        const wins = windows;
        for (const pin of pins) {
            out.push({
                cls: pin,
                pinned: true,
                windows: wins.filter(t => TaskbarPins.normalize(classOf(t)) === pin)
            });
        }
        for (const t of wins) {
            if (!TaskbarPins.isPinned(classOf(t)))
                out.push({ cls: classOf(t), pinned: false, windows: [t] });
        }
        return out;
    }

    readonly property bool shown: items.length > 0 && !suppressed && (forceShow || onEmptyWorkspace)
    property real reveal: shown ? 1 : 0
    Behavior on reveal { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

    visible: reveal > 0
    implicitWidth: row.implicitWidth + 24 + notchRadius * 2
    implicitHeight: barHeight
    height: barHeight * reveal
    clip: true

    // Va sur le workspace de l'application puis focalise la fenêtre
    function focusWindow(toplevel) {
        const ws = toplevel.workspace;
        if (ws) {
            if (ws.name.startsWith("special:")) {
                if (Hyprland.focusedWorkspace?.name !== ws.name)
                    Hyprland.dispatch(`hl.dsp.workspace.toggle_special('${ws.name.slice(8)}')`);
            } else if (Hyprland.focusedWorkspace?.id !== ws.id) {
                Hyprland.dispatch(`hl.dsp.focus({ workspace = '${ws.id}' })`);
            }
        }
        Hyprland.dispatch(`hl.dsp.focus({ window = 'address:0x${String(toplevel.address).replace(/^0x/, '')}' })`);
    }

    // Clic : lance l'app si elle est fermée, sinon va sur son workspace ;
    // avec plusieurs fenêtres, passe à la suivante à chaque clic.
    function activate(entry) {
        if (entry.windows.length === 0) {
            const de = DesktopEntries.heuristicLookup(entry.cls);
            if (de)
                de.execute();
            else
                console.warn("Taskbar: no desktop entry for", entry.cls);
            return;
        }
        const active = entry.windows.indexOf(Hyprland.activeToplevel);
        focusWindow(entry.windows[(active + 1) % entry.windows.length]);
    }

    Component.onCompleted: Hyprland.refreshToplevels()

    Item {
        id: panel
        width: row.implicitWidth + 24
        height: root.barHeight
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        opacity: root.reveal

        // Fond : coins du haut carrés (collés à la barre), coins du bas arrondis
        Item {
            anchors.fill: parent
            clip: true
            z: -1
            Rectangle {
                y: -Styles.borderRadius * 1.5
                width: parent.width
                height: parent.height + Styles.borderRadius * 1.5
                color: root.fill
                radius: Styles.borderRadius * 1.5
            }
        }

        Item {
            width: root.notchRadius
            height: root.notchRadius
            anchors.right: parent.left
            anchors.top: parent.top
            clip: true
            Rectangle {
                width: root.notchRadius * 4
                height: root.notchRadius * 4
                radius: root.notchRadius * 2
                border.width: root.notchRadius
                border.color: root.fill
                color: "transparent"
                x: -root.notchRadius * 2
                y: -root.notchRadius
            }
        }

        Item {
            width: root.notchRadius
            height: root.notchRadius
            anchors.left: parent.right
            anchors.top: parent.top
            clip: true
            Rectangle {
                width: root.notchRadius * 4
                height: root.notchRadius * 4
                radius: root.notchRadius * 2
                border.width: root.notchRadius
                border.color: root.fill
                color: "transparent"
                x: -root.notchRadius
                y: -root.notchRadius
            }
        }

        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: 10

            Repeater {
                model: root.items

                delegate: Rectangle {
                    id: item
                    required property var modelData
                    readonly property string appClass: modelData.cls
                    readonly property bool running: modelData.windows.length > 0
                    readonly property string iconSource: {
                        // Dépendance réactive : la base des entrées .desktop se charge de façon
                        // asynchrone au démarrage, il faut recalculer l'icône quand elle arrive.
                        const entries = DesktopEntries.applications.values;
                        const icon = (entries.length > 0 ? DesktopEntries.heuristicLookup(appClass)?.icon : null) ?? appClass;
                        return Quickshell.iconPath(icon, true);
                    }
                    readonly property bool isActive: modelData.windows.indexOf(Hyprland.activeToplevel) !== -1

                    // Épinglée mais fermée : atténuée
                    opacity: running ? 1.0 : 0.55

                    Layout.preferredWidth: 30
                    Layout.preferredHeight: 30
                    radius: Styles.borderRadius
                    color: isActive ? Styles.secondary : (ma.containsMouse ? Styles.background : "transparent")
                    Behavior on color { ColorAnimation { duration: 200 } }

                    // Pas d'icône dans le thème : initiale de l'application
                    Text {
                        anchors.centerIn: parent
                        visible: item.iconSource === ""
                        text: (item.appClass || "?").charAt(0).toUpperCase()
                        color: Styles.foreground
                        font.pixelSize: 14
                        font.bold: true
                    }

                    Image {
                        anchors.centerIn: parent
                        visible: item.iconSource !== ""
                        width: 20
                        height: 20
                        sourceSize: Qt.size(40, 40)
                        source: item.iconSource
                        asynchronous: true
                        smooth: true
                    }

                    MouseArea {
                        id: ma
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton)
                                TaskbarPins.toggle(item.appClass);
                            else
                                root.activate(item.modelData);
                        }
                    }
                }
            }
        }
    }
}
