#!/usr/bin/env bash
# Make mpv the default app for every video/* MIME type it declares (Linux desktop).
# Linux counterpart of set-iina-defaults.sh. Writes ~/.config/mimeapps.list.
set -euo pipefail

desktop=/usr/share/applications/mpv.desktop
if [[ ! -f $desktop ]] || ! command -v xdg-mime >/dev/null 2>&1; then
  echo "Install mpv and xdg-utils first (packages/arch/pkglist.desktop.txt)" >&2
  exit 1
fi

grep '^MimeType=' "$desktop" | cut -d= -f2 | tr ';' '\n' | grep '^video/' |
  xargs xdg-mime default mpv.desktop
