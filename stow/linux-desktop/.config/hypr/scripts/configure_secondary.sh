#!/bin/sh
# NVIDIA can assign a different DP-* name after reboot. Find the Dell by serial
# and apply its monitor-specific black wallpaper once hyprpaper IPC is ready.
monitor="$(hyprctl monitors -j | python -c '
import json, sys
for m in json.load(sys.stdin):
    if m.get("serial") == "9TG463BF2MUL":
        print(m["name"])
        break
')"

[ -n "$monitor" ] || exit 0

attempt=0
while [ "$attempt" -lt 20 ]; do
    hyprctl hyprpaper wallpaper "$monitor, $HOME/.config/hypr/black.png, fill" >/dev/null 2>&1 && exit 0
    attempt=$((attempt + 1))
    sleep 0.25
done
