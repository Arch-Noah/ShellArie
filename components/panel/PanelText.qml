import QtQuick
import Caelestia.Config
import qs.components

// Texte compact du panneau Wi-Fi (le thème par défaut est trop grand pour un panneau de barre).
StyledText {
    property real size: 9
    property int weight: Font.Normal

    font: Tokens.font.body.builders.small.size(size).weight(weight).build()
}
