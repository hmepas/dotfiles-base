# --- AI session count in prompt ---
# Exposes $RESUME_SESSIONS (per-project AI session count from `resume --count`)
# for the starship env_var module. Never blocks the prompt: precmd only reads a
# cache file; the refresh runs disowned in the background at most once per TTL.

if command -v resume &> /dev/null; then
  zmodload zsh/datetime

  typeset -g _resume_count_dir="${XDG_CACHE_HOME:-$HOME/.cache}/resume-count"
  typeset -gA _resume_count_started
  : ${RESUME_COUNT_TTL:=60}

  _resume_count_refresh() {
    local cache="$1"
    (
      local n
      n="$(command resume --count 2>/dev/null)"
      [[ "$n" == <-> ]] || exit 0
      mkdir -p -- "${cache:h}"
      print -r -- "$n" >| "$cache.$$" && mv -f -- "$cache.$$" "$cache"
    ) &> /dev/null &!
  }

  _resume_count_precmd() {
    local cache="$_resume_count_dir/${PWD//\//%}"
    local n=""
    [[ -r "$cache" ]] && n="$(<"$cache")"
    if [[ "$n" == <-> && "$n" != 0 ]]; then
      export RESUME_SESSIONS="$n"
    else
      unset RESUME_SESSIONS
    fi
    if (( EPOCHSECONDS - ${_resume_count_started[$PWD]:-0} >= RESUME_COUNT_TTL )); then
      _resume_count_started[$PWD]=$EPOCHSECONDS
      _resume_count_refresh "$cache"
    fi
  }

  autoload -Uz add-zsh-hook
  add-zsh-hook precmd _resume_count_precmd
fi
