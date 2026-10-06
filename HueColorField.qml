import QtQuick
import qs.Ui
import qs.Commons

// EXPERIMENTAL alternative to ColorField's hex-text-entry: hue/saturation/
// lightness sliders plus a live swatch, for picking a color interactively
// instead of typing a hex code. Keeps the same underlying storage format
// (a "#rrggbb" string) so reverting to ColorField is just swapping the
// component back in BarWidget.qml — nothing else changes.
Column {
  id: root

  property string label: ""
  property string value: "#000000"
  // Fired continuously while dragging any of the three sliders, for instant
  // visual feedback (matches SliderField's moved/released split, so BarWidget
  // can avoid writing to disk on every pixel of drag).
  signal moved(string hex)
  signal released(string hex)

  spacing: Style.space(6)

  function hexToHsl(hex) {
    var c = Qt.color(hex)
    var r = c.r, g = c.g, b = c.b
    var max = Math.max(r, g, b), min = Math.min(r, g, b)
    var h = 0, s = 0, l = (max + min) / 2
    if (max !== min) {
      var d = max - min
      s = l > 0.5 ? d / (2 - max - min) : d / (max + min)
      if (max === r) h = (g - b) / d + (g < b ? 6 : 0)
      else if (max === g) h = (b - r) / d + 2
      else h = (r - g) / d + 4
      h /= 6
    }
    return { h: h * 360, s: s * 100, l: l * 100 }
  }

  function hslToHex(h, s, l) {
    var c = Qt.hsla(h / 360, s / 100, l / 100, 1)
    function ch(v) {
      var n = Math.max(0, Math.min(255, Math.round(v * 255)))
      var s = n.toString(16)
      return s.length < 2 ? "0" + s : s
    }
    return "#" + ch(c.r) + ch(c.g) + ch(c.b)
  }

  property var hsl: root.hexToHsl(root.value)
  // Only resync from an external value change (e.g. "Theme" mode flipping
  // back to "Custom" elsewhere) — not from our own edits, which already
  // keep `hsl` current and would otherwise round-trip through hex rounding.
  onValueChanged: if (root.hslToHex(root.hsl.h, root.hsl.s, root.hsl.l) !== root.value) root.hsl = root.hexToHsl(root.value)

  function updateFromHsl(h, s, l, final) {
    root.hsl = { h: h, s: s, l: l }
    var hex = root.hslToHex(h, s, l)
    if (final) root.released(hex)
    else root.moved(hex)
  }

  Row {
    spacing: Style.space(8)
    Text {
      text: root.label
      color: Color.popups.text
      font.pixelSize: Style.font.body
      anchors.verticalCenter: parent.verticalCenter
    }
    Rectangle {
      width: Style.space(20)
      height: Style.space(20)
      radius: Style.space(4)
      color: root.value
      border.width: 1
      border.color: Color.popups.text
      anchors.verticalCenter: parent.verticalCenter
    }
  }

  HueSlider {
    width: Style.space(200)
    value: root.hsl.h
    onMoved: function(v) { root.updateFromHsl(v, root.hsl.s, root.hsl.l, false) }
    onReleased: function(v) { root.updateFromHsl(v, root.hsl.s, root.hsl.l, true) }
  }

  SliderField {
    label: "Saturation"
    value: root.hsl.s
    min: 0; max: 100; step: 1; integer: true
    onMoved: function(v) { root.updateFromHsl(root.hsl.h, v, root.hsl.l, false) }
    onReleased: function(v) { root.updateFromHsl(root.hsl.h, v, root.hsl.l, true) }
  }

  SliderField {
    label: "Lightness"
    value: root.hsl.l
    min: 0; max: 100; step: 1; integer: true
    onMoved: function(v) { root.updateFromHsl(root.hsl.h, root.hsl.s, v, false) }
    onReleased: function(v) { root.updateFromHsl(root.hsl.h, root.hsl.s, v, true) }
  }
}
