#!/usr/bin/env bash
# Stow personal skills; Claude needs links, Pi and Codex discover ~/.agents/skills.
set -euo pipefail
repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

# Never write through folded application directories into a stow package.
for dir in "$HOME/.agents" "$HOME/.agents/skills" "$HOME/.claude" "$HOME/.claude/skills"; do
  if [[ -L "$dir" ]]; then
    echo "Refusing to write through directory symlink: $dir" >&2
    exit 1
  fi
done
for skill in xlsx zk; do
  target="$HOME/.claude/skills/$skill"
  if [[ -e "$target" && ! -L "$target" ]]; then
    echo "Refusing to replace non-symlink: $target" >&2
    exit 1
  fi
done

stow --no-folding -t "$HOME" -d "$repo_dir/stow" agent-skills
mkdir -p "$HOME/.claude/skills"
for skill in xlsx zk; do
  ln -sfn "../../.agents/skills/$skill" "$HOME/.claude/skills/$skill"
done
