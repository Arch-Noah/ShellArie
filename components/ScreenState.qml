import Quickshell

PersistentProperties {
    id: root

    required property ShellScreen modelData

    // Drawer visibilities
    property bool bar
    property bool osd
    property bool session
    property bool launcher
    property bool dashboard
    property bool wifi
    property bool bluetooth
    property bool audio
    property bool battery
    // Centre de notifications (fenêtre détachée, indépendante des panneaux de la barre)
    property bool notifCenter
    property real notifCenterClosedAt
    property bool utilities
    property bool sidebar

    // Un seul des panneaux de la barre est ouvert à la fois
    readonly property var barPanels: ["dashboard", "wifi", "bluetooth", "audio", "battery"]

    function closeOthers(name: string): void {
        for (const n of barPanels) {
            if (n !== name && root[n])
                root[n] = false;
        }
    }

    onDashboardChanged: if (dashboard)
        closeOthers("dashboard")
    onWifiChanged: if (wifi)
        closeOthers("wifi")
    onBluetoothChanged: if (bluetooth)
        closeOthers("bluetooth")
    onAudioChanged: if (audio)
        closeOthers("audio")
    onBatteryChanged: if (battery)
        closeOthers("battery")

    // Dashboard state
    property int dashboardTab
    property date dashboardDate: new Date()
}
