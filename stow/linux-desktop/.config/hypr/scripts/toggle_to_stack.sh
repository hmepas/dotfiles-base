#!/usr/bin/env bash

# Toggle all tiled windows on the active workspace between a tabbed group and
# the normal layout. Hyprland 0.56 uses Lua dispatch expressions over IPC.
set -uo pipefail

clients_json=$(hyprctl clients -j) || exit 1
active_ws=$(hyprctl activeworkspace -j | jq -r '.id') || exit 1
active_address=$(hyprctl activewindow -j | jq -r '.address // empty')

ws_windows=$(jq -c --argjson workspace "$active_ws" '
    [.[] | select(.workspace.id == $workspace and .floating == false)]
' <<<"$clients_json")
mapfile -t addresses < <(jq -r '.[].address' <<<"$ws_windows")

lua_dispatch() {
    hyprctl dispatch "$1" >/dev/null 2>&1
}

focus_window() {
    local address=$1
    lua_dispatch "hl.dsp.focus({ window = \"address:$address\" })"
}

# If at least one tiled window is grouped, dismantle all groups represented on
# this workspace. Only windows that were group members receive the dispatcher.
if jq -e 'any(.[]; (.grouped | length) > 0)' <<<"$ws_windows" >/dev/null; then
    while IFS= read -r address; do
        lua_dispatch "hl.dsp.window.move({ out_of_group = true, window = \"address:$address\" })"
    done < <(jq -r '.[] | select((.grouped | length) > 0) | .address' <<<"$ws_windows")

    [ -z "$active_address" ] || focus_window "$active_address"
    exit 0
fi

# A group needs at least two tiled windows.
((${#addresses[@]} >= 2)) || exit 0

# Prefer the currently focused tiled window as the anchor, otherwise use the
# first tiled window reported by Hyprland.
if jq -e --arg address "$active_address" 'any(.[]; .address == $address)' <<<"$ws_windows" >/dev/null; then
    anchor=$active_address
else
    anchor=${addresses[0]}
fi

lua_dispatch "hl.dsp.group.toggle({ window = \"address:$anchor\" })" || exit 1

for address in "${addresses[@]}"; do
    [ "$address" = "$anchor" ] && continue

    # Depending on the layout tree, the anchor group can be in any direction.
    # Stop immediately after the window successfully joins it instead of issuing
    # all four move commands unconditionally.
    for direction in l r u d; do
        lua_dispatch "hl.dsp.window.move({ into_group = \"$direction\", window = \"address:$address\" })" || true
        if hyprctl clients -j | jq -e --arg address "$address" '
            .[] | select(.address == $address) | (.grouped | length) > 0
        ' >/dev/null; then
            break
        fi
    done
done

focus_window "$anchor"
