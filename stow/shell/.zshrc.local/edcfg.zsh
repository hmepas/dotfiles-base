# edcfg / viewcfg — fzf-driven config finder across ~/.config and common dotfiles.
#
# Replaces ad-hoc aliases like `alias edskhd='$EDITOR ~/.config/skhd/skhdrc'` —
# instead of memorising a path per tool, fuzzy-search them all.
#
# Usage:
#   edcfg              # fuzzy-pick any config file, open in $EDITOR (nvim by default)
#   viewcfg            # same picker, read-only view via bat with paging
#
# Keybinds inside fzf:
#   <typing>           narrow by substring (e.g. "tmux", "starship", "ghost")
#   <ctrl-j/k>         move down/up
#   <enter>            open picked file
#   <esc>              cancel
#
# Examples:
#   edcfg              → type "tmux"  → opens ~/.tmux.conf
#   edcfg              → type "ghost" → opens ~/.config/ghostty/config
#   edcfg              → type "star"  → opens ~/.config/starship.toml
#   viewcfg            → type "zshrc" → opens ~/.zshrc in bat
#
# Sources scanned (deduped):
#   ~/.config/**                                 (recursive, hidden files included)
#   top-level dotfiles: .zshrc, .zshenv, .zprofile, .bashrc, .profile,
#                       .tmux.conf, .gitconfig, .yabairc, .simplebarrc, .wezterm.lua
#   ~/.zshrc.local/**, ~/.bashrc_local/**
#
# Dependencies: fd, fzf, bat (all installed via Brewfile).
# EDITOR falls back to nvim if not set.

edcfg() {
  local f
  f=$(
    {
      fd -HI --type f . ~/.config 2>/dev/null
      print -l ~/.zshrc ~/.zshenv ~/.zprofile ~/.bashrc ~/.profile \
               ~/.tmux.conf ~/.gitconfig ~/.yabairc ~/.simplebarrc ~/.wezterm.lua
      fd -HI --type f . ~/.zshrc.local ~/.bashrc_local 2>/dev/null
    } | awk '!seen[$0]++' \
      | fzf --preview 'bat --color=always --style=plain --line-range=:200 {}' \
            --preview-window=right:60% --height=90%
  )
  [[ -n $f ]] && ${EDITOR:-nvim} "$f"
}

viewcfg() {
  local f
  f=$(
    {
      fd -HI --type f . ~/.config 2>/dev/null
      print -l ~/.zshrc ~/.zshenv ~/.zprofile ~/.bashrc ~/.profile \
               ~/.tmux.conf ~/.gitconfig ~/.yabairc ~/.simplebarrc ~/.wezterm.lua
      fd -HI --type f . ~/.zshrc.local ~/.bashrc_local 2>/dev/null
    } | awk '!seen[$0]++' \
      | fzf --preview 'bat --color=always --style=plain --line-range=:200 {}' \
            --preview-window=right:60% --height=90%
  )
  [[ -n $f ]] && bat --paging=always "$f"
}
