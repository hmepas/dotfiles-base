# ~/.zshrc
# Main Zsh configuration file

# --- Environment Variables ---
export EDITOR=vim
export LANG=en_US.UTF-8 # Good practice to set locale

# Determine OS
case "$(uname -s)" in
    Linux*)     HOSTOS=Linux;;
    Darwin*)    HOSTOS=Mac;;
    CYGWIN*)    HOSTOS=Cygwin;;
    MINGW*)     HOSTOS=MinGw;;
    *)          HOSTOS="UNKNOWN:$(uname -s)"
esac
export HOSTOS

# --- PATH Setup ---
# Initialize Homebrew (adds brew paths to PATH, MANPATH, INFOPATH)
if [ -x "/opt/homebrew/bin/brew" ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Add other paths (use typeset -U to ensure uniqueness)
typeset -U path # Ensure PATH array is unique
path=(
  $HOME/.local/bin(N-/) # Pipx, N means nullglob (no error if doesn't exist), -/ means only directories
  $HOME/bin(N-/)        # User bin
  $path                 # Existing path (including brew)
)
export PATH

# --- History ---
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=200000 # Match Bash HISTFILESIZE
setopt BANG_HIST                 # Treat '!' specially
setopt EXTENDED_HISTORY          # Write timestamps to history

# for separate history for each terminal
unsetopt inc_append_history        # Append commands to history file immediately
unsetopt inc_append_history_time
unsetopt share_history             # do not share history between different instances of the shell
# Write history on exit not immediately
setopt append_history

setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate entries first when trimming history
setopt HIST_IGNORE_DUPS          # Don't record an entry that was just recorded
setopt HIST_IGNORE_ALL_DUPS    # Delete old recorded entry if new entry is a duplicate
setopt HIST_FIND_NO_DUPS       # Don't display duplicate entries when searching
setopt HIST_IGNORE_SPACE         # Don't record commands starting with space
setopt HIST_SAVE_NO_DUPS       # Don't write duplicate entries in the history file
setopt HIST_VERIFY               # Don't execute command immediately upon history expansion

# --- Aliases ---
alias ll='ls -alF'
alias la='ls -A'

alias python=python3

# OS-specific aliases
if [[ "$HOSTOS" = "Mac" ]]; then
  alias ls='ls -G' # Enable color for ls on macOS
else
  # Check for dircolors on Linux for LS_COLORS
  if command -v dircolors &> /dev/null; then
      eval "$(dircolors -b)"
      alias ls='ls --color=auto -h'
  else
      alias ls='ls -F' # Fallback if no dircolors
  fi
fi


# --- Key Bindings ---
# Cmd line editing in $EDITOR via CTRL-X-E
autoload edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line

# --- Key Bindings (macOS) ---
if [[ "$HOSTOS" = "Mac" ]]; then
  # Standard macOS bindings (might be default in iTerm/Terminal)
  bindkey '\e[1~' beginning-of-line  # Home
  bindkey '\e[4~' end-of-line      # End
  bindkey '\e\e[D' backward-word    # Option/Alt + Left
  bindkey '\e\e[C' forward-word     # Option/Alt + Right
  # Silence Zsh deprecation warning on macOS (if using system Zsh)
  # export BASH_SILENCE_DEPRECATION_WARNING=1 # Zsh might show this too, uncomment if needed
fi

# --- Completion System ---
# Needs to be initialized after fpath is set up

# Add custom completion directory to fpath
fpath=($HOME/.zsh/completion $fpath)

# Initialize completion system
autoload -U compinit && compinit -u # Use -u to avoid security check on first run

# --- GPG Agent ---
# Start gpg-agent if not running
if command -v gpg-agent &> /dev/null; then
  # Check if agent info file exists and process is running
  if test -f $HOME/.gpg-agent-info && \
     kill -0 $(cut -d: -f 2 $HOME/.gpg-agent-info) 2>/dev/null; then
      export GPG_AGENT_INFO=$(cat $HOME/.gpg-agent-info)
  # Check if gnupg directory exists (needed to start agent)
  elif [ -d ~/.gnupg ]; then
      # Start the agent with SSH support
      eval $(gpg-agent --daemon --enable-ssh-support --default-cache-ttl 86400 --max-cache-ttl 700000)
      echo $GPG_AGENT_INFO > $HOME/.gpg-agent-info
  fi
  export GPG_TTY=$(tty)
fi

# --- Tmux Auto-start on SSH ---
# Check if not already in tmux and connected via SSH
if [[ -z "$TMUX" && -n "$SSH_TTY" ]]; then
  # Try to attach to the first unattached session
  FIRST_UNATTACHED=$(tmux list-sessions -F '#{session_name}:#{?session_attached,attached,unattached}' 2>/dev/null | grep ':unattached$' | head -n 1 | cut -d: -f1)
  if [[ -n "$FIRST_UNATTACHED" ]]; then
    tmux attach-session -t "$FIRST_UNATTACHED" && exit 0
  else
    # No unattached sessions, create a new one named by date
    DATE=$(date +"%a_%H.%M") # Adjusted date format slightly
    tmux new-session -s "$DATE" && exit 0
  fi
  echo "tmux failed to start" >&2
fi

# --- Load Local/Machine-Specific Config ---
# Source all .zsh files from ~/.zshrc.local if the directory exists
ZSHRC_LOCAL_DIR="$HOME/.zshrc.local"
if [ -d "$ZSHRC_LOCAL_DIR" ]; then
  for config_file ("$ZSHRC_LOCAL_DIR"/*.zsh); do
    if [ -r "$config_file" ]; then
      source "$config_file"
    fi
  done
  unset config_file # Clean up loop variable
fi
unset ZSHRC_LOCAL_DIR # Removed unset, might be useful for debugging

# --- Clean up ---
unset HOSTOS DATE FIRST_UNATTACHED _gen_fzf_default_opts # Clean up temporary variables/functions 


# Added by LM Studio CLI (lms)
export PATH="$PATH:$HOME/.lmstudio/bin"
# End of LM Studio CLI section

alias vim=nvim
