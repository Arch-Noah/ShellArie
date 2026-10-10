import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Bluetooth
import "../commons"
import "utilities_components"
import qs.utils
import qs.services

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
            
            HypridleWidget {}

            CustomRevealer {
                id: wifiRevealer
                
                // Piloté par Nmcli (événementiel via `nmcli monitor`), plus de polling
                readonly property string ssidText: Nmcli.active ? Nmcli.active.ssid : "Disconnected"
                readonly property int signalStrength: Nmcli.active ? Nmcli.active.strength : 0
                
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
            }

            CustomRevealer {
                id: btRevealer
                iconText: btText === "Off" || btText === "Disconnected" ? "󰂲" : "󰂱"
                labelText: btText === "Off" ? "Bluetooth Off" : btText
                onClickCommand: "\"" + Paths.qsManager + "\" toggle network bt"
                
                readonly property var btAdapter: Bluetooth.defaultAdapter
                readonly property var btDevice: Bluetooth.devices.values.find(d => d.connected) ?? null
                readonly property string btText: {
                    if (!btAdapter || !btAdapter.enabled) return "Off";
                    if (!btDevice) return "Disconnected";
                    return btDevice.batteryAvailable ? `${btDevice.name} (${Math.round(btDevice.battery * 100)}%)` : btDevice.name;
                }
            }

            CustomRevealer {
                id: ethRevealer
                iconText: ethText === "Disconnected" ? "󰈂" : "󰈁"
                labelText: ethText
                onClickCommand: "\"" + Paths.qsManager + "\" toggle network eth"
                visible: ethText !== "Disconnected"
                
                readonly property string ethText: {
                    const dev = Nmcli.activeEthernet;
                    if (!dev) return "Disconnected";
                    return dev.speed ? `Ethernet ${dev.speed}` : "Ethernet";
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
