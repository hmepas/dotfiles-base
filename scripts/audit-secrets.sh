#!/usr/bin/env bash
# audit-secrets.sh — runs gitleaks on the repo's working tree.
#
# Usage:
#   ./scripts/audit-secrets.sh              # working tree, without git history
#   ./scripts/audit-secrets.sh --staged     # staged files only (for pre-commit)
#   ./scripts/audit-secrets.sh --log-opts=HEAD~10..HEAD   # git history range

set -euo pipefail

cd "$(dirname "$0")/.."

if ! command -v gitleaks >/dev/null 2>&1; then
  echo >&2 "gitleaks is not installed. Install it: brew install gitleaks (or pacman -S gitleaks)"
  exit 1
fi

if [[ $# -eq 0 ]]; then
  exec gitleaks detect --source . --no-git --verbose
fi

exec gitleaks detect --source . --verbose "$@"
