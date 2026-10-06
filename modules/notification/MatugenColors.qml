import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

Item {
    id: root

    // ── Catppuccin Mocha (fallback statique) ──────────────────────
    property color base: "#1e1e2e"
    property color mantle: "#181825"
    property color crust: "#11111b"
    property color text: "#cdd6f4"
    property color subtext0: "#a6adc8"
    property color subtext1: "#bac2de"
    property color surface0: "#313244"
    property color surface1: "#45475a"
    property color surface2: "#585b70"
    property color overlay0: "#6c7086"
    property color overlay1: "#7f849c"
    property color overlay2: "#9399b2"
    property color blue: "#89b4fa"
    property color sapphire: "#74c7ec"
    property color peach: "#fab387"
    property color green: "#a6e3a1"
    property color red: "#f38ba8"
    property color mauve: "#cba6f7"
    property color pink: "#f5c2e7"
    property color yellow: "#f9e2af"
    property color maroon: "#eba0ac"
    property color teal: "#94e2d5"

    // ── φ-derived : baseTransparent (inchangé, déjà golden ratio) ─
    property color baseTransparent: Qt.rgba(
        base.r * 0.382 + surface0.r * 0.618,
        base.g * 0.382 + surface0.g * 0.618,
        base.b * 0.382 + surface0.b * 0.618,
        1.0
    )

    // ── φ-derived : nouvelles propriétés (comme AGS colors.scss) ──
    property color secondary: "#585b70"
    property color tertiary: "#6c7086"
    property color backgroundSecondary: "#313244"
    property color foregroundSecondary: "#cdd6f4"
    property color backgroundTertiary: "#313244"
    property color foregroundTertiary: "#cdd6f4"
    property color backgroundAlt: "#1e1e2e"
    property color foregroundAlt: "#cdd6f4"
    property color borderColor: Qt.rgba(text.r, text.g, text.b, 0.1)
    property color spotify: "#1e1e2e"
    property color materialBlue: "#1e1e2e"
    property color materialGreen: "#1e1e2e"
    property color materialRed: "#1e1e2e"
    property color materialOrange: "#1e1e2e"
    property color materialYellow: "#1e1e2e"

    // ── JSON bridge ───────────────────────────────────────────────
    property string rawJson: ""

    // Lecteur : cat Paths.colorsFile
    Process {
        id: themeReader
        command: ["cat", Paths.colorsFile]
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt !== "" && txt !== root.rawJson) {
                    root.rawJson = txt;
                    try {
                        let c = JSON.parse(txt);
                        if (c.base) root.base = c.base;
                        if (c.mantle) root.mantle = c.mantle;
                        if (c.crust) root.crust = c.crust;
                        if (c.text) root.text = c.text;
                        if (c.subtext0) root.subtext0 = c.subtext0;
                        if (c.subtext1) root.subtext1 = c.subtext1;
                        if (c.surface0) root.surface0 = c.surface0;
                        if (c.surface1) root.surface1 = c.surface1;
                        if (c.surface2) root.surface2 = c.surface2;
                        if (c.overlay0) root.overlay0 = c.overlay0;
                        if (c.overlay1) root.overlay1 = c.overlay1;
                        if (c.overlay2) root.overlay2 = c.overlay2;
                        if (c.blue) root.blue = c.blue;
                        if (c.sapphire) root.sapphire = c.sapphire;
                        if (c.peach) root.peach = c.peach;
                        if (c.green) root.green = c.green;
                        if (c.red) root.red = c.red;
                        if (c.mauve) root.mauve = c.mauve;
                        if (c.pink) root.pink = c.pink;
                        if (c.yellow) root.yellow = c.yellow;
                        if (c.maroon) root.maroon = c.maroon;
                        if (c.teal) root.teal = c.teal;
                        // φ-derived
                        if (c.secondary) root.secondary = c.secondary;
                        if (c.tertiary) root.tertiary = c.tertiary;
                        if (c.backgroundSecondary) root.backgroundSecondary = c.backgroundSecondary;
                        if (c.foregroundSecondary) root.foregroundSecondary = c.foregroundSecondary;
                        if (c.backgroundTertiary) root.backgroundTertiary = c.backgroundTertiary;
                        if (c.foregroundTertiary) root.foregroundTertiary = c.foregroundTertiary;
                        if (c.backgroundAlt) root.backgroundAlt = c.backgroundAlt;
                        if (c.foregroundAlt) root.foregroundAlt = c.foregroundAlt;
                        if (c.spotify) root.spotify = c.spotify;
                        if (c.materialBlue) root.materialBlue = c.materialBlue;
                        if (c.materialGreen) root.materialGreen = c.materialGreen;
                        if (c.materialRed) root.materialRed = c.materialRed;
                        if (c.materialOrange) root.materialOrange = c.materialOrange;
                        if (c.materialYellow) root.materialYellow = c.materialYellow;
                    } catch(e) {
                        console.log("MatugenColors: JSON parse error", e);
                    }
                }
            }
        }
    }

    // Watcher événementiel (inotifywait) — remplace l'ancien Timer polling
    Process {
        id: themeWatcher
        command: ["inotifywait", "-q", "-m", "-e", "close_write,moved_to,create", Paths.colorsDir]
        running: true
        stdout: SplitParser {
            onRead: (data) => {
                if (data.indexOf(Paths.colorsName) !== -1) {
                    themeReader.running = false;
                    themeReader.running = true;
                }
            }
        }
    }

    Component.onCompleted: {
        themeReader.running = true;
    }
}
