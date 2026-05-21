# yabai helper scripts

Stowed to `~/.config/yabai/` on any yabai-managed mac (personal + work).
Kept out of `macos-common` because the scripts are useless on macs without
yabai; kept out of `macos-personal` / `macos-work` to avoid duplication.

## What goes here

Scripts referenced from `.yabairc` and Hammerspoon `modules/yabai.lua`:

- `if_startup_then_rebalance.sh`
- `rearrange_windows.sh`
- `add_windows_arrange_rules.sh`
- `on_display_layout_change.sh`
- `simple-bar-conf.sh`
- `cycle-space-windows.sh`
- `center_unmanaged_window.sh`
- `smart-resize.sh`
- `finder-toggle.sh`
- `new-iterm-window.sh`

## SA caveat

If a script calls `space --create/--destroy/--move/--swap/--switch`,
`display --space`, `--toggle sticky/pip/shadow`, `--sub-layer`,
`--opacity`, or `--scratchpad`, those calls will silently fail on the
work mac (SIP enabled, no SA). Audit before committing.

Safe without SA: `space --focus/--layout/--rotate/--balance/--equalize`,
`window --focus/--warp/--swap/--move/--resize/--ratio/--grid/--space/--display`,
`query`, `rule --add` (without `sub-layer`).
