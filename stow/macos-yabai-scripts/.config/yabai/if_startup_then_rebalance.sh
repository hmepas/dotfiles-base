#!/bin/bash

# labeled spaces count
SPACES_CNT=`yabai -m query --spaces | jq -r '.[] | select(.label != "") | .index' | wc -l`

if [[ "$SPACES_CNT" -lt 8 ]]; then
    # probably we just started or something really went wrong and it's time to rebalance
    ~/.config/yabai/rebalance_spaces.py
    ~/.config/yabai/add_windows_arrange_rules.sh
fi
