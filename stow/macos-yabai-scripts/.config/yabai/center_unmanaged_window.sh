#!/bin/bash

# Dependency: jq (brew install jq)
# Purpose: Centers the currently focused window on the current display without resizing it.

# 1. Get current display frame (x, y, width, height)
# We accept the float values from yabai and floor them immediately for bash arithmetic
read -r d_x d_y d_w d_h <<< $(yabai -m query --displays --display | jq -r '.frame | "\(.x|floor) \(.y|floor) \(.w|floor) \(.h|floor)"')

echo "Display dimensions: $d_w x $d_h, with x=$d_x, y=$d_y"

# 2. Get focused window dimensions (width, height)
read -r w_w w_h <<< $(yabai -m query --windows --window | jq -r '.frame | "\(.w|floor) \(.h|floor)"')
echo "Window dimensions: $w_w x $w_h"

# 3. Calculate new top-left coordinates
# formula: display_start + (display_dim - window_dim) / 2
x_pos=$(( d_x + (d_w - w_w) / 2 ))
y_pos=$(( d_y + (d_h - w_h) / 2 ))
echo "New top-left coordinates: $x_pos x $y_pos"

# 4. Move window to absolute position
yabai -m window --move abs:$x_pos:$y_pos
