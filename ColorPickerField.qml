import QtQuick
import qs.Ui
import qs.Commons

// EXPERIMENTAL, modeled on a Figma mockup: a saturation/value box instead of
// separate saturation+lightness sliders, a hue slider, a live swatch, and an
// editable hex readout. Same external API as HueColorField (value/moved/
// released) so it's a drop-in swap with that or plain ColorField in
// BarWidget.qml — nothing else needs to change to pick a different one.
Column {
  id: root

  property string label: ""
  property string value: "#000000"
  signal moved(string hex)
  signal released(string hex)

  spacing: Style.space(8)

  function hexToHsv(hex) {
    var c = Qt.color(hex)
    var r = c.r, g = c.g, b = c.b
    var max = Math.max(r, g, b), min = Math.min(r, g, b)
    var d = max - min
    var h = 0
    if (d !== 0) {
      if (max === r) h = 60 * (((g - b) / d) % 6)
      else if (max === g) h = 60 * ((b - r) / d + 2)
      else h = 60 * ((r - g) / d + 4)
      if (h < 0) h += 360
    }
    var s = max === 0 ? 0 : d / max
    return { h: h, s: s * 100, v: max * 100 }
  }

  function hsvToHex(h, s, v) {
    var c = Qt.hsva(h / 360, s / 100, v / 100, 1)
    function ch(x) {
      var n = Math.max(0, Math.min(255, Math.round(x * 255)))
      var str = n.toString(16)
      return str.length < 2 ? "0" + str : str
    }
    return "#" + ch(c.r) + ch(c.g) + ch(c.b)
  }

  property var hsv: root.hexToHsv(root.value)
  // Resync only on an external value change (e.g. switching which swatch is
  // selected elsewhere) — not our own edits, which already keep `hsv` current.
  // Also re-pushes the hex field's text explicitly: typing in a TextField
  // breaks its declarative `text:` binding on the first keystroke (same
  // class of issue as the popup-binding bug elsewhere in this plugin), which
  // would otherwise leave it showing a stale value after switching targets
  // following any manual edit.
  onValueChanged: {
    if (root.hsvToHex(root.hsv.h, root.hsv.s, root.hsv.v) !== root.value) root.hsv = root.hexToHsv(root.value)
    hexInput.text = root.value.replace("#", "").toUpperCase()
  }

  function updateFromHsv(h, s, v, final) {
    root.hsv = { h: h, s: s, v: v }
    var hex = root.hsvToHex(h, s, v)
    if (final) root.released(hex)
    else root.moved(hex)
  }

  Text {
    visible: root.label !== ""
    text: root.label
    color: Color.popups.text
    font.pixelSize: Style.font.body
  }

  SaturationValueBox {
    width: Style.space(260)
    height: Style.space(110)
    hue: root.hsv.h
    saturation: root.hsv.s
    value: root.hsv.v
    onMoved: function(s, v) { root.updateFromHsv(root.hsv.h, s, v, false) }
    onReleased: function(s, v) { root.updateFromHsv(root.hsv.h, s, v, true) }
  }

  Row {
    spacing: Style.space(10)

    Rectangle {
      width: Style.space(40)
      height: rightCol.implicitHeight
      radius: Style.space(6)
      color: root.value
      border.width: 1
      border.color: Color.popups.border
    }

    Column {
      id: rightCol
      spacing: Style.space(8)

      HueSlider {
        width: Style.space(210)
        value: root.hsv.h
        onMoved: function(h) { root.updateFromHsv(h, root.hsv.s, root.hsv.v, false) }
        onReleased: function(h) { root.updateFromHsv(h, root.hsv.s, root.hsv.v, true) }
      }

      Rectangle {
        width: Style.space(150)
        height: Style.space(26)
        radius: height / 2
        color: Qt.lighter(Color.popups.background, 1.4)

        Row {
          anchors.fill: parent
          anchors.leftMargin: Style.space(10)
          anchors.rightMargin: Style.space(8)
          spacing: Style.space(8)

          Text {
            text: "Hex"
            color: Color.popups.text
            font.pixelSize: Style.font.bodySmall
            anchors.verticalCenter: parent.verticalCenter
          }

          Rectangle {
            width: 1
            height: Style.space(14)
            color: Color.popups.border
            anchors.verticalCenter: parent.verticalCenter
          }

          TextField {
            id: hexInput
            width: Style.space(62)
            anchors.verticalCenter: parent.verticalCenter
            text: root.value.replace("#", "").toUpperCase()
            foreground: Color.popups.text
            font.pixelSize: Style.font.bodySmall
            selectByMouse: true
            verticalPadding: 0
            horizontalPadding: 0
            background: Item {}
            onEditingFinished: {
              var cleaned = text.replace("#", "").toUpperCase()
              if (/^[0-9A-F]{6}$/.test(cleaned)) {
                var hex = "#" + cleaned
                root.hsv = root.hexToHsv(hex)
                root.released(hex)
              } else {
                text = root.value.replace("#", "").toUpperCase()
              }
            }
          }
        }
      }
    }
  }
}
