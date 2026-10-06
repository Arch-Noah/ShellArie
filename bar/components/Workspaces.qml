import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "../commons"

RowLayout {
    id: workspacesLayout
    spacing: 5
    property string targetMonitorName: ""
    property int lastFocusedRegularWorkspaceId: 1
    property bool isBarLocked: false
    signal toggleLockRequested()
    
    property bool isSpecialActive: Hyprland.focusedWorkspace && (Hyprland.focusedWorkspace.id < 0 || Hyprland.focusedWorkspace.name.startsWith("special:"))
    
    property var workspaceRegexIconMap: [
        { pattern: /cord$/, icon: "󰙯" },
        { pattern: /foot|kitty|alacritty|xterm|gnome-terminal|konsole|st/i, icon: "" },
        { pattern: /thunar|nautilus|dolphin|ranger/i, icon: "󰉋" },
        { pattern: /chrome|chromium|brave/i, icon: "" },
        { pattern: /firefox|zen/i, icon: "󰈹" },
        { pattern: /vlc/i, icon: "󰕼" },
        { pattern: /spotify|spotube/i, icon: "" },
        { pattern: /code|vscode|sublime|jetbrains|antigravity/i, icon: "" },
        { pattern: /steam/i, icon: "" },
        { pattern: /lutris|game|\.exe$/i, icon: "" },
        { pattern: /telegram/i, icon: "" }
    ]
    
    function getWorkspaceIcon(workspace, focusTrigger, toplevelsList) {
        var hasWindows = false;
        var foundClass = "";
        
        if (workspace && workspace.toplevels && workspace.toplevels.values) {
            var tlList = workspace.toplevels.values;
            hasWindows = tlList.length > 0;
            for (var i = 0; i < tlList.length; i++) {
                var tl = tlList[i];
                var cls = "";
                if (tl.wayland && tl.wayland.appId) {
                    cls = tl.wayland.appId;
                } else if (tl.lastIpcObject) {
                    cls = tl.lastIpcObject["class"] || tl.lastIpcObject.initialClass || "";
                }
                cls = cls || tl.title || "";
                
                if (cls) {
                    foundClass = cls;
                    break;
                }
            }
        }
        
        if (!hasWindows) return "󰫣"; // Empty star
        
        if (foundClass) {
            for (var j = 0; j < workspaceRegexIconMap.length; j++) {
                if (workspaceRegexIconMap[j].pattern.test(foundClass)) {
                    return workspaceRegexIconMap[j].icon;
                }
            }
        }
        
        return "󰫢"; // Fallback active icon
    }

    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() {
            var fw = Hyprland.focusedWorkspace;
            if (fw && fw.id > 0 && !fw.name.startsWith("special:")) {
                workspacesLayout.lastFocusedRegularWorkspaceId = fw.id;
            }
        }
    }
    
    Component.onCompleted: {
        Hyprland.refreshToplevels();
    }

    Component {
        id: hyprctlComponent
        Process {
            onRunningChanged: if (!running) destroy()
        }
    }

    function dispatchHyprctl(args) {
        hyprctlComponent.createObject(workspacesLayout, { command: ["hyprctl", "dispatch"].concat(args), running: true });
    }

    // Lock Button
    Rectangle {
        id: lockButton
        width: 30
        height: 30
        radius: Styles.borderRadius
        color: workspacesLayout.isBarLocked ? Styles.foreground : (lockHover.hovered ? Styles.secondary : "transparent")
        
        Text {
            anchors.centerIn: parent
            text: workspacesLayout.isBarLocked ? "" : ""
            color: workspacesLayout.isBarLocked ? "#000000" : Styles.foreground
            font.pixelSize: 12
            font.family: "JetBrainsMono Nerd Font"
        }
        
        HoverHandler { id: lockHover }
        
        MouseArea {
            anchors.fill: parent
            onClicked: workspacesLayout.toggleLockRequested()
        }
    }

    // Special Workspace Button
    Rectangle {
        id: specialButton
        width: 30
        height: 30
        radius: Styles.borderRadius
        color: isSpecialActive ? Styles.foreground : (specialHover.hovered ? Styles.secondary : "transparent")
        
        Text {
            anchors.centerIn: parent
            text: ""
            color: isSpecialActive ? "#000000" : Styles.foreground
            font.pixelSize: 12
            font.family: "JetBrainsMono Nerd Font"
        }
        
        HoverHandler { id: specialHover }
        
        DropArea {
            anchors.fill: parent
            onDropped: function(drop) {
                var address = drag.source.mimeData["text/plain"];
                if (address) {
                    dispatchHyprctl(["movetoworkspacesilent", "special,address:" + address]);
                }
            }
        }
        
        MouseArea {
            id: specialMa
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                dispatchHyprctl(["togglespecialworkspace"]);
            }
        }
    }

    // Normal Workspaces
    Row {
        id: normalWorkspaces
        spacing: 2

        Repeater {
            model: {
                var arr = [];
                // Collect and sort normal workspaces
                for (var i = 0; i < Hyprland.workspaces.values.length; i++) {
                    var ws = Hyprland.workspaces.values[i];
                    if (ws.id > 0 && !ws.name.startsWith("special:")) {
                        // Filter by monitor
                        if (targetMonitorName !== "" && ws.monitor && ws.monitor.name !== targetMonitorName) {
                            continue;
                        }
                        arr.push(ws);
                    }
                }
                arr.sort(function(a, b) { return a.id - b.id; });
                return arr;
            }

            delegate: Rectangle {
                id: wsButton
                property bool isFocused: workspacesLayout.isSpecialActive 
                    ? (modelData.id === workspacesLayout.lastFocusedRegularWorkspaceId) 
                    : (Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === modelData.id)
                property bool hasWindows: modelData.toplevels && modelData.toplevels.values && modelData.toplevels.values.length > 0
                
                width: isFocused ? 50 : 30
                height: 30
                radius: Styles.borderRadius
                
                // Hover behavior
                scale: ma.containsMouse ? 1.02 : 1.0
                property int offsetY: ma.containsMouse ? -2 : 0
                transform: Translate { y: wsButton.offsetY }
                
                color: isFocused ? Styles.foreground : (ma.containsMouse ? Styles.background : "transparent")
                
                // Opacity to simulate inactive
                opacity: hasWindows || isFocused ? 1.0 : 0.5
                
                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }
                Behavior on color { ColorAnimation { duration: 300 } }
                Behavior on scale { NumberAnimation { duration: 200 } }
                Behavior on offsetY { NumberAnimation { duration: 200 } }

                Text {
                    anchors.centerIn: parent
                    text: workspacesLayout.getWorkspaceIcon(modelData, Hyprland.focusedToplevel, modelData.toplevels && modelData.toplevels.values ? modelData.toplevels.values.length : 0)
                    color: isFocused ? Styles.background : Styles.foreground
                    font.pixelSize: 12
                    font.family: "JetBrainsMono Nerd Font"
                }
                
                DropArea {
                    anchors.fill: parent
                    onDropped: function(drop) {
                        var address = drag.source.mimeData["text/plain"];
                        if (address) {
                            dispatchHyprctl(["movetoworkspacesilent", modelData.id + ",address:" + address]);
                        }
                    }
                }
                
                MouseArea {
                    id: ma
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        dispatchHyprctl(["workspace", modelData.id.toString()]);
                    }
                }
            }
        }
    }
}
