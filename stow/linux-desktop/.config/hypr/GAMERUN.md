# Game launch notes

Mini guide for Steam Launch Options on Hyprland/NVIDIA.

## RDR2: HDR + NVIDIA features via gamescope (Valve Proton path)

Steam → game → Properties → Launch Options:

```bash
PROTON_ENABLE_NVAPI=1 gamescope -W 3840 -H 2160 -r 160 --hdr-enabled --hdr-itm-enable -- %command%
```

What this does:

- `PROTON_ENABLE_NVAPI=1` enables NVIDIA NVAPI in Proton, so the game can expose NVIDIA features such as DLSS/Reflex when supported.
- `gamescope` runs the game inside a dedicated gaming compositor.
- `-W 3840 -H 2160` sets the target resolution to 4K.
- `-r 160` sets the target refresh rate to 160 Hz.
- `--hdr-enabled` attempts to enable the HDR pipeline.
- `--hdr-itm-enable` enables inverse tone mapping for SDR content inside an HDR scene; if the image looks wrong, try removing it.
- `%command%` is replaced by Steam with the actual game launch command.

## Variant with GameMode

If `gamemode` is installed, a good permanent launch option can be:

```bash
PROTON_ENABLE_NVAPI=1 gamemoderun gamescope -W 3840 -H 2160 -r 160 --hdr-enabled --hdr-itm-enable -- %command%
```

`gamemoderun` may improve frametime/FPS by applying gaming-oriented power/performance hints.

## Variant with MangoHud for diagnostics

If `mangohud` is installed, use this temporarily for measurements:

```bash
PROTON_ENABLE_NVAPI=1 gamemoderun gamescope -W 3840 -H 2160 -r 160 --hdr-enabled --hdr-itm-enable -- mangohud %command%
```

`mangohud` shows FPS, frametime, GPU/CPU load, VRAM usage, temperatures, etc.

## How to choose

1. Start with the clean variant without `gamemoderun` and `mangohud`.
2. If the game starts correctly and HDR works, add `gamemoderun`.
3. Use `mangohud` temporarily for measurements, then remove it if the overlay is not needed.

## Useful packages

```bash
sudo pacman -S gamemode mangohud
```

`gamescope` is already installed.

## If HDR looks wrong

Try removing `--hdr-itm-enable`:

```bash
PROTON_ENABLE_NVAPI=1 gamemoderun gamescope -W 3840 -H 2160 -r 160 --hdr-enabled -- %command%
```

If flickering or other issues appear, fall back to launching without HDR/gamescope:

```bash
PROTON_ENABLE_NVAPI=1 %command%
```

## Native HDR on Hyprland + NVIDIA (KCD2 recipe, 2026-11-13)

Verified stack: Hyprland 0.57 (Lua config), nvidia 615, aquamarine 0.14, INNOCN 32M2V over HDMI,
RTX 5070 Ti, GE-Proton11-12.

### Prerequisites

1. **10-bit output** in `hyprland.lua`: `bitdepth = 10` on the HDMI-A-1 monitor rule.
   `hyprctl monitors` must show `currentFormat: XBGR2101010`. XR30 is still rejected by the
   NVIDIA GBM backend, but aquamarine now falls back to XB30 silently; 160 Hz is kept.
   HDR on 8-bit works but bands badly (PQ in 8 bit).
2. `render.cm_auto_hdr = 1` (default). Hyprland switches the output to HDR only for a
   **fullscreen** client that commits an HDR image description. Windowed = HDR revoked.
3. **Proton-GE**, not Valve Proton. Valve's Proton 10/11/Experimental ship no `winewayland.so`
   and ignore `PROTON_ENABLE_WAYLAND`/`PROTON_ENABLE_HDR`; the game stays on XWayland and HDR
   is impossible. Installed via `paru -S proton-ge-custom-bin`
   (`/usr/share/steam/compatibilitytools.d/proton-ge-custom`). Restart Steam after install.

### Steam setup (KCD2)

Properties → Compatibility → force **Proton-GE**. Properties → General → Launch Options:

```bash
PROTON_ENABLE_WAYLAND=1 PROTON_FORCE_HDR=1 %command%
```

Why `FORCE` and not `ENABLE`: with `cm_auto_hdr` Hyprland reports the output as SDR until the
client itself commits HDR, so Wine sees an SDR output and never exposes HDR to the game
(`r_HDROutput` stays 0). `PROTON_FORCE_HDR` sets `DXVK_HDR=1` + `WAYLANDDRV_FORCE_HDR=1` and
breaks that loop. The GE source comments name Hyprland `cm_auto_hdr` as the reason this exists.

Then in game: Display mode → Fullscreen first, then enable HDR in graphics settings.
A short black screen on HDR on/off is the output being reconfigured; expected.

Bonus: the Wayland driver gives working alt-tab and no XWayland scaling.

### Verify

```bash
hyprctl -j clients | grep -A3 kingdomcome   # "xwayland": false, "fullscreen": 2
hyprctl monitors | grep currentFormat        # XBGR2101010
grep r_HDROutput "$HOME/.local/share/Steam/steamapps/compatdata/1771300/pfx/drive_c/users/steamuser/Saved Games/kingdomcome2/profiles/default/attributes.xml"   # value="1"
```

### Pitfalls hit along the way

- Steam silently dropped the Launch Options text once. Reopen Properties and confirm it saved.
- `hyprctl keyword` returns `unknown request` with the Lua config; use
  `hyprctl eval 'hl.monitor({ ... })'`. Omitting `bitdepth` does not reset it; pass `bitdepth = 8` to revert.
- Changing the monitor rule while a game runs drops its fullscreen state; the game may save
  "windowed" and come back that way.
- Nested `gamescope --hdr-enabled` also works on Valve Proton, but HDR is revoked the moment the
  gamescope window leaves fullscreen and gamescope does not re-enable it on its own
  (toggle fullscreen off/on with Super+Shift+F, then reopen the game's graphics settings).
- `hyprctl monitors` → `colorManagementPreset` shows the configured preset (`srgb`), not the live
  HDR state; use the game's own HDR toggle / config as the signal.
- Not related to HDR: the "brightness flicker" fix from 2026-11-04 was VRR off (`vrr = 0`),
  the June 10-bit removal was XR30 allocation errors. Separate issues.

### mpv side effect

With `cm_auto_hdr` on, mpv (`vo=gpu-next`, `target-colorspace-hint=auto`) in fullscreen asks for
HDR/WCG and the whole output switches, so the picture "changes gamma". That is the compositor
entering HDR mode, not a bug. To keep mpv SDR and let libplacebo tone-map, put
`target-colorspace-hint=no` in `~/.config/mpv/mpv.conf`; with 10-bit on, the
"wide color gamut is enabled but the display is not in 10-bit mode" warning is gone either way.
