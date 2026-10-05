#!/bin/bash
# Follows the most-recently-modified MangoHud log CSV in $DIR, switching to a
# newer file automatically if a different game starts logging. Lines are
# streamed to stdout so the Quickshell plugin's Process/SplitParser can read
# them live.
DIR="${XDG_CACHE_HOME:-$HOME/.cache}/mangohud"
mkdir -p "$DIR"

current=""
tailpid=""

cleanup() {
  [ -n "$tailpid" ] && kill "$tailpid" 2>/dev/null
  exit 0
}
trap cleanup TERM INT

while true; do
  newest=$(ls -t "$DIR"/*.csv 2>/dev/null | head -1)
  if [ -n "$newest" ] && [ "$newest" != "$current" ]; then
    [ -n "$tailpid" ] && kill "$tailpid" 2>/dev/null
    current="$newest"
    tail -F -n0 "$current" &
    tailpid=$!
  fi
  sleep 2
done
