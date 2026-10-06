import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../commons"

Rectangle {
    id: root
    
    // We bind to our dynamic content
    width: layout.implicitWidth
    height: 30
    radius: Styles.pillRadius // Use pillRadius or borderRadius depending on design. AGS used pill-like for clock, let's keep it consistent
    color: "transparent"
    
    property string uploadText: "0"
    property string downloadText: "0"
    
    // Background daemon process reading metricd socket
    Process {
        id: metricdProc
        command: ["nc", "-U", "/run/user/1000/metricd.sock"]
        running: true
        
        // Restart if it dies (e.g. if metricd is restarted)
        onRunningChanged: {
            if (!running) {
                restartTimer.start()
            }
        }
        
        stdout: SplitParser {
            onRead: function(data) {
                var lines = data.split("\n");
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim();
                    if (line === "") continue;
                    
                    try {
                        var msg = JSON.parse(line);
                        if (msg.type === "network" && msg.interfaces && msg.interfaces.length > 0) {
                            var interfaces = msg.interfaces.slice();
                            
                            // Sort by total cumulative bytes to find the primary interface
                            interfaces.sort(function(a, b) {
                                var totalA = (a.tx_bytes_cumulative || 0) + (a.rx_bytes_cumulative || 0);
                                var totalB = (b.tx_bytes_cumulative || 0) + (b.rx_bytes_cumulative || 0);
                                return totalB - totalA;
                            });
                            
                            var mainIf = null;
                            for (var j = 0; j < interfaces.length; j++) {
                                if (interfaces[j].name !== "lo") {
                                    mainIf = interfaces[j];
                                    break;
                                }
                            }
                            if (!mainIf) mainIf = interfaces[0];
                            
                            if (mainIf) {
                                // Convert to kB/s and round to integer
                                var txKB = (mainIf.upload_speed_bps || 0) / 1024;
                                var rxKB = (mainIf.download_speed_bps || 0) / 1024;
                                
                                root.uploadText = Math.round(txKB).toString();
                                root.downloadText = Math.round(rxKB).toString();
                            }
                        }
                    } catch (e) {
                        // Ignore JSON parse errors for partial chunks
                    }
                }
            }
        }
    }
    
    Timer {
        id: restartTimer
        interval: 2000
        repeat: false
        onTriggered: metricdProc.running = true
    }
    
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
