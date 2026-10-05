import QtQuick
import qs.Ui
import qs.Commons

BarWidget {
  id: root
  moduleName: "game-overlay"

  readonly property var gameService: bar?.shell?.serviceFor("game-overlay")
  readonly property bool active: gameService ? gameService.live : false
  readonly property bool followTheme: gameService ? gameService.settings.followTheme : false

  property bool popupOpen: false

  // PopupCard's own close() falls back to directly setting its `open`
  // property when the owner has no close() of its own — and that imperative
  // assignment permanently breaks the `open: root.popupOpen` binding below,
  // since QML replaces a binding with a plain value the moment something
  // assigns to it imperatively. The bar calls this (via `owner: root`) when
  // another widget's popup opens, to enforce only one open at a time; without
  // this method that coordination was exactly what got the popup stuck closed
  // until the whole widget got recreated (e.g. by moving its bar position).
  function close() { root.popupOpen = false }

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
    onPressed: root.popupOpen = !root.popupOpen
  }

  PopupCard {
    id: popup
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.popupOpen
    contentWidth: popup.fittedContentWidth(Style.space(300))
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

      ColorField {
        label: "Label color"
        visible: !root.followTheme
        value: root.gameService ? root.gameService.settings.labelColor : "#6C9BD9"
        onChanged: function(v) {
          if (!root.gameService) return
          root.gameService.settings.labelColor = v
          root.gameService.saveSettings()
        }
      }

      ColorField {
        label: "Background"
        visible: !root.followTheme
        value: root.gameService ? root.gameService.settings.backgroundColor : "#101518"
        onChanged: function(v) {
          if (!root.gameService) return
          root.gameService.settings.backgroundColor = v
          root.gameService.saveSettings()
        }
      }

      PanelSeparator { foreground: Color.popups.text }

      PanelSectionHeader { text: "TEMPERATURE UNIT"; foreground: Color.popups.text }

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
  }
}
