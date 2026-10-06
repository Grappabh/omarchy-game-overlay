import QtQuick
import qs.Ui
import qs.Commons

// A single-purpose slider for picking a hue (0-360): same drag/knob mechanics
// as the Ui kit's PanelSlider, but with a rainbow gradient track instead of a
// plain-color one (PanelSlider's track only takes a single `trackColor`).
// EXPERIMENTAL — see ColorField.qml for the hex-input alternative this is
// standing in for; reverting means swapping HueColorField back for ColorField
// in BarWidget.qml, nothing else.
Item {
  id: root

  property real value: 0 // degrees, 0-360
  property bool dragging: false
  property real liveValue: value
  onValueChanged: if (!dragging) liveValue = value

  signal moved(real value)
  signal released(real value)

  implicitWidth: Style.space(200)
  implicitHeight: Math.max(Style.space(22), knob.height + Style.spacing.md)

  readonly property real trackHeight: Math.max(4, Math.round(Style.spacing.controlHeight * 0.11))
  readonly property real knobSize: Math.max(14, Math.round(Style.spacing.controlHeight * 0.38))
  readonly property real progress: Math.max(0, Math.min(1, liveValue / 360))

  Rectangle {
    id: track
    anchors.verticalCenter: parent.verticalCenter
    anchors.left: parent.left
    anchors.right: parent.right
    height: root.trackHeight
    radius: height / 2
    gradient: Gradient {
      orientation: Gradient.Horizontal
      GradientStop { position: 0.0;    color: "#FF0000" }
      GradientStop { position: 0.1667; color: "#FFFF00" }
      GradientStop { position: 0.3333; color: "#00FF00" }
      GradientStop { position: 0.5;    color: "#00FFFF" }
      GradientStop { position: 0.6667; color: "#0000FF" }
      GradientStop { position: 0.8333; color: "#FF00FF" }
      GradientStop { position: 1.0;    color: "#FF0000" }
    }
  }

  BorderSurface {
    id: knob
    width: root.knobSize
    height: root.knobSize
    radius: root.knobSize / 2
    color: Qt.hsla(root.liveValue / 360, 1, 0.5, 1)
    borderSpec: Border.flat(Color.popups.background, Math.max(1, Style.space(2)))
    anchors.verticalCenter: track.verticalCenter
    x: Math.max(0, Math.min(track.width - width, track.width * root.progress - width / 2))
    scale: mouseArea.containsMouse || root.dragging ? 1.15 : 1.0

    Behavior on x {
      enabled: !root.dragging
      NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
    }
    Behavior on scale {
      NumberAnimation { duration: 110; easing.type: Easing.OutCubic }
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    function valueFromX(x) {
      var clamped = Math.max(0, Math.min(track.width, x))
      return Math.max(0, Math.min(360, (clamped / track.width) * 360))
    }

    onPressed: function(mouse) {
      root.dragging = true
      var next = valueFromX(mouse.x)
      root.liveValue = next
      root.moved(next)
    }
    onPositionChanged: function(mouse) {
      if (!root.dragging) return
      var next = valueFromX(mouse.x)
      root.liveValue = next
      root.moved(next)
    }
    onReleased: function(mouse) {
      root.dragging = false
      root.released(root.liveValue)
      root.liveValue = root.value
    }
  }
}
