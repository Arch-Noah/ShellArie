pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.panel
import qs.services

// Vue d'un type de périphérique audio : sortie (enceintes, casque) ou entrée (micro).
ColumnLayout {
    id: root

    property bool output: true

    readonly property var node: output ? Audio.sink : Audio.source
    readonly property var nodes: output ? Audio.sinks : Audio.sources
    readonly property real volume: output ? Audio.volume : Audio.sourceVolume
    readonly property bool muted: output ? Audio.muted : Audio.sourceMuted
    readonly property real maxVolume: GlobalConfig.services.maxVolume

    spacing: 10

    // Icône d'après le nom du périphérique
    function iconFor(n: var): string {
        if (!root.output)
            return "mic";
        const name = ((n?.description ?? "") + " " + (n?.name ?? "")).toLowerCase();
        if (/headphone|headset|casque|buds|bluez/.test(name))
            return "headphones";
        if (/hdmi|displayport/.test(name))
            return "tv";
        return "speaker";
    }

    function chooseNode(n: var): void {
        if (root.output)
            Audio.setAudioSink(n);
        else
            Audio.setAudioSource(n);
    }

    PanelEmpty {
        visible: !root.node
        icon: root.output ? "volume_off" : "mic_off"
        text: root.output ? qsTr("Aucune sortie audio") : qsTr("Aucune entrée audio")
        iconSize: 26
    }

    // --- Périphérique actif : volume et sourdine ---
    Rectangle {
        visible: !!root.node
        Layout.fillWidth: true
        implicitHeight: hero.implicitHeight + 28
        radius: 16
        color: Qt.alpha(Colours.palette.m3primary, 0.12)

        ColumnLayout {
            id: hero
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Rectangle {
                    implicitWidth: 44
                    implicitHeight: 44
                    radius: 22
                    color: Qt.alpha(Colours.palette.m3primary, 0.2)

                    PanelIcon {
                        anchors.centerIn: parent
                        text: root.muted ? (root.output ? "volume_off" : "mic_off") : root.iconFor(root.node)
                        size: 22
                        color: Colours.palette.m3primary
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    PanelText {
                        text: root.node?.description || root.node?.name || ""
                        size: 11
                        weight: Font.DemiBold
                        elide: Text.ElideMiddle
                        Layout.fillWidth: true
                    }

                    PanelText {
                        text: root.muted ? qsTr("Son coupé") : qsTr("Actif")
                        size: 8.5
                        color: root.muted ? Colours.palette.m3error : Colours.palette.m3primary
                    }
                }

                PanelText {
                    text: Math.round(root.volume * 100) + " %"
                    size: 14
                    weight: Font.DemiBold
                    color: root.muted ? Colours.palette.m3onSurfaceVariant : Colours.palette.m3onSurface
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                StyledSlider {
                    id: slider
                    Layout.fillWidth: true
                    from: 0
                    to: root.maxVolume
                    enabled: !root.muted
                    onMoved: Audio.setStreamVolume(root.node, value)
                }

                // Suit le volume réel, sauf pendant le glissement
                Binding {
                    target: slider
                    property: "value"
                    value: root.volume
                    when: !slider.pressed
                }

                PanelButton {
                    icon: root.muted ? (root.output ? "volume_off" : "mic_off") : (root.output ? "volume_up" : "mic")
                    tint: root.muted ? Colours.palette.m3error : Colours.palette.m3primary
                    filled: root.muted
                    onTint: Colours.palette.m3onError
                    onClicked: Audio.setStreamMuted(root.node, !root.muted)
                }
            }
        }
    }

    // --- Liste des périphériques ---
    PanelCard {
        visible: root.nodes.length > 0
        Layout.fillWidth: true

        Repeater {
            model: root.nodes

            delegate: ColumnLayout {
                id: item

                required property int index
                required property var modelData

                Layout.fillWidth: true
                spacing: 0

                PanelDivider {
                    visible: item.index > 0
                }

                DeviceRow {
                    Layout.fillWidth: true
                    node: item.modelData
                    selected: item.modelData === root.node
                    icon: root.iconFor(item.modelData)
                    onChosen: root.chooseNode(item.modelData)
                }
            }
        }
    }
}
