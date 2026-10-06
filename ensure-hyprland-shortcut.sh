#!/bin/bash
# Keeps the game-overlay plugin's show/hide shortcut in sync with Hyprland.
#
# Two things have to happen, because of a quirk in this Omarchy build's
# Hyprland+Lua setup confirmed by hand: `hyprctl reload` does NOT re-register
# a newly added or changed `bind`/`bindd` line, whether it's in a brand-new
# sourced file or appended to an already-sourced one — only a real Hyprland
# startup parses those. The one thing that DOES take effect immediately is
# `hyprctl eval 'o.bind(...)'`, which calls the same registration Hyprland's
# own startup uses, live. So:
#   1. Persist the bind to a dedicated, fully-owned file (sourced from
#      hyprland.conf once, additively) so it survives a real Hyprland
#      restart/reboot, the same way every other custom keybind here does.
#   2. Also register it live via `hyprctl eval` so it works immediately,
#      without making the user restart Hyprland just to test a shortcut
#      they just recorded.
# Run both at every plugin load (with the persisted shortcut) and on demand
# whenever the user records a new one.
#
# Reload happens BEFORE the eval, not after: eval-registered binds stack up
# as separate duplicates if called repeatedly without a reload in between
# (confirmed by hand — two evals with no reload between them left two
# identical bindings active), while reload harmlessly resets the live bind
# table back to whatever the static files say (which, per the quirk above,
# never includes our own bind) — so reload-then-eval always lands on exactly
# one live registration, however many times this script runs.

set -u

HYPR_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
CONF_FILE="$HYPR_DIR/hyprland.conf"
SHORTCUT_FILE="$HYPR_DIR/game-overlay-shortcut.conf"
BIND="${1:-SUPER CTRL, G}"  # hyprlang syntax: "<space-separated MODS>, <key>"

mods=$(echo "${BIND%%,*}" | xargs)
key=$(echo "${BIND#*,}" | xargs)
lua_keys=$(echo "$mods $key" | sed 's/  */ + /g')

# One-time, additive: make sure hyprland.conf loads our dedicated file (for
# persistence across a real restart — see above). Never touches anything
# else in hyprland.conf.
if [ -f "$CONF_FILE" ] && ! grep -qF "source = $SHORTCUT_FILE" "$CONF_FILE"; then
  cp "$CONF_FILE" "$CONF_FILE.game-overlay-shortcut-backup"
  {
    echo ""
    echo "# Added by the game-overlay plugin: persists its user-configurable"
    echo "# show/hide shortcut (recorded from the bar widget's settings"
    echo "# popup) across a real Hyprland restart."
    echo "source = $SHORTCUT_FILE"
  } >> "$CONF_FILE"

  if command -v hyprctl >/dev/null 2>&1; then
    before_errors=$(hyprctl configerrors 2>/dev/null)
    hyprctl reload >/dev/null 2>&1
    sleep 0.5
    after_errors=$(hyprctl configerrors 2>/dev/null)
    if [ -n "$after_errors" ] && [ "$after_errors" != "$before_errors" ]; then
      mv "$CONF_FILE.game-overlay-shortcut-backup" "$CONF_FILE"
      hyprctl reload >/dev/null 2>&1
      notify-send "game-overlay plugin" "Couldn't set up the show/hide shortcut automatically. See the plugin's README." 2>/dev/null || true
      exit 0
    fi
  fi
  rm -f "$CONF_FILE.game-overlay-shortcut-backup" 2>/dev/null
fi

# Fully owned by us — always safe to overwrite outright.
cat > "$SHORTCUT_FILE" <<EOF
# Managed by the game-overlay plugin. Re-generated whenever the shortcut is
# re-recorded from the bar widget's settings popup — don't hand-edit.
# (Only takes effect on a real Hyprland restart — see ensure-hyprland-shortcut.sh.)
bindd = $mods, $key, Toggle game overlay, exec, omarchy-shell game-overlay toggleVisibility
EOF

command -v hyprctl >/dev/null 2>&1 || exit 0

hyprctl reload >/dev/null 2>&1
sleep 0.2

result=$(hyprctl eval "o.bind(\"$lua_keys\", \"Toggle game overlay\", \"omarchy-shell game-overlay toggleVisibility\")" 2>&1)
if [ "$result" != "ok" ]; then
  notify-send "game-overlay plugin" "That shortcut couldn't be applied. Try a different key combination." 2>/dev/null || true
fi
