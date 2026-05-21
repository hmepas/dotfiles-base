#!/usr/bin/env bash
set -euo pipefail

# зависимости
command -v yabai >/dev/null 2>&1 || { echo "yabai not found in PATH" >&2; exit 1; }
command -v jq    >/dev/null 2>&1 || { echo "jq not found in PATH" >&2; exit 1; }
command -v osascript >/dev/null 2>&1 || { echo "osascript not found" >&2; exit 1; }

# helper: получить список id окон iTerm2
get_ids() {
  yabai -m query --windows \
    | jq -c 'map(select(.subrole=="AXStandardWindow" and .app=="iTerm2")) | map(.id)'
}

before_ids="$(get_ids)"

if [ "$before_ids" = "[]" ]; then
    open -a /Applications/iTerm.app/Contents/MacOS/iTerm2
    sleep 0.5
else # otherwise open a new window
    /usr/bin/osascript <<'APPLESCRIPT'
    tell application "iTerm2"
      create window with default profile
      delay 0.1
    end tell
APPLESCRIPT
fi

# 2) найти id нового окна (diff по спискам; fallback — фокусное/макс id)
new_win_id=""
for _ in {1..15}; do
  after_ids="$(get_ids)"
  # diff: элементы из after, которых не было в before
  new_win_id="$(jq -r --argjson a "$before_ids" --argjson b "$after_ids" -n '$b - $a | last?')"
  [[ -n "${new_win_id:-}" && "$new_win_id" != "null" ]] && break
  sleep 0.07
done

if [[ -z "${new_win_id:-}" || "$new_win_id" == "null" ]]; then
  echo "could not determine new iTerm2 window id" >&2
  exit 1
fi

yabai -m window "$new_win_id" --space mouse --focus "$new_win_id"
