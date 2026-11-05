import QtQuick
import qs.components
import qs.components.panel

// Panneau Bluetooth : enveloppe commune branchée sur ScreenState.bluetooth.
PanelWrapper {
    id: wrapper

    required property ScreenState screenState

    shouldBeActive: screenState?.bluetooth ?? false

    contentComponent: Component {
        Content {
            screenState: wrapper.screenState
        }
    }
}
