# --- Key Bindings ---
# Ensure Zsh is in emacs mode for standard keybindings
bindkey -e

# Standard macOS bindings for Home/End keys
bindkey '\e[1~' beginning-of-line  # Home
bindkey '\e[4~' end-of-line      # End
bindkey '\e[H'  beginning-of-line  # Home (alternative)
bindkey '\e[F'  end-of-line      # End (alternative)

# Word-wise navigation (Option/Alt + Arrows)
bindkey '\e\e[D' backward-word   # Works in some terminals
bindkey '\e\e[C' forward-word    # Works in some terminals
bindkey '\eb'    backward-word   # Standard Meta+b
bindkey '\ef'    forward-word    # Standard Meta+f

# FIX for VS Code / Cursor Terminal
# This handles the case where the terminal sends literal '^' + Letter
bindkey '^A' beginning-of-line
bindkey '^E' end-of-line
bindkey '^K' kill-line
bindkey '^U' kill-whole-line
bindkey '^P' up-line-or-history
bindkey '^N' down-line-or-history
bindkey '^F' forward-char
bindkey '^B' backward-char
bindkey '^D' delete-char-or-list

# Cmd+Arrow Key fix (requires terminal profile mapping)
# VS Code often sends these codes for Cmd+Left/Right
bindkey '^[d' backward-word      # Common for Cmd+Left
bindkey '^[c' forward-word      # Common for Cmd+Right

# opt+-> opt+<- behaviour
bindkey "^[[1;3C" forward-word
bindkey "^[[1;3D" backward-word
