# yabai helper scripts

Stowed to `~/.config/yabai/` on any yabai-managed mac (personal + work).
Kept out of `macos-common` because the scripts are useless on macs without
yabai; kept out of `macos-personal` / `macos-work` to avoid duplication.

## What goes here

Scripts referenced from `.yabairc` and Hammerspoon `modules/yabai.lua`:

- `if_startup_then_rebalance.sh` — calls `rebalance_spaces.py`
- `rearrange_windows.sh`
- `add_windows_arrange_rules.sh`
- `on_display_layout_change.sh` — calls `fix_spaces.py`
- `simple-bar-conf.sh`
- `cycle-space-windows.sh`
- `center_unmanaged_window.sh`
- `smart-resize.sh`
- `finder-toggle.sh`
- `new-iterm-window.sh`
- `rebalance_spaces.py` — internal helper, called from `if_startup_then_rebalance.sh`
- `fix_spaces.py` — internal helper, called from `on_display_layout_change.sh`

## Not stowed (3rd party / host-local)

- `ubersicht-widgets/simple-bar/` — upstream Übersicht widget cloned to
  `~/.config/yabai/ubersicht-widgets/simple-bar/`. Hammerspoon
  `config.lua` points `YABAI_MODE_SCRIPT` at
  `ubersicht-widgets/simple-bar/lib/scripts/yabai-set-mode-server.sh`,
  so the widget repo must exist on a yabai host for the mode indicator
  to update. Install separately, don't commit.
- `~/bin/yb/yabai_watcher` — referenced from `.yabairc` (personal) but
  lives outside this stow package. Add it where appropriate if you
  want the loop on a fresh machine.

## SA caveat

If a script calls `space --create/--destroy/--move/--swap/--switch`,
`display --space`, `--toggle sticky/pip/shadow`, `--sub-layer`,
`--opacity`, or `--scratchpad`, those calls will silently fail on the
work mac (SIP enabled, no SA). Audit before committing.

Safe without SA: `space --focus/--layout/--rotate/--balance/--equalize`,
`window --focus/--warp/--swap/--move/--resize/--ratio/--grid/--space/--display`,
`query`, `rule --add` (without `sub-layer`).
