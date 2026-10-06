import QtQuick
import qs.Ui
import qs.Commons

// A pill button that doubles as a key-combo recorder: click it once to start
// listening, then press the combo you want. Needs at least one modifier
// (Ctrl/Shift/Alt/Super) so a bare letter never gets swallowed as a shortcut
// by accident; Escape cancels without changing anything.
Item {
  id: root

  // Hyprland bind syntax: "<space-separated MODS>, <key>", e.g. "SUPER CTRL, G".
  property string value: ""
  property bool recording: false
  signal changed(string bind)

  implicitWidth: pill.implicitWidth
  implicitHeight: pill.implicitHeight

  function modLabel(mod) {
    return mod.length > 0 ? mod.charAt(0) + mod.slice(1).toLowerCase() : mod
  }

  function keyLabel(key) {
    if (key.length === 0) return key
    if (key.length === 1) return key.toUpperCase()
    return key.charAt(0).toUpperCase() + key.slice(1).toLowerCase()
  }

  function displayText() {
    if (root.recording) return "Press keys…"
    if (!root.value) return "Click to set"
    var parts = root.value.split(",")
    var mods = parts[0] ? parts[0].trim().split(/\s+/).filter(function(m) { return m.length > 0 }) : []
    var key = parts[1] ? parts[1].trim() : ""
    var labels = mods.map(root.modLabel)
    if (key) labels.push(root.keyLabel(key))
    return labels.length > 0 ? labels.join("+") : "Click to set"
  }

  // Letters/digits map straight onto their Qt key code (Qt.Key_A === 'A'.charCodeAt(0),
  // and likewise for 0-9), so only the non-alphanumeric keys need a lookup.
  function keyName(event) {
    if (event.key >= Qt.Key_A && event.key <= Qt.Key_Z) return String.fromCharCode(event.key)
    if (event.key >= Qt.Key_0 && event.key <= Qt.Key_9) return String.fromCharCode(event.key)
    if (event.key >= Qt.Key_F1 && event.key <= Qt.Key_F35) return "F" + (event.key - Qt.Key_F1 + 1)
    switch (event.key) {
      case Qt.Key_Space: return "space"
      case Qt.Key_Tab: return "Tab"
      case Qt.Key_Return: case Qt.Key_Enter: return "Return"
      case Qt.Key_Backspace: return "BackSpace"
      case Qt.Key_Delete: return "Delete"
      case Qt.Key_Insert: return "Insert"
      case Qt.Key_Home: return "Home"
      case Qt.Key_End: return "End"
      case Qt.Key_PageUp: return "Prior"
      case Qt.Key_PageDown: return "Next"
      case Qt.Key_Up: return "Up"
      case Qt.Key_Down: return "Down"
      case Qt.Key_Left: return "Left"
      case Qt.Key_Right: return "Right"
      case Qt.Key_Comma: return "comma"
      case Qt.Key_Period: return "period"
      default: return ""
    }
  }

  Keys.onPressed: function(event) {
    if (!root.recording) return
    event.accepted = true

    if (event.key === Qt.Key_Escape) { root.recording = false; return }
    // A bare modifier press (no "real" key yet) — keep listening.
    if (event.key === Qt.Key_Control || event.key === Qt.Key_Shift ||
        event.key === Qt.Key_Alt || event.key === Qt.Key_Meta) return

    var mods = []
    if (event.modifiers & Qt.MetaModifier) mods.push("SUPER")
    if (event.modifiers & Qt.ControlModifier) mods.push("CTRL")
    if (event.modifiers & Qt.ShiftModifier) mods.push("SHIFT")
    if (event.modifiers & Qt.AltModifier) mods.push("ALT")
    // Require a modifier so this can never capture a plain typing key.
    if (mods.length === 0) return

    var key = root.keyName(event)
    if (!key) return

    root.recording = false
    var bind = mods.join(" ") + ", " + key
    root.value = bind
    root.changed(bind)
  }

  onActiveFocusChanged: if (!activeFocus) recording = false

  Button {
    id: pill
    anchors.fill: parent
    text: root.displayText()
    fontSize: Style.font.bodySmall
    foreground: Color.popups.text
    horizontalPadding: Style.spacing.controlPaddingX
    verticalPadding: Style.spacing.controlPaddingY + Style.space(2)
    bordered: true
    active: root.recording
    onClicked: {
      root.recording = !root.recording
      if (root.recording) root.forceActiveFocus()
    }
  }
}
