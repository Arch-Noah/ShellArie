import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../commons"
import qs.utils
import qs.services

Rectangle {
    id: root
    
    // We bind to our dynamic content
    width: layout.implicitWidth
    height: 30
    radius: Styles.pillRadius // Use pillRadius or borderRadius depending on design. AGS used pill-like for clock, let's keep it consistent
    color: "transparent"
    
    readonly property string uploadText: Math.round(Metricd.uploadKBs).toString()
    readonly property string downloadText: Math.round(Metricd.downloadKBs).toString()
    
    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 8
        
        Row {
            spacing: 2
            Text {
                text: root.uploadText
                color: Styles.foreground
                font.pixelSize: 13
                font.family: "JetBrainsMono NFP"
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: "" // FontAwesome up arrow
                color: Styles.foreground
                opacity: 0.7
                font.pixelSize: 11
                font.family: "JetBrainsMono NFP" // Or whatever icon font provides 
                anchors.verticalCenter: parent.verticalCenter
            }
        }
        
        Row {
            spacing: 2
            Text {
                text: root.downloadText
                color: Styles.foreground
                font.pixelSize: 13
                font.family: "JetBrainsMono NFP"
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: "" // FontAwesome down arrow
                color: Styles.foreground
                opacity: 0.7
                font.pixelSize: 11
                font.family: "JetBrainsMono NFP"
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
