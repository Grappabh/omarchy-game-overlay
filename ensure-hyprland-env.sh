#!/bin/bash
# Makes sure MANGOHUD=1 is set globally for the Hyprland session, so every
# Vulkan/OpenGL/Proton game launched picks it up automatically — the one
# setup step that can't be done from inside Quickshell itself, since it's
# core window-manager config, not plugin config.
#
# Omarchy installs come in two flavors: a newer Lua-based config
# (~/.config/hypr/hyprland.lua, using `hl.env(...)`) or the classic hyprlang
# format (~/.config/hypr/hyprland.conf, using `env = KEY,VALUE`). Rather than
# guess which one is actually active, this adds the right line to whichever
# file(s) exist — harmless if a file turns out to be inactive/unused, since
# an inert file sourced by nothing changes nothing.
#
# Always additive, never touches or removes an existing line, and validates
# with `hyprctl configerrors` afterward — if our own addition is what
# introduces a new error, it's rolled back automatically rather than left in
# place to break the user's Hyprland config.

set -u

HYPR_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
LUA_FILE="$HYPR_DIR/hyprland.lua"
CONF_FILE="$HYPR_DIR/hyprland.conf"

changed_lua=0
changed_conf=0

if [ -f "$LUA_FILE" ] && ! grep -q 'hl\.env("MANGOHUD"' "$LUA_FILE"; then
  cp "$LUA_FILE" "$LUA_FILE.pill-overlay-backup"
  {
    echo ""
    echo "-- Added by the Pill overlay plugin: lets Vulkan/OpenGL/Proton"
    echo "-- games pick up MangoHud automatically."
    echo 'hl.env("MANGOHUD", "1")'
  } >> "$LUA_FILE"
  changed_lua=1
fi

if [ -f "$CONF_FILE" ] && ! grep -qE '^[[:space:]]*env[[:space:]]*=[[:space:]]*MANGOHUD' "$CONF_FILE"; then
  cp "$CONF_FILE" "$CONF_FILE.pill-overlay-backup"
  {
    echo ""
    echo "# Added by the Pill overlay plugin: lets Vulkan/OpenGL/Proton"
    echo "# games pick up MangoHud automatically."
    echo "env = MANGOHUD,1"
  } >> "$CONF_FILE"
  changed_conf=1
fi

# Nothing to do (already configured, or neither file exists).
if [ "$changed_lua" -eq 0 ] && [ "$changed_conf" -eq 0 ]; then
  exit 0
fi

if ! command -v hyprctl >/dev/null 2>&1; then
  exit 0
fi

before_errors=$(hyprctl configerrors 2>/dev/null)
hyprctl reload >/dev/null 2>&1
sleep 0.5
after_errors=$(hyprctl configerrors 2>/dev/null)

# Only roll back if our edit is what changed the error state — a pre-existing
# unrelated error (present both before and after) isn't ours to revert.
if [ -n "$after_errors" ] && [ "$after_errors" != "$before_errors" ]; then
  [ "$changed_lua" -eq 1 ] && [ -f "$LUA_FILE.pill-overlay-backup" ] && mv "$LUA_FILE.pill-overlay-backup" "$LUA_FILE"
  [ "$changed_conf" -eq 1 ] && [ -f "$CONF_FILE.pill-overlay-backup" ] && mv "$CONF_FILE.pill-overlay-backup" "$CONF_FILE"
  hyprctl reload >/dev/null 2>&1
  notify-send "Pill overlay plugin" "Couldn't automatically enable MangoHud for your games (a config error was detected, so the change was rolled back). Please add it manually — see the plugin's README." 2>/dev/null || true
  exit 0
fi

rm -f "$LUA_FILE.pill-overlay-backup" "$CONF_FILE.pill-overlay-backup" 2>/dev/null
notify-send "Pill overlay plugin" "MangoHud is now enabled automatically for games in this session." 2>/dev/null || true
