#!/usr/bin/env bash
# Make IINA the default app for common video file extensions on a personal Mac.
set -euo pipefail

if [[ "$(uname -s)" != Darwin ]]; then
  echo "This script requires macOS." >&2
  exit 1
fi

if ! command -v duti >/dev/null 2>&1; then
  echo "Install duti and IINA first: brew bundle --file=packages/Brewfile.personal" >&2
  exit 1
fi

for ext in mkv mp4 m4v mov avi webm mpg mpeg ts m2ts mts wmv flv ogv; do
  duti -s com.colliderli.iina ".$ext" all
done
