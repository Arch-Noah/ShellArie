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
    property bool utilities
    property bool sidebar

    // Un seul des panneaux dashboard / wifi / bluetooth est ouvert à la fois
    onDashboardChanged: if (dashboard) {
        wifi = false;
        bluetooth = false;
    }
    onWifiChanged: if (wifi) {
        dashboard = false;
        bluetooth = false;
    }
    onBluetoothChanged: if (bluetooth) {
        dashboard = false;
        wifi = false;
    }

    // Dashboard state
    property int dashboardTab
    property date dashboardDate: new Date()
}
