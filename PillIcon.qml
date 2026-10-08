import QtQuick
import QtQuick.Effects
import qs.Commons

// Bundled bar icon (pill-icon.svg, from a Figma export) rendered as a
// symbolic icon: the SVG itself is a plain white shape on transparency, and
// MultiEffect's colorization re-tints it live to match the bar's own
// foreground — the same technique Omarchy's own tray uses for symbolic
// tray icons (plugins/bar/widgets/Tray.qml). That live-matching is the
// reason this isn't just a plain colored <Image>: a hardcoded fill would
// look right under today's theme and wrong under the next one.
Item {
  id: root

  property real iconWidth: Style.space(22)
  property real iconHeight: Style.space(11)
  property color color: Color.foreground

  implicitWidth: iconWidth
  implicitHeight: iconHeight
  width: implicitWidth
  height: implicitHeight

  Image {
    id: source
    anchors.fill: parent
    fillMode: Image.PreserveAspectFit
    sourceSize.width: Math.round(width * Screen.devicePixelRatio)
    sourceSize.height: Math.round(height * Screen.devicePixelRatio)
    source: Qt.resolvedUrl("pill-icon.svg")
    // Hidden layer so MultiEffect can sample it as a texture instead of
    // showing its own (uncolored) render too.
    visible: false
    layer.enabled: true
  }

  MultiEffect {
    anchors.fill: source
    source: source
    colorization: 1.0
    colorizationColor: root.color
  }
}
