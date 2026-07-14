#!/usr/bin/env bash
# Clone/update shared agent skills and expose them to Claude, Codex, and Pi.
set -euo pipefail

skill_repo="${SKILL_REPO:-/Users/hmepas/projects/xlsx_skill}"
skill_dir="$HOME/.agents/skills/xlsx"

if [[ -d "$skill_dir/.git" ]]; then
  git -C "$skill_dir" pull --ff-only
else
  mkdir -p "$(dirname "$skill_dir")"
  git clone "$skill_repo" "$skill_dir"
fi

# A folded stow package would make ~/.claude point into this repository.
if [[ -L "$HOME/.claude" ]]; then
  echo "~/.claude is a symlink; stow claude with --no-folding first." >&2
  exit 1
fi

for target in \
  "$HOME/.claude/skills/xlsx" \
  "$HOME/.codex/skills/xlsx" \
  "$HOME/.pi/agent/skills/xlsx"
do
  mkdir -p "$(dirname "$target")"

  if [[ -e "$target" && ! -L "$target" ]]; then
    echo "Refusing to replace non-symlink: $target" >&2
    exit 1
  fi

  rm -f "$target"
  ln -s "$skill_dir" "$target"
done
