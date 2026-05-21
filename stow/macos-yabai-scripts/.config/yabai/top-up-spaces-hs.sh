#!/bin/bash
# Top up Mission Control spaces to 16 via Hammerspoon.
#
# Pair of top-up-spaces.sh: that one uses `yabai -m space --create`, which
# needs the scripting-addition and therefore only works on a SIP-disabled
# host. This variant calls `hs.spaces.addSpaceToScreen()` over the
# Hammerspoon CLI (`hs`), which uses private APIs but does NOT require
# yabai's SA — so it runs on the work mac.
#
# Wired from stow/macos-work/.yabairc.

set -e

TARGET=16
CNT=$(yabai -m query --spaces | jq 'length')
echo "There are $CNT spaces"

if (( CNT >= TARGET )); then
    echo "no need to create any"
    exit 0
fi

NEEDED=$(( TARGET - CNT ))
echo "creating $NEEDED spaces via Hammerspoon"

# Single hs invocation: loop inside Lua to avoid per-iteration IPC + Mission
# Control toggles. closeMissionControl=true only on the last iteration.
hs -c "
local n = $NEEDED
for i = 1, n do
  hs.spaces.addSpaceToScreen(nil, i == n)
end
return 'done'
" >/dev/null

echo "topped up to $TARGET"
