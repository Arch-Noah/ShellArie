import QtQuick
import Quickshell
import Caelestia.Config
import qs.services

Scope {
    Component.onCompleted: {
        // Force certain singletons to load on shell init instead of lazily

        IdleInhibitor;
        GameMode;
        Notifs;
        Players;

        if (GlobalConfig.utilities.vpn.enabled)
            VPN;
    }

    Timer {
        interval: 2000
        running: true
        repeat: false
        onTriggered: Weather.reload()
    }
}
