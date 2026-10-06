import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Io
import "../commons"
import "utilities_components"
import qs.utils

RowLayout {
    id: utilitiesLayout
    spacing: 0

    Rectangle {
        id: systemTrayGroup
        implicitWidth: innerLayout.implicitWidth
        height: 30
        radius: Styles.borderRadius
        color: Styles.backgroundTransparent
        
        RowLayout {
            id: innerLayout
            anchors.fill: parent
            spacing: 0
            
            CustomRevealer {
                id: wifiRevealer
                
                property string ssidText: "Disconnected"
                property int signalStrength: 0
                
                iconText: {
                    if (ssidText === "Disconnected") return "󰤮";
                    if (signalStrength > 80) return "󰤨";
                    if (signalStrength > 60) return "󰤥";
                    if (signalStrength > 40) return "󰤢";
                    if (signalStrength > 20) return "󰤟";
                    return "󰤮";
                }
                
                labelText: ssidText
                onClickCommand: "\"" + Paths.qsManager + "\" toggle network wifi"
                
                Process {
                    id: wifiProcess
                    command: ["env", "LC_ALL=C", "nmcli", "-t", "-f", "active,ssid,signal", "dev", "wifi"]
                    running: true
                    stdout: StdioCollector {
                        onStreamFinished: {
                            if (this.text) {
                                var lines = this.text.split('\n');
                                for (var i = 0; i < lines.length; i++) {
                                    if (lines[i].startsWith("yes:")) {
                                        var parts = lines[i].split(':');
                                        if (parts.length >= 3) {
                                            wifiRevealer.ssidText = parts[1];
                                            var sig = parseInt(parts[2]);
                                            wifiRevealer.signalStrength = isNaN(sig) ? 0 : sig;
                                        }
                                        return;
                                    }
                                }
                            }
                            wifiRevealer.ssidText = "Disconnected";
                            wifiRevealer.signalStrength = 0;
                        }
                    }
                }
                
                Timer {
                    interval: 5000; running: true; repeat: true;
                    onTriggered: wifiProcess.running = true
                }
            }

            CustomRevealer {
                id: btRevealer
                iconText: btText === "Off" || btText === "Disconnected" ? "󰂲" : "󰂱"
                labelText: btText === "Off" ? "Bluetooth Off" : btText
                onClickCommand: "\"" + Paths.qsManager + "\" toggle network bt"
                
                property string btText: "Checking..."
                
                Process {
                    id: btProcess
                    command: ["bash", "-c", "export LC_ALL=C; dev=$(bluetoothctl devices Connected | head -n1); if [ -z \"$dev\" ]; then powered=$(bluetoothctl show | grep -q 'Powered: yes' && echo 'yes' || echo 'no'); if [ \"$powered\" = 'yes' ]; then echo 'Disconnected'; else echo 'Off'; fi; else mac=$(echo \"$dev\" | awk '{print $2}'); name=$(echo \"$dev\" | cut -d' ' -f3-); bat=$(bluetoothctl info \"$mac\" | grep 'Battery Percentage:' | awk -F'(' '{print $2}' | tr -d ')'); if [ -n \"$bat\" ]; then echo \"$name ($bat%)\"; else echo \"$name\"; fi; fi"]
                    running: true
                    stdout: StdioCollector {
                        onStreamFinished: {
                            if (this.text) {
                                btRevealer.btText = this.text.trim();
                            }
                        }
                    }
                }
                
                Timer {
                    interval: 5000; running: true; repeat: true;
                    onTriggered: btProcess.running = true
                }
            }

            CustomRevealer {
                id: ethRevealer
                iconText: ethText === "Disconnected" ? "󰈂" : "󰈁"
                labelText: ethText
                onClickCommand: "\"" + Paths.qsManager + "\" toggle network eth"
                visible: ethText !== "Disconnected"
                
                property string ethText: "Disconnected"
                
                Process {
                    id: ethProcess
                    command: ["bash", "-c", "export LC_ALL=C; dev=$(nmcli -t -f DEVICE,TYPE,STATE dev | grep ':ethernet:connected' | head -n1 | cut -d':' -f1); if [ -n \"$dev\" ]; then speed=$(cat /sys/class/net/$dev/speed 2>/dev/null); if [ -n \"$speed\" ] && [ \"$speed\" -gt 0 ]; then echo \"Ethernet $speed Mb/s\"; else echo \"Ethernet\"; fi; else echo \"Disconnected\"; fi"]
                    running: true
                    stdout: StdioCollector {
                        onStreamFinished: {
                            if (this.text) {
                                ethRevealer.ethText = this.text.trim();
                            }
                        }
                    }
                }
                
                Timer {
                    interval: 5000; running: true; repeat: true;
                    onTriggered: ethProcess.running = true
                }
            }
            
            BatteryWidget {}
            
            VolumeWidget {}
            
            BrightnessWidget {}
            
            ResourceMonitorWidget {}
            
            TailscaleWidget {}
        }
    }
}
