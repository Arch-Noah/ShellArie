import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "."

Item {
    id: window

    Caching { id: paths }

    property var notifModel
    property var liveNotifs

    onNotifModelChanged: Qt.callLater(window.enforceNotificationSort)

    Connections {
        target: window.notifModel
        function onCountChanged() {
            Qt.callLater(window.enforceNotificationSort);
        }
    }

    function enforceNotificationSort() {
        if (!notifModel || notifModel.count <= 1) return;
        let firstNonAction = -1;
        for (let i = 0; i < notifModel.count; i++) {
            let item = notifModel.get(i);
            let hasAction = false;
            try {
                let parsed = item.actionsJson ? JSON.parse(item.actionsJson) : [];
                hasAction = parsed.length > 0;
            } catch(e) {}

            if (hasAction) {
                if (firstNonAction !== -1 && i > firstNonAction) {
                    notifModel.move(i, firstNonAction, 1);
                    firstNonAction++;
                }
            } else {
                if (firstNonAction === -1) {
                    firstNonAction = i;
                }
            }
        }
    }

    Scaler {
        id: scaler
        currentWidth: Screen.width
    }

    function s(val) {
        return scaler.s(val);
    }

    MatugenColors { id: _theme }
    readonly property color base: _theme.base
    readonly property color baseTransparent: _theme.baseTransparent
    readonly property color mantle: _theme.mantle
    readonly property color crust: _theme.crust
    readonly property color text: _theme.text
    readonly property color subtext0: _theme.subtext0
    readonly property color overlay0: _theme.overlay0
    readonly property color overlay1: _theme.overlay1
    readonly property color surface0: _theme.surface0
    readonly property color surface1: _theme.surface1
    readonly property color surface2: _theme.surface2

    readonly property color mauve: _theme.mauve
    readonly property color pink: _theme.pink
    readonly property color red: _theme.red
    readonly property color maroon: _theme.maroon
    readonly property color peach: _theme.peach
    readonly property color yellow: _theme.yellow
    readonly property color green: _theme.green
    readonly property color teal: _theme.teal
    readonly property color sapphire: _theme.sapphire
    readonly property color blue: _theme.blue

    property bool dndEnabled: false

    property var collapsedGroups: ({})

    function toggleGroup(groupName) {
        let temp = Object.assign({}, collapsedGroups);
        temp[groupName] = !temp[groupName];
        collapsedGroups = temp;
    }

    function isCollapsed(groupName) {
        return collapsedGroups[groupName] === true;
    }

    Process {
        id: dndInit
        running: true
        command: ["bash", "-c", "cat " + paths.getCacheDir("dnd") + "/state 2>/dev/null || echo '0'"]
        stdout: StdioCollector {
            onStreamFinished: {
                window.dndEnabled = (this.text.trim() === "1");
            }
        }
    }

    Process {
        id: dndPoller
        command: ["bash", "-c", "cat '" + paths.getCacheDir("dnd") + "/state' 2>/dev/null || echo '0'"]
        stdout: StdioCollector {
            onStreamFinished: window.dndEnabled = (this.text.trim() === "1")
        }
    }
    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: dndPoller.running = true
    }

    property real globalOrbitAngle: 0
    NumberAnimation on globalOrbitAngle {
        from: 0; to: Math.PI * 2; duration: 90000; loops: Animation.Infinite; running: true
    }

    property real introMain: 0
    property real introNotifs: 0

    ParallelAnimation {
        running: true
        NumberAnimation { target: window; property: "introMain"; from: 0; to: 1.0; duration: 800; easing.type: Easing.OutQuart }
        SequentialAnimation {
            PauseAnimation { duration: 150 }
            NumberAnimation { target: window; property: "introNotifs"; from: 0; to: 1.0; duration: 850; easing.type: Easing.OutQuart }
        }
    }

    ParallelAnimation {
        id: exitAnim
        NumberAnimation { target: window; property: "introMain"; to: 0; duration: 400; easing.type: Easing.InQuart }
        NumberAnimation { target: window; property: "introNotifs"; to: 0; duration: 300; easing.type: Easing.InQuart }
    }

    function clearGroup(appName) {
        if (!notifModel) return;
        for (let i = notifModel.count - 1; i >= 0; i--) {
            if (notifModel.get(i).appName === appName) {
                let uid = notifModel.get(i).uid;
                if (window.liveNotifs && window.liveNotifs[uid]) {
                    delete window.liveNotifs[uid];
                }
                notifModel.remove(i);
            }
        }
    }

    Item {
        anchors.fill: parent
        scale: 0.92 + (0.08 * introMain)
        opacity: introMain
        transform: Translate { y: window.s(15) * (1 - introMain) }

        Rectangle {
            anchors.fill: parent
            radius: window.s(14)
            color: window.baseTransparent
            border.color: window.surface0
            border.width: 1
            clip: true

            Rectangle {
                width: parent.width * 0.8; height: width; radius: width / 2
                x: (parent.width / 2 - width / 2) + Math.cos(window.globalOrbitAngle * 2) * window.s(150)
                y: (parent.height / 2 - height / 2) + Math.sin(window.globalOrbitAngle * 2) * window.s(100)
                opacity: 0.08
                color: window.mauve
            }

            Rectangle {
                width: parent.width * 0.9; height: width; radius: width / 2
                x: (parent.width / 2 - width / 2) + Math.sin(window.globalOrbitAngle * 1.5) * window.s(-150)
                y: (parent.height / 2 - height / 2) + Math.cos(window.globalOrbitAngle * 1.5) * window.s(-100)
                opacity: 0.06
                color: window.blue
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: window.s(20)
                spacing: window.s(15)

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: window.s(38)
                    spacing: window.s(12)

                    Text {
                        text: "Notifications"
                        font.family: "JetBrains Mono"
                        font.weight: Font.Black
                        font.pixelSize: window.s(18)
                        color: window.text
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        Layout.preferredWidth: dndMa.containsMouse ? window.s(38) + dndText.implicitWidth + window.s(8) : window.s(38)
                        Layout.preferredHeight: window.s(38)
                        radius: window.s(12)
                        color: window.dndEnabled ? Qt.alpha(window.red, 0.15) : (dndMa.containsMouse ? window.surface1 : "transparent")
                        border.color: window.dndEnabled ? window.red : (dndMa.containsMouse ? window.surface2 : "transparent")
                        border.width: 1
                        clip: true

                        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        Row {
                            anchors.right: parent.right
                            anchors.rightMargin: window.s(10)
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: window.s(8)

                            Text {
                                id: dndText
                                text: window.dndEnabled ? "Silent" : "Mute"
                                font.family: "JetBrains Mono"
                                font.weight: Font.Bold
                                font.pixelSize: window.s(13)
                                color: window.dndEnabled ? window.red : window.text
                                anchors.verticalCenter: parent.verticalCenter
                                opacity: dndMa.containsMouse ? 1.0 : 0.0
                                Behavior on opacity { NumberAnimation { duration: 250 } }
                            }

                            Text {
                                font.family: "Iosevka Nerd Font"
                                font.pixelSize: window.s(18)
                                color: window.dndEnabled ? window.red : (dndMa.containsMouse ? window.text : window.overlay0)
                                text: window.dndEnabled ? "󰂛" : "󰂚"
                                anchors.verticalCenter: parent.verticalCenter
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                        }

                        MouseArea {
                            id: dndMa
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                window.dndEnabled = !window.dndEnabled;
                                Quickshell.execDetached(["sh", "-c", "echo '" + (window.dndEnabled ? "1" : "0") + "' > " + paths.getCacheDir("dnd") + "/state"]);
                            }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.family: "JetBrains Mono"
                    font.weight: Font.Medium
                    font.pixelSize: window.s(14)
                    color: window.overlay0
                    text: "You're all caught up."
                    visible: !notifModel || notifModel.count === 0
                }

                ListView {
                    id: notifList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: window.notifModel
                    spacing: window.s(8)
                    clip: true

                    opacity: introNotifs
                    transform: Translate { y: window.s(20) * (1 - introNotifs) }

                    ScrollBar.vertical: ScrollBar {
                        active: notifList.moving || notifList.movingVertically
                        width: window.s(4)
                        policy: ScrollBar.AsNeeded
                        contentItem: Rectangle { implicitWidth: window.s(4); radius: window.s(2); color: window.surface2 }
                    }

                    add: Transition {
                        ParallelAnimation {
                            NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 400; easing.type: Easing.OutQuint }
                            NumberAnimation { property: "x"; from: window.s(-40); to: 0; duration: 500; easing.type: Easing.OutExpo }
                            NumberAnimation { property: "scale"; from: 0.95; to: 1.0; duration: 500; easing.type: Easing.OutBack }
                        }
                    }
                    remove: Transition {
                        ParallelAnimation {
                            NumberAnimation { property: "opacity"; to: 0.0; duration: 300; easing.type: Easing.OutQuint }
                            NumberAnimation { property: "scale"; to: 0.9; duration: 300; easing.type: Easing.OutQuint }
                        }
                    }
                    displaced: Transition {
                        NumberAnimation { properties: "y"; duration: 400; easing.type: Easing.OutExpo }
                    }

                    section.property: "appName"
                    section.criteria: ViewSection.FullString
                    section.delegate: Item {
                        width: ListView.view.width
                        height: window.s(46)

                        Rectangle {
                            anchors.fill: parent
                            anchors.topMargin: window.s(10)
                            anchors.bottomMargin: window.s(4)
                            color: headerMa.containsMouse ? window.surface1 : "transparent"
                            radius: window.s(8)
                            Behavior on color { ColorAnimation { duration: 150 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: window.s(6)
                                anchors.rightMargin: window.s(6)
                                spacing: window.s(8)

                                MouseArea {
                                    id: headerMa
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: window.toggleGroup(section)

                                    RowLayout {
                                        anchors.fill: parent
                                        spacing: window.s(8)

                                        Text {
                                            font.family: "Iosevka Nerd Font"
                                            font.pixelSize: window.s(14)
                                            color: window.mauve
                                            text: window.isCollapsed(section) ? "󰅂" : "󰅀"
                                            Behavior on rotation { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                                        }

                                        Text {
                                            text: section.toUpperCase()
                                            font.family: "JetBrains Mono"
                                            font.weight: Font.Black
                                            font.pixelSize: window.s(11)
                                            color: window.text
                                            Layout.fillWidth: true
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                    }
                                }

                                Rectangle {
                                    Layout.preferredWidth: window.s(26)
                                    Layout.preferredHeight: window.s(26)
                                    radius: window.s(13)
                                    color: groupClearMa.containsMouse ? window.surface2 : "transparent"
                                    Behavior on color { ColorAnimation { duration: 150 } }

                                    Text {
                                        anchors.centerIn: parent
                                        font.family: "Iosevka Nerd Font"
                                        font.pixelSize: window.s(14)
                                        color: groupClearMa.containsMouse ? window.red : window.overlay0
                                        text: "󰅖"
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                    }

                                    MouseArea {
                                        id: groupClearMa
                                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: window.clearGroup(section)
                                    }
                                }
                            }
                        }
                    }

                    delegate: Item {
                        id: delegateWrapper
                        width: ListView.view.width
                        property bool isHidden: window.isCollapsed(model.appName)
                        height: isHidden ? 0 : innerCard.height
                        visible: height > 0
                        opacity: isHidden ? 0 : 1
                        clip: true

                        Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
                        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutQuint } }

                        property var realNotif: window.liveNotifs ? window.liveNotifs[model.uid] : null

                        Connections {
                            target: delegateWrapper.realNotif || null
                            function onClosed() {
                                delegateWrapper.removeThisNotif();
                            }
                        }

                        function removeThisNotif() {
                            if (!window.notifModel) return;
                            for (let i = 0; i < window.notifModel.count; i++) {
                                if (window.notifModel.get(i).uid === model.uid) {
                                    if (window.liveNotifs && window.liveNotifs[model.uid]) {
                                        delete window.liveNotifs[model.uid];
                                    }
                                    window.notifModel.remove(i);
                                    break;
                                }
                            }
                        }

                        property var actionArray: {
                            try {
                                let parsed = model.actionsJson ? JSON.parse(model.actionsJson) : [];
                                return parsed;
                            } catch (e) {
                                return [];
                            }
                        }

                        Rectangle {
                            id: innerCard
                            width: parent.width
                            height: cardContent.height + window.s(24)
            radius: window.s(13)
                            color: cardHover.containsMouse ? window.surface1 : window.surface0
                            border.color: cardHover.containsMouse ? window.surface2 : "transparent"
                            border.width: 1
                            clip: true
                            Behavior on color { ColorAnimation { duration: 200 } }
                            Behavior on border.color { ColorAnimation { duration: 200 } }

                            MouseArea {
                                id: cardHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if ((model.appName === "Screenshot" || model.appName === "Screen Recorder") && model.iconPath !== "") {
                                        let folderPath = model.iconPath.substring(0, model.iconPath.lastIndexOf('/'))
                                        Quickshell.execDetached(["xdg-open", folderPath])
                                    } else {
                                        if (delegateWrapper.realNotif && delegateWrapper.realNotif.actions) {
                                            for (var i = 0; i < delegateWrapper.realNotif.actions.length; i++) {
                                                if (delegateWrapper.realNotif.actions[i].identifier === "default") {
                                                    delegateWrapper.realNotif.actions[i].invoke();
                                                    break;
                                                }
                                            }
                                        }
                                    }
                                    if (delegateWrapper.realNotif && typeof delegateWrapper.realNotif.close === "function") {
                                        delegateWrapper.realNotif.close()
                                    }
                                    delegateWrapper.removeThisNotif();
                                }
                            }

                            Rectangle {
                                width: window.s(4)
                                height: parent.height
                                anchors.left: parent.left
                                color: window.mauve
                            }

                            ColumnLayout {
                                id: cardContent
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: window.s(14)
                                anchors.leftMargin: window.s(18)
                                spacing: window.s(6)

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: window.s(8)

                                    Text {
                                        text: model.summary || "Notification"
                                        font.family: "JetBrains Mono"
                                        font.weight: Font.Bold
                                        font.pixelSize: window.s(13)
                                        color: window.text
                                        Layout.fillWidth: true
                                        wrapMode: Text.Wrap
                                        textFormat: Text.StyledText
                                    }

                                    Rectangle {
                                        Layout.preferredWidth: window.s(22)
                                        Layout.preferredHeight: window.s(22)
                                        radius: window.s(11)
                                        color: itemClearMa.containsMouse ? Qt.alpha(window.red, 0.15) : "transparent"
                                        Behavior on color { ColorAnimation { duration: 150 } }

                                        Text {
                                            anchors.centerIn: parent
                                            font.family: "Iosevka Nerd Font"
                                            font.pixelSize: window.s(12)
                                            color: itemClearMa.containsMouse ? window.red : window.overlay0
                                            text: "󰅖"
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                        }

                                        MouseArea {
                                            id: itemClearMa
                                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                            onClicked: delegateWrapper.removeThisNotif();
                                        }
                                    }
                                }

                                Text {
                                    text: model.body || ""
                                    font.family: "JetBrains Mono"
                                    font.weight: Font.Medium
                                    font.pixelSize: window.s(11)
                                    color: window.subtext0
                                    Layout.fillWidth: true
                                    wrapMode: Text.Wrap
                                    visible: text !== ""
                                    textFormat: Text.StyledText
                                    onLinkActivated: (link) => Quickshell.execDetached(["xdg-open", link])
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.topMargin: delegateWrapper.actionArray.length > 0 ? window.s(6) : 0
                                    spacing: window.s(8)
                                    visible: delegateWrapper.actionArray.length > 0

                                    Repeater {
                                        model: delegateWrapper.actionArray
                                        delegate: Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: window.s(28)
                                            radius: window.s(8)

                                            property bool isPrimary: index === 0

                                            color: {
                                                if (isPrimary) {
                                                    return actionMouseArea.containsMouse ? window.blue : Qt.darker(window.blue, 1.2)
                                                } else {
                                                    return actionMouseArea.containsMouse ? window.surface2 : window.surface1
                                                }
                                            }

                                            border.color: isPrimary ? window.blue : window.surface2
                                            border.width: 1

                                            Behavior on color { ColorAnimation { duration: 150 } }

                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData.text || "Action"
                                                font.family: "JetBrains Mono"
                                                font.weight: Font.Bold
                                                font.pixelSize: window.s(11)
                                                color: isPrimary ? window.crust : window.text
                                            }

                                            MouseArea {
                                                id: actionMouseArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor

                                                onClicked: {
                                                    if (delegateWrapper.realNotif && delegateWrapper.realNotif.actions) {
                                                        for (var i = 0; i < delegateWrapper.realNotif.actions.length; i++) {
                                                            if (delegateWrapper.realNotif.actions[i].identifier === modelData.id) {
                                                                delegateWrapper.realNotif.actions[i].invoke();
                                                                break;
                                                            }
                                                        }
                                                    }
                                                    delegateWrapper.removeThisNotif();
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
