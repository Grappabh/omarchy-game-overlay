import QtQuick
import qs.Ui
import qs.Commons

BarWidget {
  id: root
  moduleName: "game-overlay"

  readonly property var gameService: bar?.shell?.serviceFor("game-overlay")
  readonly property bool active: gameService ? gameService.live : false
  readonly property bool followTheme: gameService ? gameService.settings.followTheme : false

  // Backed by the service (not a local property) so Super+Ctrl+1-9 — which
  // calls shell.toggle("game-overlay") and, because our manifest's kinds
  // include "panel", actually opens/closes via Panel.qml's open()/close()
  // rather than ours — ends up toggling the exact same popup a direct click
  // does. See Service.qml's popupOpen for the full explanation.
  readonly property bool popupOpen: gameService ? gameService.popupOpen : false

  // Shape contract for shell.summon/hide/toggle and the Super+Ctrl+N bar
  // hotkeys: Bar.panelNavigationSlots only counts a widget as a panel if it
  // has open()/close()/opened, so all three are required, not just close().
  readonly property bool opened: root.popupOpen

  function open() { if (root.gameService) root.gameService.popupOpen = true }

  // PopupCard's own close() falls back to directly setting its `open`
  // property when the owner has no close() of its own — and that imperative
  // assignment permanently breaks the `open: root.popupOpen` binding below,
  // since QML replaces a binding with a plain value the moment something
  // assigns to it imperatively. The bar calls this (via `owner: root`) when
  // another widget's popup opens, to enforce only one open at a time; without
  // this method that coordination was exactly what got the popup stuck closed
  // until the whole widget got recreated (e.g. by moving its bar position).
  function close() { if (root.gameService) root.gameService.popupOpen = false }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  // The same visual/interaction primitive every other bar-widget plugin
  // uses (clock, network, ...) — gets us the shared hover highlight, tooltip
  // timing, and text rendering for free instead of a bespoke Text+MouseArea.
  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.active ? "FPS " + root.gameService.fmtFps(root.gameService.fpsVal) : ""
    hasVisualContent: root.active
    onPressed: if (root.gameService) root.gameService.popupOpen = !root.gameService.popupOpen
  }

  // KeyboardPanel rather than PopupCard: PopupCard is an xdg-popup tied to
  // the bar's own (WlrLayer.Top) surface, which a true fullscreen game's
  // surface renders above — same layer problem our own always-on pill in
  // Panel.qml solves with WlrLayer.Overlay. KeyboardPanel is a real
  // layer-shell surface already set to WlrLayer.Overlay for exactly this
  // reason (it's what bluetooth/network's popups use, which is why those
  // stay visible and interactive over a fullscreen game while a plain
  // PopupCard-based popup wouldn't). Same API otherwise — drop-in swap.
  KeyboardPanel {
    id: popup
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.popupOpen
    contentWidth: popup.fittedContentWidth(Style.space(320))
    contentHeight: popup.fittedContentHeight(column.implicitHeight)

    Column {
      id: column
      anchors.fill: parent
      spacing: Style.space(12)

      Text {
        text: "Game overlay"
        color: Color.popups.text
        font.pixelSize: Style.font.heading
        font.bold: true
      }

      PanelSeparator { foreground: Color.popups.text }

      PanelSectionHeader { text: "POSITION"; foreground: Color.popups.text }

      PositionPicker {
        value: root.gameService ? root.gameService.settings.position : "top-center"
        onChanged: function(v) {
          if (!root.gameService) return
          root.gameService.settings.position = v
          root.gameService.saveSettings()
        }
      }

      PanelSeparator { foreground: Color.popups.text }

      PanelSectionHeader { text: "SIZE & OPACITY"; foreground: Color.popups.text }

      SliderField {
        label: "Font size"
        value: root.gameService ? root.gameService.settings.fontSize : 16
        min: 10; max: 32; step: 1; integer: true
        onMoved: function(v) { if (root.gameService) root.gameService.settings.fontSize = v }
        onReleased: function(v) { if (root.gameService) root.gameService.saveSettings() }
      }

      SliderField {
        label: "Opacity"
        value: root.gameService ? root.gameService.settings.backgroundOpacity : 0.85
        min: 0; max: 1; step: 0.05; decimals: 2
        onMoved: function(v) { if (root.gameService) root.gameService.settings.backgroundOpacity = v }
        onReleased: function(v) { if (root.gameService) root.gameService.saveSettings() }
      }

      PanelSeparator { foreground: Color.popups.text }

      PanelSectionHeader { text: "COLORS"; foreground: Color.popups.text }

      Row {
        id: colorModeRow
        width: parent.width
        spacing: Style.space(6)

        readonly property real cellWidth: (width - spacing) / 2

        Button {
          text: "Custom"
          width: colorModeRow.cellWidth
          fontSize: Style.font.bodySmall
          foreground: Color.popups.text
          horizontalPadding: Style.spacing.controlPaddingX
          verticalPadding: Style.spacing.controlPaddingY + Style.space(2)
          bordered: true
          active: !root.followTheme
          onClicked: {
            if (!root.gameService) return
            root.gameService.settings.followTheme = false
            root.gameService.saveSettings()
          }
        }

        Button {
          text: "Theme"
          width: colorModeRow.cellWidth
          fontSize: Style.font.bodySmall
          foreground: Color.popups.text
          horizontalPadding: Style.spacing.controlPaddingX
          verticalPadding: Style.spacing.controlPaddingY + Style.space(2)
          bordered: true
          active: root.followTheme
          onClicked: {
            if (!root.gameService) return
            root.gameService.settings.followTheme = true
            root.gameService.saveSettings()
          }
        }
      }

      // EXPERIMENTAL: hue/saturation/lightness sliders instead of hex entry
      // (HueColorField.qml). To revert, swap both back to ColorField with a
      // single value/onChanged each — see git history for the exact block.
      HueColorField {
        label: "Label color"
        visible: !root.followTheme
        value: root.gameService ? root.gameService.settings.labelColor : "#6C9BD9"
        onMoved: function(hex) { if (root.gameService) root.gameService.settings.labelColor = hex }
        onReleased: function(hex) {
          if (!root.gameService) return
          root.gameService.settings.labelColor = hex
          root.gameService.saveSettings()
        }
      }

      HueColorField {
        label: "Background"
        visible: !root.followTheme
        value: root.gameService ? root.gameService.settings.backgroundColor : "#101518"
        onMoved: function(hex) { if (root.gameService) root.gameService.settings.backgroundColor = hex }
        onReleased: function(hex) {
          if (!root.gameService) return
          root.gameService.settings.backgroundColor = hex
          root.gameService.saveSettings()
        }
      }

      PanelSeparator { foreground: Color.popups.text }

      Row {
        spacing: Style.space(24)

        Column {
          spacing: Style.space(6)

          PanelSectionHeader { text: "TEMPERATURE"; foreground: Color.popups.text }

          Row {
            spacing: Style.space(8)
            Text {
              text: "°C"
              color: Color.popups.text
              font.pixelSize: Style.font.body
              anchors.verticalCenter: parent.verticalCenter
            }
            ToggleSwitch {
              checked: root.gameService ? root.gameService.settings.fahrenheit : false
              anchors.verticalCenter: parent.verticalCenter
              onToggled: {
                if (!root.gameService) return
                root.gameService.settings.fahrenheit = !root.gameService.settings.fahrenheit
                root.gameService.saveSettings()
              }
            }
            Text {
              text: "°F"
              color: Color.popups.text
              font.pixelSize: Style.font.body
              anchors.verticalCenter: parent.verticalCenter
            }
          }
        }

        Column {
          spacing: Style.space(6)

          PanelSectionHeader { text: "SHOW/HIDE"; foreground: Color.popups.text }

          ShortcutRecorder {
            width: Style.space(140)
            value: root.gameService ? root.gameService.settings.shortcut : ""
            onChanged: function(bind) {
              if (!root.gameService) return
              root.gameService.settings.shortcut = bind
              root.gameService.saveSettings()
              root.gameService.applyShortcut()
            }
          }
        }
      }
    }
  }
}
