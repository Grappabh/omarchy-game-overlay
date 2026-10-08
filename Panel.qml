import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.Commons

// Auto-injected by the shell since the manifest declares a "service" kind:
// see shell.qml's panel loader (`item.service = shell.serviceFor(pluginId)`).
Item {
  id: root

  property var service: null

  // Shape contract for shell.summon/hide/toggle: because our manifest's
  // kinds include "panel", any shell.toggle(id) call (notably
  // from the Super+Ctrl+1-9 bar hotkeys) is routed to THIS entry point
  // rather than the bar widget's own open()/close() — see
  // isBarWidgetPanelPlugin in the host's shell.qml. Forwarding to the same
  // shared service flag BarWidget.qml's popup watches means the hotkey and
  // a direct click on the bar icon end up controlling the same popup.
  readonly property bool opened: service ? service.popupOpen : false
  function open() { if (root.service) root.service.popupOpen = true }
  function close() { if (root.service) root.service.popupOpen = false }

  readonly property int pillFontSize: service ? service.settings.fontSize : 16

  readonly property bool followTheme: service ? service.settings.followTheme : false
  // `color` properties auto-convert a hex string on assignment, which is the
  // only way to turn a settings string into something with .r/.g/.b
  // components — Qt.rgba() needs those to apply a separate opacity value.
  readonly property color customBackground: service ? service.settings.backgroundColor : "#101518"
  readonly property color effectiveLabelColor: followTheme ? Color.accent : (service ? service.settings.labelColor : "#6C9BD9")
  readonly property color effectiveBackground: followTheme ? Color.popups.background : customBackground

  // One of top-left/top-center/top-right/bottom-left/bottom-center/bottom-right.
  readonly property string pos: service ? service.settings.position : "top-center"
  readonly property bool posTop: root.pos.indexOf("top") === 0
  readonly property bool posBottom: root.pos.indexOf("bottom") === 0
  readonly property bool posLeft: root.pos.indexOf("left") >= 0
  readonly property bool posRight: root.pos.indexOf("right") >= 0
  readonly property bool posCenterH: root.pos.indexOf("center") >= 0

  // Bundled alongside this plugin so it doesn't depend on ttf-opensans being
  // installed system-wide; if it somehow fails to load, font.family falls
  // back to empty string, which Qt Quick resolves to the default system font.
  FontLoader { id: pillFont; source: "OpenSans-Light.ttf" }

  // One panel per connected monitor, each independently shown only when ITS
  // monitor currently displays the fullscreen game — so on a multi-monitor
  // setup the pill appears on the right screen instead of on all of them (or
  // on whichever one happened to be targeted by default).
  Variants {
    model: Quickshell.screens

    delegate: Component {
      // A Loader fully creates/destroys the panel (and its Wayland layer-shell
      // surface) based on `active`, instead of leaving the surface mapped and
      // merely toggling a `visible` property — which didn't reliably unmap it.
      Loader {
        id: screenLoader
        required property var modelData
        readonly property var myMonitor: Hyprland.monitorFor(modelData)
        // Reads `service.heartbeat` purely to force a re-check every 500ms as
        // a safety net: right after a game relaunches, Hyprland briefly
        // reports the new window with no fullscreen info yet (lastIpcObject
        // arrives a beat later over IPC), and relying solely on its change
        // signal left this stuck at `false`.
        readonly property bool onThisScreen: root.service && (root.service.heartbeat, screenLoader.myMonitor ? root.service.workspaceHasFullscreenWindow(screenLoader.myMonitor.activeWorkspace) : false)
        active: root.service && root.service.live && screenLoader.onThisScreen && root.service.settings.overlayVisible

        sourceComponent: PanelWindow {
          screen: screenLoader.modelData
          anchors { top: true; bottom: true; left: true; right: true }
          color: "transparent"
          WlrLayershell.namespace: "pill-overlay"
          WlrLayershell.layer: WlrLayer.Overlay
          WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
          exclusionMode: ExclusionMode.Ignore
          // Visual-only: empty input region so the pill never blocks clicks to
          // whatever is underneath it (the game).
          mask: Region {}

          Rectangle {
            id: pill
            readonly property int edgeMargin: 16

            // Plain x/y instead of anchors: toggling 4 separate anchor line
            // bindings (top/bottom/left/right) on a position switch isn't
            // atomic — QML can briefly apply e.g. the new top anchor before
            // the old bottom one clears, and a conflicting pair of anchors
            // overrides the explicit width/height below with a stretch-to-fill,
            // which then doesn't reliably unstick. A single x/y expression per
            // axis has no such transient conflicting state to get stuck in.
            x: root.posCenterH ? (parent.width - width) / 2
              : (root.posRight ? parent.width - width - edgeMargin : edgeMargin)
            y: root.posBottom ? parent.height - height - edgeMargin : edgeMargin
            width: content.implicitWidth + 44
            height: content.implicitHeight + 20
            radius: height / 2
            color: Qt.rgba(root.effectiveBackground.r, root.effectiveBackground.g, root.effectiveBackground.b, root.service ? root.service.settings.backgroundOpacity : 0.85)

            Row {
              id: content
              anchors.centerIn: parent
              spacing: 22

              // No anchors here: these are direct children of the "content"
              // Row above, and anchoring a Positioner's child to its parent
              // (even just verticalCenter) fights the Positioner's own layout
              // pass — it was producing a runaway implicitHeight on "content"
              // (and hence this pill, since height is derived from it)
              // whenever the pill's own anchors changed, i.e. on every
              // position switch. All three rows already share the same
              // font.pixelSize, so they're already the same height without it.
              Row {
                spacing: 7
                Text { text: "CPU"; color: root.effectiveLabelColor; font.family: pillFont.name; font.pixelSize: root.pillFontSize }
                Text { text: root.service ? root.service.fmtPct(root.service.cpuLoad) : ""; color: "white"; font.family: pillFont.name; font.pixelSize: root.pillFontSize }
                Text { text: root.service ? root.service.fmtTemp(root.service.cpuTemp, root.service.settings.fahrenheit) : ""; color: "white"; font.family: pillFont.name; font.pixelSize: root.pillFontSize }
              }
              Row {
                spacing: 7
                Text { text: "GPU"; color: root.effectiveLabelColor; font.family: pillFont.name; font.pixelSize: root.pillFontSize }
                Text { text: root.service ? root.service.fmtPct(root.service.gpuLoad) : ""; color: "white"; font.family: pillFont.name; font.pixelSize: root.pillFontSize }
                Text { text: root.service ? root.service.fmtTemp(root.service.gpuTemp, root.service.settings.fahrenheit) : ""; color: "white"; font.family: pillFont.name; font.pixelSize: root.pillFontSize }
              }
              Row {
                spacing: 7
                Text { text: "FPS"; color: root.effectiveLabelColor; font.family: pillFont.name; font.pixelSize: root.pillFontSize }
                Text { text: root.service ? root.service.fmtFps(root.service.fpsVal) : ""; color: "white"; font.family: pillFont.name; font.pixelSize: root.pillFontSize }
              }
            }
          }
        }
      }
    }
  }
}
