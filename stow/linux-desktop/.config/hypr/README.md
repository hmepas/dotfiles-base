# Local Hyprland context

- Main config: `hyprland.lua` (Hyprland 0.56+). The old `hyprland.conf` is kept as a fallback.
- The first switch from `hyprland.conf` to `hyprland.lua` needs a session restart: a plain `hyprctl reload` does not change the type of the already created config manager.
- Main monitor: `HDMI-A-1`, `3840x2160@160`, scale `1.25`, position `1080x96`.
- Secondary Dell (serial `9TG463BF2MUL`): on the left, `1920x1080@60`, portrait rotated clockwise (`transform = 1`; `3` is counter-clockwise).
- The Dell's name (`DP-*`) changes between boots, so Hyprland matches it via `desc:`. The `scripts/configure_secondary.sh` script assigns it a black wallpaper dynamically.
- Waybar is on `HDMI-A-1` only; the Dell uses workspace `name:left`, while `1–10` are pinned to the main monitor.
- `Super+Shift+A` → Dell; `Super+Shift+D` → main.
- SDDM runs via `/usr/local/bin/sddm-labwc`: the startup script `/usr/local/bin/sddm-single-output` turns the Dell off by EDID. As a fallback, the `sddm-astronaut-single` theme hides the UI on every screen except `HDMI-A-1`. Configs: `/etc/sddm.conf.d/{10-wayland,theme}.conf` (see `system/linux-desktop/README.md` in dotfiles-base).

## Keybinding cheatsheet

Descriptions live right in `hl.bind()` via the local `bind()` helper, and
`scripts/keybindings-cheatsheet.py` reads the active binds from `hyprctl binds -j`.
No separate hand-maintained list of shortcuts is needed.

- `Hyper+H` (`Caps Lock+H`) — search all shortcuts via Rofi.
- `Hyper+Shift+H` — which-key style category menu.
- `Hyper+Ctrl+H` — show/hide the visual keyboard map in imv; `Esc` or `Q` close it immediately.
- Keyboard icon in Waybar: left click — search, middle click — categories, right click — show/hide the map.

## Checking the Lua config

```sh
luac -p ~/.config/hypr/hyprland.lua
Hyprland --verify-config --config ~/.config/hypr/hyprland.lua
```

Once the session is already running on Lua:

```sh
hyprctl reload
hyprctl configerrors
```

To go back to the fallback, rename `hyprland.lua` so that no file with that exact name exists, and restart the session.
