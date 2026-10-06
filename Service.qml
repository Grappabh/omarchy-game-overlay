import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Shared background state for both Panel.qml and BarWidget.qml: the CSV
// watcher, MangoHud.conf provisioning, and the user settings file all live
// here once so neither entry point duplicates them. The shell auto-injects
// this into Panel via `service`; BarWidget looks it up explicitly through
// `bar.shell.serviceFor("game-overlay")`.
Item {
  id: root

  property var shell: null

  readonly property string watchScript: Qt.resolvedUrl("watch-latest.sh").toString().replace("file://", "")
  readonly property string ensureConfigScript: Qt.resolvedUrl("ensure-mangohud-config.sh").toString().replace("file://", "")
  readonly property string ensureHyprlandEnvScript: Qt.resolvedUrl("ensure-hyprland-env.sh").toString().replace("file://", "")
  readonly property string ensureShortcutScript: Qt.resolvedUrl("ensure-hyprland-shortcut.sh").toString().replace("file://", "")

  // Transient, not persisted. Shared between BarWidget.qml and Panel.qml so
  // both can drive the same popup: our manifest's kinds include "panel" (for
  // the always-on overlay pill), which makes shell.toggle(id) — the path
  // Super+Ctrl+1-9 and other IPC-driven opens use — route to the "panel"
  // entry point (Panel.qml) instead of the bar widget's own open()/close().
  // Panel.qml's open()/close() flip this flag; BarWidget's PopupCard watches
  // it the same way a direct click on the bar icon does.
  property bool popupOpen: false

  property real fpsVal: 0
  property real cpuLoad: 0
  property real cpuTemp: 0
  property real gpuLoad: 0
  property real gpuTemp: 0
  property real lastUpdateMs: 0

  // Date.now() isn't a QML binding dependency, so `live` is re-evaluated on
  // every heartbeat tick instead of only once at startup.
  property int heartbeat: 0
  readonly property bool live: heartbeat >= 0 && (Date.now() - root.lastUpdateMs) < 2200

  // Only show on the monitor that actually has the fullscreen game on it —
  // layer-shell surfaces are per-output, so without this the pill would
  // otherwise follow the user to every workspace/monitor they switch to.
  // Scanning each toplevel's own fullscreen flag directly (rather than trusting
  // the workspace-level `hasFullscreen` aggregate, which didn't track correctly
  // in practice) so this matches exactly what `hyprctl clients -j` reports.
  function workspaceHasFullscreenWindow(ws) {
    if (!ws) return false
    var tops = ws.toplevels.values
    for (var i = 0; i < tops.length; i++) {
      var ipc = tops[i].lastIpcObject
      if (ipc && ipc.fullscreen) return true
    }
    return false
  }

  // CSV columns (MangoHud logging.cpp):
  // fps, frametime, cpu_load, cpu_power, gpu_load, cpu_temp, gpu_temp, ...
  function parseLine(line) {
    var parts = line.split(",")
    if (parts.length < 7) return
    var f = parseFloat(parts[0])
    if (!isFinite(f)) return // header row or garbage, ignore
    root.fpsVal = f
    root.cpuLoad = parseFloat(parts[2])
    root.gpuLoad = parseFloat(parts[4])
    root.cpuTemp = parseFloat(parts[5])
    root.gpuTemp = parseFloat(parts[6])
    root.lastUpdateMs = Date.now()
  }

  function fmtPct(v) { return (isFinite(v) ? Math.round(v) : 0) + "%" }
  function fmtTemp(v, fahrenheit) {
    var c = isFinite(v) ? v : 0
    var t = fahrenheit ? c * 9 / 5 + 32 : c
    return Math.round(t) + "°" + (fahrenheit ? "F" : "C")
  }
  function fmtFps(v) { return String(isFinite(v) ? Math.round(v) : 0) }

  // User-adjustable: panel/bar-widget settings UIs in Omarchy are either
  // schema-driven (bar-widget only, and that writes into shell.json rather
  // than a plugin-owned file) or nonexistent (panel). This file is our own
  // customization surface instead, shared by both entry points — hand-edit
  // it directly, or use the bar-widget's popup, and either way it reloads
  // live. Auto-created with these defaults the first time it's missing.
  FileView {
    id: settingsFile
    // Deliberately NOT under this plugin's own directory: Omarchy's plugin
    // hot-reload watches that whole folder for source changes, so writing
    // settings there was triggering a full "Local plugin changed, reloading"
    // cycle on every single settings change — tearing down and recreating
    // the bar widget (closing its popup) as if from a code edit.
    path: Quickshell.env("HOME") + "/.config/omarchy/game-overlay-settings.json"
    watchChanges: true
    onFileChanged: reload()
    // Loading a file that doesn't exist yet only warns and falls back to the
    // JsonAdapter's declared defaults below — it doesn't create the file on
    // its own, so write it out once here to give users a real template.
    // Besides the defaults-fallback above, this is also the one point where
    // the real persisted (or just-defaulted) values are known, so it's the
    // right place to sync the Hyprland shortcut once per load — not a
    // standalone always-running Process, since that would read the
    // JsonAdapter's declared default before this async load had a chance to
    // overwrite it with whatever the user last recorded.
    onLoaded: root.applyShortcut()
    onLoadFailed: function(error) {
      if (error === FileViewError.FileNotFound) {
        writeAdapter()
        root.applyShortcut()
      }
    }

    JsonAdapter {
      id: settingsAdapter
      property int fontSize: 16
      property string labelColor: "#6C9BD9"
      property string backgroundColor: "#101518"
      property real backgroundOpacity: 0.85
      // One of: top-left, top-center, top-right, bottom-left, bottom-center,
      // bottom-right.
      property string position: "top-center"
      // When true, labelColor/backgroundColor are ignored in favor of the
      // live Omarchy theme's accent/popup colors.
      property bool followTheme: false
      property bool fahrenheit: false
      // Whether the overlay pill itself is shown while a game is live —
      // toggled by the Hyprland shortcut below (and only by it; the bar
      // widget and its settings popup stay available regardless, so the
      // user always has a way back in if they forget the shortcut).
      property bool overlayVisible: true
      // Hyprland bind syntax: "<space-separated mods>, <key>", e.g.
      // "SUPER CTRL, G". Applied via ensure-hyprland-shortcut.sh.
      property string shortcut: "SUPER CTRL, G"
    }
  }

  // Exposed as a real property (an `id` alone isn't reachable from outside
  // this file) so Panel.qml and BarWidget.qml can both read/write it via
  // `service.settings.xxx`.
  readonly property var settings: settingsAdapter
  // Called after the bar-widget's settings popup changes a value — JsonAdapter
  // updates the in-memory property immediately either way, but this is what
  // actually writes it back to disk.
  function saveSettings() { settingsFile.writeAdapter() }

  // Syncs the Hyprland-side keybind to settings.shortcut: once per load (see
  // the FileView handlers above) and again whenever the user records a new
  // one from the bar widget's settings popup.
  function applyShortcut() {
    Quickshell.execDetached(["bash", root.ensureShortcutScript, root.settings.shortcut])
  }

  // Hit by the Hyprland keybind ensure-hyprland-shortcut.sh sets up
  // ("omarchy-shell game-overlay toggleVisibility"). A plain show/hide flag
  // rather than routing through the host's shell.toggle(id) machinery, since
  // that's keyed to the popup (see popupOpen above), not the pill.
  IpcHandler {
    target: "game-overlay"
    function toggleVisibility(): void {
      root.settings.overlayVisible = !root.settings.overlayVisible
      root.saveSettings()
    }
  }

  Timer {
    interval: 500
    running: true
    repeat: true
    onTriggered: {
      // A freshly-created toplevel (e.g. right after a game relaunch) often
      // never gets its fullscreen info delivered via Hyprland's incremental
      // event stream, leaving lastIpcObject permanently undefined. Forcing a
      // full re-sync here keeps it populated regardless.
      Hyprland.refreshToplevels()
      root.heartbeat++
    }
  }

  // One-shot, runs once per plugin load: makes sure MangoHud.conf has what
  // this plugin needs, without touching anything it doesn't (see the script
  // itself for the safe-merge/notify-instead-of-overwrite logic).
  Process {
    command: ["bash", root.ensureConfigScript]
    running: true
  }

  // One-shot: makes sure MANGOHUD=1 is set globally in Hyprland's own config
  // (the one setup step that truly can't be done from inside Quickshell) so
  // enabling the plugin alone is enough — no manual config editing required.
  // Additive-only and self-validating; see the script for the rollback logic.
  Process {
    command: ["bash", root.ensureHyprlandEnvScript]
    running: true
  }

  Process {
    id: watcher
    command: ["bash", root.watchScript]
    stdout: SplitParser { onRead: function(line) { root.parseLine(line) } }
    running: true
  }
}
