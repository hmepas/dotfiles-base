# --- FZF ---
# Assumes fzf installed via brew or similar, providing ~/.fzf.zsh
if [[ -f ~/.fzf.zsh ]]; then
  source ~/.fzf.zsh

  # Set FZF options from bashrc
  # Requires 'ag' (the_silver_searcher). Consider 'rg' (ripgrep) as a faster alternative.
  if command -v ag &> /dev/null; then
    export FZF_DEFAULT_COMMAND='ag --hidden --ignore .git -g ""' # Find files with ag including hidden
  elif command -v rg &> /dev/null; then
     export FZF_DEFAULT_COMMAND='rg --files --hidden --glob "!.git"' # Find files with rg including hidden
  fi

  export FZF_TMUX=1
  export FZF_TMUX_HEIGHT="40%"
  export FZF_CTRL_T_OPTS="--select-1 --exit-0" # Options for Ctrl+T file finder

  # Use ag or rg for Ctrl+T path completion if available
  if command -v ag &> /dev/null; then
    _fzf_compgen_path() {
      ag --hidden --ignore .git -g "" "$1"
    }
  elif command -v rg &> /dev/null; then
    _fzf_compgen_path() {
      rg --files --hidden --glob "!.git" "$1"
    }
  fi

  # Solarized Dark color scheme for fzf
  _gen_fzf_default_opts() {
    local base03="234"; local base02="235"; local base01="240"; local base00="241"
    local base0="244"; local base1="245"; local base2="254"; local base3="230"
    local yellow="136"; local orange="166"; local red="160"; local magenta="125"
    local violet="61"; local blue="33"; local cyan="37"; local green="64"
    # Solarized Dark color scheme for fzf
    export FZF_DEFAULT_OPTS="\
    --color=bg+:$base02,bg:$base03,spinner:$cyan,hl:$blue\
    --color=fg+:$base1,fg:$base0,hl+:$base3\
    --color=info:$yellow,prompt:$yellow,pointer:$base3,marker:$base3,header:$blue\
    --height=${FZF_TMUX_HEIGHT:-40%} --reverse" # Add height and reverse layout
  }
  _gen_fzf_default_opts
fi


