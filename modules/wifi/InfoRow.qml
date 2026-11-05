import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.services

// Ligne « libellé / valeur » : un clic copie la valeur dans le presse-papiers.
Item {
    id: root

    property string icon
    property string label
    property string value
    // Texte copié ; par défaut la valeur affichée
    property string copyText: value
    property bool copied

    implicitHeight: row.implicitHeight + 14

    function copy(): void {
        if (!copyText || copyText === "—")
            return;
        Quickshell.execDetached(["wl-copy", "--", copyText]);
        copied = true;
        resetTimer.restart();
    }

    Timer {
        id: resetTimer
        interval: 1400
        onTriggered: root.copied = false
    }

    StateLayer {
        anchors.fill: parent
        anchors.margins: 2
        radius: 12
        cursorShape: Qt.PointingHandCursor
        onClicked: root.copy()
    }

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        anchors.topMargin: 7
        anchors.bottomMargin: 7
        spacing: 10

        WifiIcon {
            text: root.copied ? "check" : root.icon
            size: 14
            color: root.copied ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            Layout.alignment: Qt.AlignVCenter
        }

        WifiText {
            text: root.copied ? qsTr("Copié") : root.label
            color: root.copied ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            Layout.alignment: Qt.AlignVCenter
        }

        WifiText {
            text: root.value
            weight: Font.Medium
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            horizontalAlignment: Text.AlignRight
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        }
    }
}
