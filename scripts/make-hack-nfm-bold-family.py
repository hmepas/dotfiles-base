#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = ["fonttools>=4.50"]
# ///
"""Clone the Hack Nerd Font Mono Bold face into its own family "Hack NFM Bold".

Why: Ghostty on macOS resolves fonts by family name only, so
`font-codepoint-map = ...=Hack Nerd Font Mono Bold` silently falls back to the
regular face. iTerm2 could render Non-ASCII glyphs with a separate (bold) font,
which made Cyrillic visibly different from Latin (no more latin "c" vs cyrillic
"с" confusion). Having the bold face as a standalone family restores that:

    font-codepoint-map = U+0400-U+04FF=Hack NFM Bold

The glyph outlines are untouched; only the name table and style flags change,
so the new family reports itself as a "Regular" face and Ghostty picks it for
the regular style.

Requires: font-hack-nerd-font cask (packages/Brewfile) and uv.
Output: ~/Library/Fonts/HackNFMBold-Regular.ttf
"""
import sys
from pathlib import Path

from fontTools.ttLib import TTFont

SRC = Path.home() / "Library/Fonts/HackNerdFontMono-Bold.ttf"
DST = Path.home() / "Library/Fonts/HackNFMBold-Regular.ttf"
FAMILY = "Hack NFM Bold"
STYLE = "Regular"
PS_NAME = "HackNFMBold-Regular"

if not SRC.exists():
    sys.exit(f"{SRC} not found; install it: brew bundle --file=packages/Brewfile")

font = TTFont(SRC)

names = {
    1: FAMILY,
    2: STYLE,
    3: f"{PS_NAME};{FAMILY}",
    4: FAMILY,
    6: PS_NAME,
    16: FAMILY,
    17: STYLE,
}
name_table = font["name"]
for rec in name_table.names:
    if rec.nameID in names:
        rec.string = names[rec.nameID]

# Report as a regular-weight face so style matching does not skip it.
os2 = font["OS/2"]
os2.usWeightClass = 400
os2.fsSelection = (os2.fsSelection & ~(1 << 5)) | (1 << 6)  # clear BOLD, set REGULAR
font["head"].macStyle &= ~1  # clear bold bit

font.save(DST)
print(f"wrote {DST}")
print(f"ghostty: font-codepoint-map = U+0400-U+04FF={FAMILY}")
