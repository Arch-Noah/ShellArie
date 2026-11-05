pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import qs.components
import qs.components.panel
import qs.services

// Panneau Batterie : tuiles d'uptime, déconnexion, grande jauge circulaire.
Item {
    id: root

    required property ScreenState screenState

    readonly property var device: UPower.displayDevice
    readonly property bool present: !!device && device.isPresent
    readonly property real pct: present ? Math.max(0, Math.min(1, device.percentage)) : 0
    readonly property string stateName: present ? UPowerDeviceState.toString(device.state) : ""
    readonly property bool charging: stateName === "Charging" || stateName === "PendingCharge"
    readonly property bool full: stateName === "FullyCharged"
    readonly property bool low: !charging && !full && pct <= 0.2

    // Couleur de l'anneau selon l'état
    readonly property color ringColor: {
        if (charging || full)
            return Colours.palette.m3tertiary;
        if (pct <= 0.2)
            return Colours.palette.m3error;
        if (pct <= 0.4)
            return "#f9c74f";
        return Colours.palette.m3primary;
    }

    // Pourcentage animé vers la valeur réelle
    property real animPct: 0
    Behavior on animPct {
        NumberAnimation {
            duration: 900
            easing.type: Easing.OutCubic
        }
    }
    onPctChanged: animPct = pct
    Component.onCompleted: {
        animPct = pct;
        forceActiveFocus();
        uptimeFile.reload();
    }

    // Uptime
    property int upHours
    property int upMins

    FileView {
        id: uptimeFile
        path: "/proc/uptime"
        onLoaded: {
            const sec = parseInt(text().split(" ")[0] ?? 0);
            root.upHours = Math.floor(sec / 3600);
            root.upMins = Math.floor((sec % 3600) / 60);
        }
    }

    Timer {
        interval: 15000
        running: true
        repeat: true
        onTriggered: uptimeFile.reload()
    }

    implicitWidth: 340
    implicitHeight: content.implicitHeight + 28
    clip: true

    focus: true
    Keys.onEscapePressed: screenState.battery = false

    function stateText(): string {
        switch (stateName) {
        case "Charging":
        case "PendingCharge":
            return qsTr("EN CHARGE");
        case "Discharging":
        case "PendingDischarge":
            return qsTr("EN DÉCHARGE");
        case "FullyCharged":
            return qsTr("CHARGÉE");
        case "Empty":
            return qsTr("VIDE");
        default:
            return qsTr("INCONNU");
        }
    }

    function durationText(sec: real): string {
        const minutes = Math.round(sec / 60);
        if (minutes <= 0)
            return "";
        const h = Math.floor(minutes / 60);
        const m = minutes % 60;
        return h > 0 ? h + " h " + String(m).padStart(2, "0") : m + " min";
    }

    function infoText(): string {
        if (!present)
            return "";
        const parts = [];
        if (charging) {
            const t = durationText(device.timeToFull);
            if (t)
                parts.push(t + " " + qsTr("avant pleine charge"));
        } else if (!full) {
            const t = durationText(device.timeToEmpty);
            if (t)
                parts.push(t + " " + qsTr("restantes"));
        }
        const w = Math.abs(device.changeRate);
        if (w > 0.1)
            parts.push(Math.round(w) + " W");
        return parts.join(" · ");
    }

    function batteryIcon(): string {
        if (charging)
            return "battery_charging_full";
        if (pct >= 0.95)
            return "battery_full";
        if (pct >= 0.8)
            return "battery_6_bar";
        if (pct >= 0.65)
            return "battery_5_bar";
        if (pct >= 0.5)
            return "battery_4_bar";
        if (pct >= 0.35)
            return "battery_3_bar";
        if (pct >= 0.2)
            return "battery_2_bar";
        if (pct >= 0.1)
            return "battery_1_bar";
        return "battery_alert";
    }

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: 14
        spacing: 8

        // --- Ligne du haut : uptime et déconnexion ---
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: [
                    {
                        value: root.upHours,
                        label: "HR",
                        accent: Colours.palette.m3primary
                    },
                    {
                        value: root.upMins,
                        label: "MIN",
                        accent: Colours.palette.m3secondary
                    }
                ]

                delegate: RowLayout {
                    id: tile

                    required property int index
                    required property var modelData

                    spacing: 6

                    PanelText {
                        visible: tile.index === 1
                        text: ":"
                        size: 13
                        weight: Font.Bold
                        color: Colours.palette.m3onSurfaceVariant
                    }

                    Rectangle {
                        implicitWidth: Math.max(46, valueText.implicitWidth + 20)
                        implicitHeight: 46
                        radius: 12
                        color: Qt.alpha(tile.modelData.accent, 0.1)

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 0

                            PanelText {
                                id: valueText
                                text: String(tile.modelData.value).padStart(2, "0")
                                size: 15
                                weight: Font.Bold
                                color: tile.modelData.accent
                                Layout.alignment: Qt.AlignHCenter
                            }

                            PanelText {
                                text: tile.modelData.label
                                size: 6.5
                                weight: Font.Bold
                                color: Colours.palette.m3onSurfaceVariant
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }

            // Déconnexion : un premier clic demande confirmation
            PanelButton {
                id: logout
                property bool confirming

                icon: confirming ? "" : "logout"
                text: confirming ? qsTr("Confirmer ?") : ""
                tint: confirming ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                filled: confirming
                onTint: Colours.palette.m3onError
                textSize: 8.5
                implicitHeight: 30
                onClicked: {
                    if (confirming) {
                        confirming = false;
                        Quickshell.execDetached(["hyprctl", "dispatch", "exit"]);
                    } else {
                        confirming = true;
                        confirmTimer.restart();
                    }
                }

                Timer {
                    id: confirmTimer
                    interval: 3000
                    onTriggered: logout.confirming = false
                }
            }
        }

        // --- Jauge circulaire ---
        Item {
            id: gauge
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 6
            implicitWidth: 230
            implicitHeight: 230

            // Cercle décoratif extérieur
            Rectangle {
                anchors.centerIn: parent
                width: parent.width + 36
                height: width
                radius: width / 2
                color: "transparent"
                border.width: 1
                border.color: Qt.alpha(Colours.palette.m3onSurface, 0.06)
            }

            // Halo qui bat en charge
            Rectangle {
                id: halo
                anchors.centerIn: parent
                width: parent.width + 12
                height: width
                radius: width / 2
                color: "transparent"
                border.width: 2
                border.color: Qt.alpha(root.ringColor, 0.25)
                visible: root.present && (root.charging || root.low)
                opacity: 0.2

                SequentialAnimation on opacity {
                    running: halo.visible
                    loops: Animation.Infinite

                    NumberAnimation {
                        to: 0.8
                        duration: 1100
                        easing.type: Easing.InOutSine
                    }

                    NumberAnimation {
                        to: 0.15
                        duration: 1100
                        easing.type: Easing.InOutSine
                    }
                }
            }

            Canvas {
                id: ring
                anchors.fill: parent

                readonly property real value: root.animPct
                readonly property color arc: root.ringColor
                readonly property color track: Qt.alpha(Colours.palette.m3onSurface, 0.1)

                onValueChanged: requestPaint()
                onArcChanged: requestPaint()
                onTrackChanged: requestPaint()

                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    const lw = 16;
                    const cx = width / 2;
                    const cy = height / 2;
                    const r = Math.min(width, height) / 2 - lw;

                    // Disque intérieur
                    ctx.fillStyle = Qt.rgba(0, 0, 0, 0.35);
                    ctx.beginPath();
                    ctx.arc(cx, cy, r - lw / 2 - 4, 0, 2 * Math.PI);
                    ctx.fill();

                    ctx.lineWidth = lw;
                    ctx.lineCap = "round";

                    // Piste
                    ctx.strokeStyle = track;
                    ctx.beginPath();
                    ctx.arc(cx, cy, r, 0, 2 * Math.PI);
                    ctx.stroke();

                    // Arc de charge, depuis midi, dans le sens horaire
                    if (value > 0.001) {
                        ctx.strokeStyle = arc;
                        ctx.beginPath();
                        ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + value * 2 * Math.PI);
                        ctx.stroke();
                    }
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                visible: root.present
                spacing: 2

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 6

                    PanelIcon {
                        text: root.batteryIcon()
                        size: 22
                        color: root.ringColor
                        Layout.alignment: Qt.AlignVCenter
                    }

                    PanelText {
                        text: Math.round(root.animPct * 100) + "%"
                        size: 32
                        weight: Font.Bold
                        color: Qt.lighter(root.ringColor, 1.25)
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                PanelText {
                    text: root.stateText()
                    size: 8
                    weight: Font.Bold
                    color: Colours.palette.m3onSurfaceVariant
                    Layout.alignment: Qt.AlignHCenter
                }
            }

            // Pas de batterie
            ColumnLayout {
                anchors.centerIn: parent
                visible: !root.present
                spacing: 6

                PanelIcon {
                    text: "battery_unknown"
                    size: 30
                    color: Colours.palette.m3onSurfaceVariant
                    Layout.alignment: Qt.AlignHCenter
                }

                PanelText {
                    text: qsTr("Aucune batterie")
                    color: Colours.palette.m3onSurfaceVariant
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }

        // --- Autonomie et puissance ---
        PanelText {
            visible: root.infoText() !== ""
            text: root.infoText()
            size: 9
            color: Colours.palette.m3onSurfaceVariant
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 2
            Layout.bottomMargin: 4
        }
    }
}
