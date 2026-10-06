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

    Bar.BarWindow {
        id: bar
    }

    NotificationPopups {
        id: notificationPopups
    }
}
