import QtQuick
import qs.Ui
import qs.Commons

BarWidget {
  id: root
  moduleName: "game-overlay"

  readonly property var gameService: bar?.shell?.serviceFor("game-overlay")
  readonly property bool active: gameService ? gameService.live : false
  readonly property bool followTheme: gameService ? gameService.settings.followTheme : false

  // Which swatch the shared hue/saturation/lightness controls below are
  // currently editing. Transient (not persisted) — resets to "label" each
  // time the popup is recreated, which is fine for a selector like this.
  property string colorTarget: "label"

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

  // WidgetButton below already hides itself (hasVisualContent: root.active),
  // but that's invisible to the bar's own sizing: Bar.qml's ModuleSlot sizes
  // off *this* root item's visible/implicitWidth, not the button it wraps.
  // Without this, the slot kept reserving WidgetButton's ~12px minimum width
  // even while inactive — a persistent empty gap in the bar between whatever
  // this widget sits next to. Stays visible while the popup is open even if
  // the game just exited, so it doesn't vanish out from under an open popup.
  visible: root.active || root.popupOpen
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  // BarIconButton (a WidgetButton that also supports a custom iconComponent,
  // same primitive Dropbox/Tailscale's bar icons use) rather than plain
  // WidgetButton — this shows the pill logo instead of the live "FPS <n>"
  // text; the actual numbers still show on the overlay pill itself, this is
  // just what's clickable in the bar.
  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    iconComponent: Component {
      PillIcon {
        anchors.centerIn: parent
        color: button.foreground
      }
    }
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

      // Hero: pill icon · title · subtext — copied field-for-field from
      // bluetooth's own hero (plugins/panels/bluetooth/Panel.qml), down to
      // the font tokens and the font.family binding to root.bar.fontFamily
      // (missing that was why the title font didn't actually match before).
      Item {
        width: parent.width
        implicitHeight: Math.max(heroIcon.implicitHeight, heroLabels.implicitHeight)

        PillIcon {
          id: heroIcon
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          iconWidth: Style.space(36)
          iconHeight: Style.space(18)
          color: root.bar ? root.bar.foreground : Color.popups.text
        }

        Column {
          id: heroLabels
          anchors.left: heroIcon.right
          anchors.leftMargin: Style.space(14)
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.space(2)

          Text {
            text: "Pill overlay"
            color: root.bar ? root.bar.foreground : Color.popups.text
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.title
            font.bold: true
            elide: Text.ElideRight
            width: parent.width
          }

          Text {
            textFormat: Text.PlainText
            text: "FPS overlay for your games".toUpperCase()
            color: Qt.darker(root.bar ? root.bar.foreground : Color.popups.text, 1.4)
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
            font.letterSpacing: 1.2
            elide: Text.ElideRight
            width: parent.width
          }
        }
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

      // EXPERIMENTAL, modeled on a Figma mockup: a saturation/value box + hue
      // slider + swatch + editable hex (ColorPickerField.qml), shared between
      // both swatches via these two pill buttons rather than repeated per
      // swatch. Earlier experiment (3 plain sliders: HueColorField.qml) and
      // the original hex-only ColorField.qml are both still here, untouched,
      // if this one doesn't stick — swap the component below for either.
      Row {
        id: colorTargetRow
        width: parent.width
        visible: !root.followTheme
        spacing: Style.space(6)

        readonly property real cellWidth: (width - spacing) / 2

        Button {
          text: "Label color"
          width: colorTargetRow.cellWidth
          fontSize: Style.font.bodySmall
          foreground: Color.popups.text
          horizontalPadding: Style.spacing.controlPaddingX
          verticalPadding: Style.spacing.controlPaddingY + Style.space(2)
          bordered: true
          active: root.colorTarget === "label"
          onClicked: root.colorTarget = "label"
        }

        Button {
          text: "Background"
          width: colorTargetRow.cellWidth
          fontSize: Style.font.bodySmall
          foreground: Color.popups.text
          horizontalPadding: Style.spacing.controlPaddingX
          verticalPadding: Style.spacing.controlPaddingY + Style.space(2)
          bordered: true
          active: root.colorTarget === "background"
          onClicked: root.colorTarget = "background"
        }
      }

      ColorPickerField {
        visible: !root.followTheme
        value: {
          if (!root.gameService) return root.colorTarget === "label" ? "#6C9BD9" : "#101518"
          return root.colorTarget === "label" ? root.gameService.settings.labelColor : root.gameService.settings.backgroundColor
        }
        onMoved: function(hex) {
          if (!root.gameService) return
          if (root.colorTarget === "label") root.gameService.settings.labelColor = hex
          else root.gameService.settings.backgroundColor = hex
        }
        onReleased: function(hex) {
          if (!root.gameService) return
          if (root.colorTarget === "label") root.gameService.settings.labelColor = hex
          else root.gameService.settings.backgroundColor = hex
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
