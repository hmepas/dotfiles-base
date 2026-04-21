# ~/.zshrc.local/yc.zsh
# The next line updates PATH for CLI.
if [ -f "$HOME/yandex-cloud/path.bash.inc" ]; then source "$HOME/yandex-cloud/path.bash.inc"; fi

# The next line enables shell command completion for yc.
if [ -f "$HOME/yandex-cloud/completion.zsh.inc" ]; then source "$HOME/yandex-cloud/completion.zsh.inc"; fi


# Yandex Cloud CLI completion setup
# Ensure completion directory exists (safe to run multiple times)
mkdir -p $HOME/.zsh/completion

# Generate completion script if yc command exists and compinit has run
if command -v yc &> /dev/null && (( $+functions[compinit] )); then
  # Check if completion file already exists or generate it
  if [[ ! -f "$HOME/.zsh/completion/_yc" ]]; then
    yc completion zsh > "$HOME/.zsh/completion/_yc" 2>/dev/null || true
  fi
fi 
