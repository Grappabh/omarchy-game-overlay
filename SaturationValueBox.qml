import QtQuick
import qs.Ui
import qs.Commons

// The classic HSV saturation/value square: x-axis is saturation (white at
// left, full hue at right), y-axis is value/brightness (full brightness at
// top, black at bottom), tinted by whatever `hue` currently is. Standalone
// component (not SliderField/HueSlider-based) since it's a 2D drag, not a
// linear one.
Item {
  id: root

  property real hue: 0         // 0-360, drives the tint
  property real saturation: 0  // 0-100
  property real value: 100     // 0-100 ("value"/brightness, HSV's V)
  property bool dragging: false
  property real liveSaturation: saturation
  property real liveValue: value
  onSaturationChanged: if (!dragging) liveSaturation = saturation
  onValueChanged: if (!dragging) liveValue = value

  signal moved(real saturation, real value)
  signal released(real saturation, real value)

  implicitWidth: Style.space(260)
  implicitHeight: Style.space(110)

  readonly property color pureHue: Qt.hsva(root.hue / 360, 1, 1, 1)
  readonly property real knobSize: Style.space(14)

  Rectangle {
    id: box
    anchors.fill: parent
    radius: Style.space(6)

    // Base layer: white (S=0) to the pure hue (S=1) at full value.
    gradient: Gradient {
      orientation: Gradient.Horizontal
      GradientStop { position: 0.0; color: "#FFFFFF" }
      GradientStop { position: 1.0; color: root.pureHue }
    }

    // Overlay: transparent (V=1) to black (V=0), top to bottom — QtQuick's
    // default Gradient orientation is already vertical.
    Rectangle {
      anchors.fill: parent
      radius: parent.radius
      gradient: Gradient {
        GradientStop { position: 0.0; color: "#00000000" }
        GradientStop { position: 1.0; color: "#FF000000" }
      }
    }
  }

  BorderSurface {
    id: knob
    width: root.knobSize
    height: root.knobSize
    radius: root.knobSize / 2
    color: "transparent"
    borderSpec: Border.flat("white", Math.max(1, Style.space(2)))
    x: Math.max(0, Math.min(box.width - width, box.width * (root.liveSaturation / 100) - width / 2))
    y: Math.max(0, Math.min(box.height - height, box.height * (1 - root.liveValue / 100) - height / 2))
    scale: mouseArea.containsMouse || root.dragging ? 1.15 : 1.0

    Behavior on x {
      enabled: !root.dragging
      NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
    }
    Behavior on y {
      enabled: !root.dragging
      NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    function fromPoint(px, py) {
      var cx = Math.max(0, Math.min(box.width, px))
      var cy = Math.max(0, Math.min(box.height, py))
      return {
        s: (cx / box.width) * 100,
        v: (1 - cy / box.height) * 100
      }
    }

    onPressed: function(mouse) {
      root.dragging = true
      var p = fromPoint(mouse.x, mouse.y)
      root.liveSaturation = p.s
      root.liveValue = p.v
      root.moved(p.s, p.v)
    }
    onPositionChanged: function(mouse) {
      if (!root.dragging) return
      var p = fromPoint(mouse.x, mouse.y)
      root.liveSaturation = p.s
      root.liveValue = p.v
      root.moved(p.s, p.v)
    }
    onReleased: function(mouse) {
      root.dragging = false
      root.released(root.liveSaturation, root.liveValue)
      root.liveSaturation = root.saturation
      root.liveValue = root.value
    }
  }
}
