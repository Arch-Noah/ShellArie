import QtQuick
import qs.components
import qs.components.panel

// Panneau Wi-Fi : enveloppe commune branchée sur ScreenState.wifi.
PanelWrapper {
    id: wrapper

    required property ScreenState screenState

    shouldBeActive: screenState?.wifi ?? false

    contentComponent: Component {
        Content {
            screenState: wrapper.screenState
        }
    }
}
