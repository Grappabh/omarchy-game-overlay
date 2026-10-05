import QtQuick
import qs.Ui
import qs.Commons

// Hex color field used for the two color settings in BarWidget.qml's popup.
// Built on qs.Ui.TextField (a real QtQuick.Controls.TextField under the
// hood) rather than a bare TextInput — the bare version never actually
// accepted focus/typing inside the popup; this component is the same one
// Omarchy's own panels use for text entry, so it's known to work there.
Row {
  id: field
  property string label: ""
  property string value: ""
  signal changed(string newValue)

  spacing: Style.space(8)

  Text {
    text: field.label
    color: Color.popups.text
    font.pixelSize: Style.font.body
    width: Style.space(90)
    anchors.verticalCenter: parent.verticalCenter
  }

  Rectangle {
    width: Style.space(18); height: Style.space(18); radius: Style.space(3)
    color: field.value
    border.color: Color.popups.border
    border.width: 1
    anchors.verticalCenter: parent.verticalCenter
  }

  TextField {
    id: input
    width: Style.space(90)
    verticalPadding: Style.space(3)
    horizontalPadding: Style.space(6)
    anchors.verticalCenter: parent.verticalCenter
    text: field.value
    selectByMouse: true
    font.pixelSize: Style.font.bodySmall
    // No outline, per request — flat fill only, no border at all.
    background: Rectangle {
      color: Qt.lighter(Color.popups.background, 1.4)
      radius: Style.space(4)
    }
    onEditingFinished: {
      if (/^#[0-9A-Fa-f]{6}$/.test(text)) field.changed(text)
      else text = field.value // reject anything that isn't a plain hex color
    }
  }
}
