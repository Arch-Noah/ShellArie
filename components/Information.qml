import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import "../commons"
import "informations_components"

RowLayout {
    id: informationLayout
    spacing: 8

    // MPRIS
    MprisWidget {
        id: mprisWidget
        Layout.alignment: Qt.AlignVCenter
    }

    // Clock
    ClockWidget {
        id: clockWidget
        Layout.alignment: Qt.AlignVCenter
    }
    // Bandwidth
    BandwidthWidget {
        id: bandwidthWidget
        Layout.alignment: Qt.AlignVCenter
    }
}
