# --- Starship Prompt ---
# Must be last to correctly capture previous command status
if command -v starship &> /dev/null; then
  eval "$(starship init zsh)"
fi


