import QtQuick
import qs.components
import qs.components.panel

// Panneau Batterie : enveloppe commune branchée sur ScreenState.battery.
PanelWrapper {
    id: wrapper

    required property ScreenState screenState

    shouldBeActive: screenState?.battery ?? false

    contentComponent: Component {
        Content {
            screenState: wrapper.screenState
        }
    }
}
