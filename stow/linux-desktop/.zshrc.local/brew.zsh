# Linuxbrew: leftovers not packaged for Arch (see packages/Brewfile.linux-desktop)
if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv zsh)"
fi
