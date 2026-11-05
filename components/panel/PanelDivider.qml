import QtQuick
import QtQuick.Layouts
import qs.services

// Filet fin entre deux lignes d'une carte.
Rectangle {
    Layout.fillWidth: true
    Layout.leftMargin: 44
    Layout.rightMargin: 8
    implicitHeight: 1
    color: Qt.alpha(Colours.palette.m3onSurface, 0.06)
}
