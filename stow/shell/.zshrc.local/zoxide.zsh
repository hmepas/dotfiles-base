# ~/.zshrc.local/zoxide.zsh
# Zoxide (smart directory jumping) setup

if command -v zoxide &> /dev/null; then
  eval "$(zoxide init zsh)"
fi 