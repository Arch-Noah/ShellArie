import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Widgets
import "../../commons"

Item {
    id: root
    
    property var activePlayer: null
    
    function updateActivePlayer() {
        var players = Mpris.players.values;
        if (players.length === 0) {
            root.activePlayer = null;
            return;
        }
        var validPlayers = [];
        for (var j = 0; j < players.length; j++) {
            if (players[j].trackTitle && players[j].trackTitle.trim() !== "") {
                validPlayers.push(players[j]);
            }
        }
        
        if (validPlayers.length === 0) {
            root.activePlayer = null;
            return;
        }
        
        for (var i = 0; i < validPlayers.length; i++) {
            if (validPlayers[i].playbackState === MprisPlaybackState.Playing) {
                root.activePlayer = validPlayers[i];
                return;
            }
        }
        root.activePlayer = validPlayers[0];
    }
    
    Instantiator {
        model: Mpris.players.values
        onObjectAdded: root.updateActivePlayer()
        onObjectRemoved: root.updateActivePlayer()
        Item {
            Connections {
                target: modelData
                function onPlaybackStateChanged() { root.updateActivePlayer(); }
            }
        }
    }
    
    Component.onCompleted: {
        updateActivePlayer();
    }
    
    visible: activePlayer !== null
    
    property string coverPath: {
        if (!root.activePlayer || !root.activePlayer.trackArtUrl || root.activePlayer.trackArtUrl === "") {
            return "file:///home/nnoah/.config/ags/assets/player/player_default.png";
        }
        var url = root.activePlayer.trackArtUrl;
        if (url.startsWith("http://") || url.startsWith("https://") || url.startsWith("file://")) {
            return url;
        }
        return "file://" + url;
    }
    
    HoverHandler { id: hover }
    property bool isHovered: hover.hovered
    
    property string titleText: activePlayer ? (activePlayer.trackTitle || "Unknown") : ""
    property string artistText: activePlayer ? (activePlayer.trackArtist || "Unknown Artist") : ""
    
    property string playerIconName: {
        if (!root.activePlayer) return "";
        
        var identity = (root.activePlayer.identity || "").toLowerCase();
        var searchString = identity.split(".instance")[0]; // Remove things like chromium.instance123
        
        // Dynamically search system desktop entries for the correct icon
        var apps = DesktopEntries.applications.values;
        if (apps) {
            for (var i = 0; i < apps.length; i++) {
                var app = apps[i];
                var name = (app.name || "").toLowerCase();
                var exec = (app.execString || "").toLowerCase();
                
                if (name.indexOf(searchString) !== -1 || exec.indexOf(searchString) !== -1) {
                    if (app.icon && Quickshell.hasThemeIcon(app.icon)) return app.icon;
                }
            }
        }
        
        // Fallbacks for known mismatches if not found dynamically
        if (searchString.indexOf("spotify") !== -1) return "spotify-client";
        if (searchString.indexOf("chrome") !== -1 || searchString.indexOf("chromium") !== -1) return "google-chrome";
        if (searchString.indexOf("firefox") !== -1) return "firefox";
        
        return "";
    }
    
    property int titleWidth: Math.min((titleText.length) * 10 + 40, 200)
    property int targetArtistWidth: Math.min((artistText.length) * 9, 150)
    
    implicitWidth: titleWidth + artistRevealerWidth + statusRevealerWidth
    implicitHeight: 30
    
    property int artistRevealerWidth: isHovered ? targetArtistWidth : 0
    Behavior on artistRevealerWidth { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }
    
    property int statusRevealerWidth: isHovered ? 25 : 0
    Behavior on statusRevealerWidth { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }
    
    ClippingRectangle {
        anchors.fill: parent
        radius: Styles.borderRadius
        color: "black"
        // clip: true is implied or handled by ClippingRectangle
        
        Image {
            anchors.fill: parent
            source: root.coverPath
            fillMode: Image.PreserveAspectCrop
            opacity: 0.4
            asynchronous: true
            cache: false
        }
        
        RowLayout {
            anchors.fill: parent
            anchors.margins: 5
            spacing: 3
            
            Item {
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                Image {
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    source: root.playerIconName !== "" ? "image://icon/" + root.playerIconName : ""
                    
                    RotationAnimation on rotation {
                        loops: Animation.Infinite
                        from: 0
                        to: 360
                        duration: 10000
                        running: root.activePlayer && root.activePlayer.playbackState === MprisPlaybackState.Playing
                    }
                }
            }
            
            Item {
                Layout.preferredWidth: statusRevealerWidth
                Layout.fillHeight: true
                clip: true
                
                Text {
                    anchors.centerIn: parent
                    text: root.activePlayer && root.activePlayer.playbackState === MprisPlaybackState.Playing ? "" : ""
                    color: "white"
                    font.pixelSize: 13
                    font.family: "JetBrainsMono NFP"
                }
            }
            
            Row {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 15
                
                Text {
                    id: titleDisplay
                    text: root.titleText
                    color: "white"
                    font.pixelSize: 13
                    font.family: "JetBrainsMono NFP"
                    font.bold: true
                    width: Math.max(0, root.titleWidth - 40 - (statusRevealerWidth > 0 ? statusRevealerWidth : 0))
                    elide: Text.ElideRight
                    anchors.verticalCenter: parent.verticalCenter
                }
                
                Item {
                    width: artistRevealerWidth
                    height: parent.height
                    clip: true
                    
                    Text {
                        id: artistDisplay
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.artistText
                        color: "white"
                        opacity: 0.7
                        font.pixelSize: 12
                        font.family: "JetBrainsMono NFP"
                        font.bold: true
                        width: parent.width
                        elide: Text.ElideRight
                    }
                }
            }
        }
        
        Process {
            id: toggleProcess
            command: ["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle music"]
        }
        
        MouseArea {
            anchors.fill: parent
            onClicked: {
                toggleProcess.running = true;
            }
        }
    }
}
