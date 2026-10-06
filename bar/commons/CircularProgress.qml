import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes

Item {
    id: root
    
    // Properties
    property real value: 0.0 // between 0.0 and 1.0
    property string icon: ""
    property color color: Styles.secondary
    property color backgroundColor: Qt.rgba(0.5, 0.5, 0.5, 0.3)
    property int strokeWidth: 3
    
    implicitWidth: 24
    implicitHeight: 24
    
    Shape {
        id: bgCircle
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        antialiasing: true
        layer.enabled: true
        layer.samples: 8
        layer.smooth: true
        
        ShapePath {
            strokeWidth: root.strokeWidth
            strokeColor: root.backgroundColor
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            
            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: Math.min(root.width, root.height) / 2 - root.strokeWidth / 2
                radiusY: radiusX
                startAngle: 0
                sweepAngle: 360
            }
        }
    }
    
    Shape {
        id: fgCircle
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        antialiasing: true
        layer.enabled: true
        layer.samples: 8
        layer.smooth: true
        
        ShapePath {
            strokeWidth: root.strokeWidth
            strokeColor: root.color
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            
            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: Math.min(root.width, root.height) / 2 - root.strokeWidth / 2
                radiusY: radiusX
                // QML PathAngleArc: 0 is 3 o'clock, -90 is 12 o'clock.
                startAngle: -90
                sweepAngle: root.value * 360
            }
        }
    }
    
    Text {
        anchors.centerIn: parent
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: root.icon
        color: Styles.foreground
        font.pixelSize: root.height * 0.55
        visible: root.icon !== ""
    }
}
