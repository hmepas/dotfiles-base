#!/bin/bash

# To return control for windows to Yabai

# no more desktop focus on click
defaults write com.apple.WindowManager EnableStandardClickToShowDesktop -bool false

# no nataive tiling
defaults write com.apple.WindowManager EnableTiling -bool false

# no snapping to grid
defaults write com.apple.WindowManager TilingMargins -bool false

# Make interfacde more flat and faster
defaults write -g com.apple.SwiftUI.DisableSolarium -bool YES
