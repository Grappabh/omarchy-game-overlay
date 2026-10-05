import QtQuick
import qs.Commons

// A small "monitor" rectangle with 6 clickable dots — one per corner/edge-
// center position the overlay pill can sit at. Mirrors the actual top/bottom
// × left/center/right layout used by Panel.qml's anchoring.
Column {
  id: root
  property string value: "top-center"
  signal changed(string newValue)

  spacing: Style.space(8)

  Rectangle {
    id: monitor
    width: Style.space(160)
    height: Style.space(90)
    radius: Style.space(6)
    color: Qt.darker(Color.popups.background, 1.15)
    border.color: Color.popups.border
    border.width: 1

    Repeater {
      model: [
        { key: "top-left", xf: 0.12, yf: 0.18 },
        { key: "top-center", xf: 0.5, yf: 0.18 },
        { key: "top-right", xf: 0.88, yf: 0.18 },
        { key: "bottom-left", xf: 0.12, yf: 0.82 },
        { key: "bottom-center", xf: 0.5, yf: 0.82 },
        { key: "bottom-right", xf: 0.88, yf: 0.82 }
      ]

      delegate: Rectangle {
        id: dot
        required property var modelData
        readonly property bool selected: root.value === modelData.key

        width: Style.space(14)
        height: Style.space(14)
        radius: width / 2
        x: monitor.width * modelData.xf - width / 2
        y: monitor.height * modelData.yf - height / 2
        color: selected ? Color.accent : Qt.lighter(Color.popups.background, 1.6)
        border.color: Color.popups.border
        border.width: selected ? 0 : 1

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: root.changed(dot.modelData.key)
        }
      }
    }
  }
}
