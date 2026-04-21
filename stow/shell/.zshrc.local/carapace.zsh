# ~/.zshrc.local/carapace.zsh
# Carapace completion setup

if command -v carapace &> /dev/null; then
  export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense' # optional
  # Ensure compinit is loaded before sourcing carapace
  if (( $+functions[compinit] )); then
    source <(carapace _carapace zsh)
  fi
fi 