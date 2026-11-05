import QtQuick
import qs.components.controls

// StyledSwitch réduit : le scale ne change pas la taille de layout, on la recalcule.
Item {
    id: root

    property alias checked: sw.checked
    readonly property real factor: 0.65

    signal toggled

    implicitWidth: sw.implicitWidth * factor
    implicitHeight: sw.implicitHeight * factor

    StyledSwitch {
        id: sw
        anchors.centerIn: parent
        scale: root.factor
        onToggled: root.toggled()
    }
}
