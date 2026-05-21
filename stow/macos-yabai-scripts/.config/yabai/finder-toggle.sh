#!/usr/bin/env zsh
# Focus Finder window on current space; if none, create one here.

set -euo pipefail

jqbin=$(command -v jq || true)
[ -z "$jqbin" ] && { echo "jq not found. brew install jq"; exit 1; }

# Текущий спейс
CUR_SPACE=$(yabai -m query --spaces --space | jq -r '.index')

# Ищем окно Finder на текущем спейсе
find_finder_on_space() {
  yabai -m query --windows --space | jq -r '.[] | select(.app=="Finder") | .id' | sort | tail -n1
}

# Ищем последнее окно Finder везде
find_finder_windows() {
  yabai -m query --windows | jq -r '.[] | select(.app=="Finder") | .id' | sort | tail -n1
}

WIN_ID=$(find_finder_on_space || true)
if [[ -n "${WIN_ID:-}" ]]; then
  #echo "found on current space $CUR_SPACE - space; WIN_ID: $WIN_ID";
  yabai -m window --focus "$WIN_ID"
  exit 0
fi

# Проверяем если нет окон, то создаем одно
osascript >/dev/null <<'APPLESCRIPT'
tell application "Finder"
  if (count of windows) = 0 then
    make new Finder window to (path to home folder)
  end if
end tell
APPLESCRIPT
sleep 0.05 # otherwise it's not popped before the check in next block

# Переключаемся на вновь созданное или если окно уже было на одно из существующих
WIN_ID=$(find_finder_windows || true)
if [[ -n "${WIN_ID:-}" ]]; then
  #echo "found on other space or newly created moving to current $CUR_SPACE - space and focusing. WIN_ID: $WIN_ID";
  yabai -m window "$WIN_ID" --space $CUR_SPACE --focus
  exit 0
fi

