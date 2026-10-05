import QtQuick
import qs.Ui
import qs.Commons

// Label + draggable slider + live value readout, built on Omarchy's own
// PanelSlider rather than a custom track/knob implementation.
Row {
  id: field
  property string label: ""
  property real value: 0
  property real min: 0
  property real max: 100
  property real step: 1
  property bool integer: false
  property int decimals: 0
  // Fired continuously while dragging, for instant visual feedback.
  signal moved(real newValue)
  // Fired once when the drag ends (or on a wheel tick) — the right moment
  // to actually persist to disk instead of writing on every pixel of drag.
  signal released(real newValue)

  spacing: Style.space(8)

  Text {
    text: field.label
    color: Color.popups.text
    font.pixelSize: Style.font.body
    width: Style.space(80)
    anchors.verticalCenter: parent.verticalCenter
  }

  PanelSlider {
    id: slider
    width: Style.space(120)
    anchors.verticalCenter: parent.verticalCenter
    value: field.value
    minimum: field.min
    maximum: field.max
    step: field.step
    integer: field.integer
    onMoved: function(v) { field.moved(v) }
    onReleased: function(v) { field.released(v) }
  }

  Text {
    text: field.decimals > 0 ? field.value.toFixed(field.decimals) : String(Math.round(field.value))
    color: Color.popups.text
    font.pixelSize: Style.font.body
    width: Style.space(36)
    horizontalAlignment: Text.AlignHCenter
    anchors.verticalCenter: parent.verticalCenter
  }
}
