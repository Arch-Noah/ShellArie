import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import "../commons"

Rectangle {
    id: root
    property int workspaceId: -1
    
    color: Styles.backgroundTransparent
    radius: Styles.borderRadius
    
    // Size constraints for the popover
    width: 250
    height: 150
    
    // Provide a model of toplevels for this workspace
    property var clients: {
        var arr = [];
        if (workspaceId < 0) return arr;
        var toplevels = Hyprland.toplevels.values;
        for (var i = 0; i < toplevels.length; i++) {
            var c = toplevels[i];
            if (c.workspace && c.workspace.id === workspaceId) {
                arr.push(c);
            }
        }
        return arr;
    }

    // A KD-Tree rendering is complex to do purely declaratively.
    // We can use a Canvas or position elements dynamically in JS.
    // For simplicity and stability, we'll position Rectangles based on their relative coordinates
    // compared to the screen size.

    Flow {
        id: container
        anchors.fill: parent
        anchors.margins: 10
        spacing: 5
        
        Repeater {
            model: root.clients
            
            delegate: Rectangle {
                id: clientRect
                
                width: 50 // Mock width
                height: 50 // Mock height
                color: Styles.background
                radius: Styles.borderRadius
                border.color: Styles.tertiary
                border.width: 1
                
                Text {
                    anchors.centerIn: parent
                    text: modelData.class || "App"
                    color: Styles.foreground
                    font.pixelSize: 10
                    elide: Text.ElideRight
                    width: parent.width - 4
                    horizontalAlignment: Text.AlignHCenter
                }
                
                // Drag Source
                Drag.active: dragArea.drag.active
                Drag.supportedActions: Qt.MoveAction
                Drag.dragType: Drag.Automatic
                Drag.mimeData: { "text/plain": modelData.address.toString() }
                
                MouseArea {
                    id: dragArea
                    anchors.fill: parent
                    drag.target: parent
                    
                    onReleased: {
                        parent.Drag.drop();
                        // Snap back
                        parent.x = 0;
                        parent.y = 0;
                    }
                }
            }
        }
        
        Text {
            text: "Empty"
            color: Styles.foreground
            opacity: 0.5
            visible: root.clients.length === 0
        }
    }
}
