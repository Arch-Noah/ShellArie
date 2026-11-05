import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.utils
import qs.components
import Caelestia
import Caelestia.Config
import "bar" as Bar
import "components"
import "modules"
import "modules/notification"
import "modules/notifcenter"

Scope {
    id: root

    Binding {
        target: ShellState
        property: "shellRoot"
        value: root
    }

    GSFLoader {}
    ServiceLoader {}
    
    IpcHandler {
        target: "dashboard"
        function toggle(): void {
            const state = ShellState.forActive();
            if (state) state.dashboard = !state.dashboard;
        }
        function showTab(index: int): void {
            const state = ShellState.forActive();
            if (state) {
                state.dashboardTab = index;
                state.dashboard = true;
            }
        }
    }

    IpcHandler {
        target: "wifi"
        function toggle(): void {
            const state = ShellState.forActive();
            if (state) state.wifi = !state.wifi;
        }
    }

    IpcHandler {
        target: "bluetooth"
        function toggle(): void {
            const state = ShellState.forActive();
            if (state) state.bluetooth = !state.bluetooth;
        }
    }

    IpcHandler {
        target: "sound"
        function toggle(): void {
            const state = ShellState.forActive();
            if (state) state.audio = !state.audio;
        }
    }

    Bar.BarWindow {
        id: bar
    }

    NotifCenterWindow {}

    IpcHandler {
        target: "notifcenter"
        function toggle(): void {
            const state = ShellState.forActive();
            if (state) state.notifCenter = !state.notifCenter;
        }
    }

    NotificationPopups {
        id: notificationPopups
    }
}
