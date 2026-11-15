#!/usr/bin/env zsh
#
# paru -S fnm-bin
# fnm install --latest
# mkdir -p ~/.npm-global
# npm config set prefix '~/.npm-global'

if command -v fnm &> /dev/null; then
  export PATH=$HOME/.npm-global/bin:$PATH
  eval "$(fnm env --use-on-cd)"
fi
