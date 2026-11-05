import QtQuick
import qs.components
import qs.components.panel

// Panneau Son : enveloppe commune branchée sur ScreenState.audio.
PanelWrapper {
    id: wrapper

    required property ScreenState screenState

    shouldBeActive: screenState?.audio ?? false

    contentComponent: Component {
        Content {
            screenState: wrapper.screenState
        }
    }
}
