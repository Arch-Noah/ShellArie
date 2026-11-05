import Quickshell

PersistentProperties {
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
    // Centre de notifications (fenêtre détachée, indépendante des panneaux de la barre)
    property bool notifCenter
    property real notifCenterClosedAt
    property bool utilities
    property bool sidebar

    // Un seul des panneaux dashboard / wifi / bluetooth / audio est ouvert à la fois
    onDashboardChanged: if (dashboard) {
        wifi = false;
        bluetooth = false;
        audio = false;
    }
    onWifiChanged: if (wifi) {
        dashboard = false;
        bluetooth = false;
        audio = false;
    }
    onBluetoothChanged: if (bluetooth) {
        dashboard = false;
        wifi = false;
        audio = false;
    }
    onAudioChanged: if (audio) {
        dashboard = false;
        wifi = false;
        bluetooth = false;
    }

    // Dashboard state
    property int dashboardTab
    property date dashboardDate: new Date()
}
