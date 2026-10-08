#!/bin/bash
# Makes sure ~/.config/MangoHud/MangoHud.conf has what this plugin needs:
# MangoHud running invisibly (alpha=0) purely as a background stats engine,
# continuously logging fps/cpu/gpu numbers to a CSV this plugin tails.
#
# Never overwrites a setting the user already has to a different value —
# only adds what's missing, and notifies instead of clobbering a conflict,
# since someone who already uses MangoHud's own on-screen HUD wouldn't want
# it silently hidden.

set -u

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/mangohud"
CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/MangoHud"
CONF="$CONF_DIR/MangoHud.conf"
mkdir -p "$CACHE_DIR" "$CONF_DIR"

# Flag-only options: just need to exist anywhere in the file.
FLAGS=(cpu_stats cpu_temp gpu_stats gpu_temp fps)
# key=value options: need a line starting with "key=" present.
declare -A KV=(
  [alpha]="0"
  [background_alpha]="0"
  [autostart_log]="1"
  [log_interval]="500"
  [output_folder]="$CACHE_DIR"
)

if [ ! -f "$CONF" ]; then
  {
    echo "### MangoHud runs fully invisible here (alpha=0) — it exists purely as"
    echo "### a background stats engine + logger for the Pill overlay Quickshell"
    echo "### plugin, which does the actual visible rendering."
    echo
    for f in "${FLAGS[@]}"; do echo "$f"; done
    echo
    for k in "${!KV[@]}"; do echo "$k=${KV[$k]}"; done
  } > "$CONF"
  exit 0
fi

missing_flags=()
for f in "${FLAGS[@]}"; do
  grep -qxF "$f" "$CONF" || missing_flags+=("$f")
done

missing_kv=()
conflicting_kv=()
for k in "${!KV[@]}"; do
  existing=$(grep -m1 "^${k}=" "$CONF" || true)
  if [ -z "$existing" ]; then
    missing_kv+=("$k=${KV[$k]}")
  elif [ "$existing" != "$k=${KV[$k]}" ]; then
    conflicting_kv+=("$existing (Pill overlay needs $k=${KV[$k]})")
  fi
done

if [ ${#missing_flags[@]} -gt 0 ] || [ ${#missing_kv[@]} -gt 0 ]; then
  {
    echo
    echo "### Added by the Pill overlay plugin"
    for f in "${missing_flags[@]}"; do echo "$f"; done
    for kv in "${missing_kv[@]}"; do echo "$kv"; done
  } >> "$CONF"
fi

if [ ${#conflicting_kv[@]} -gt 0 ]; then
  msg="Your MangoHud.conf has settings the Pill overlay plugin needs changed, but won't overwrite automatically:"
  for c in "${conflicting_kv[@]}"; do
    msg="$msg
$c"
  done
  msg="$msg
Edit $CONF to resolve."
  notify-send "Pill overlay plugin" "$msg" 2>/dev/null || true
fi
