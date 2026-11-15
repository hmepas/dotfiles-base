# Linux desktop: system-level setup (`/etc`, `/usr/local`)

Not stowed — stow only manages `~`. These are the root-owned pieces the home
configs rely on. Apply by hand with `sudo`; everything here is small enough to
copy from this file.

## keyd — Super+C/V/X as copy/paste/cut everywhere

Mac muscle memory: Super acts like Cmd for clipboard, below the compositor, so
it works in every app (GTK, Qt, terminals, games' text fields). Hyprland relies
on it for the em dash (Super+Shift+- → AltGr+-, xkb `misc:typo`, see
`~/.config/hypr/hyprland.lua`).

`/etc/keyd/default.conf`:

```ini
[ids]
*

[main]

[meta]
# when SUPER button pressed
c = C-insert
v = S-insert
x = S-delete

[meta+alt]
c = M-A-c
v = M-A-v
x = M-A-x

[meta+shift]
# Em dash: Super+Shift+- -> AltGr+- (xkb misc:typo, see ~/.config/hypr/hyprland.lua)
minus = G-minus
```

```bash
sudo systemctl enable --now keyd
sudo keyd reload   # after edits
```

Ghostty pairs with this: `shift+insert=paste_from_clipboard` in
`stow/linux-desktop/.config/ghostty/linux.conf`.

## SDDM — Wayland greeter on labwc, session `hyprland-uwsm`

Principles:

- Greeter runs on Wayland (labwc as compositor), not X11.
- Login session: **Hyprland (uwsm)**. uwsm sources `~/.profile` with `sh`
  at login — keep `~/.profile` POSIX and never let it fail.
- Multi-monitor: the greeter shows only on the main monitor. The secondary
  output is switched off by EDID serial (its `DP-*` name changes between boots).
- Theme: `sddm-astronaut-theme` (AUR) as a base, no avatars.

`/etc/sddm.conf.d/10-wayland.conf`:

```ini
[General]
DisplayServer=wayland

[Wayland]
CompositorCommand=/usr/local/bin/sddm-labwc
```

`/etc/sddm.conf.d/theme.conf`:

```ini
[Theme]
Current=sddm-astronaut-theme

[Users]
# no avatars
DisableAvatarsThreshold=2
# cursor on the password input
RememberLastUser=true
```

`/etc/sddm.conf.d/nvidia.conf` (only with an NVIDIA GPU; no virtual keyboard /
software render):

```ini
[General]
InputMethod=
```

`/usr/local/bin/sddm-labwc` (wrapper: SDDM 0.21 drops arguments from
`CompositorCommand`):

```sh
#!/bin/sh
exec /usr/bin/labwc -s /usr/local/bin/sddm-single-output
```

`/usr/local/bin/sddm-single-output` (only with a secondary monitor; put its
EDID serial from `wlr-randr` in place of `<SERIAL>`):

```sh
#!/bin/sh
# Disable the secondary output in the SDDM/labwc greeter, resolved by EDID serial.
log=/tmp/sddm-single-output.log
: > "$log"
attempt=0
while [ "$attempt" -lt 50 ]; do
    state="$(/usr/bin/wlr-randr 2>>"$log")"
    secondary="$(printf '%s\n' "$state" | awk '/^[^ ]/{name=$1} /Serial: <SERIAL>/{print name; exit}')"
    if [ -n "$secondary" ]; then
        echo "disabling $secondary" >> "$log"
        /usr/bin/wlr-randr --output "$secondary" --off >>"$log" 2>&1
        exit $?
    fi
    attempt=$((attempt + 1))
    sleep 0.1
done
echo 'secondary output not found' >> "$log"
exit 0
```

On the current box a fork `sddm-astronaut-single` additionally hides the UI on
all but the main output (fallback if the script loses the race).

```bash
sudo chmod +x /usr/local/bin/sddm-labwc /usr/local/bin/sddm-single-output
sudo systemctl enable sddm
```

## Apple keyboard

`/etc/modprobe.d/hid_apple.conf` — F1..F12 by default, media keys via Fn:

```
options hid_apple fnmode=2
```

## Deliberately out of scope

Machine-specific, redo per hardware (an agent can tune them on the spot):

- Audio device tuning: PipeWire rnnoise filter, WirePlumber per-device rules,
  udev rules disabling onboard audio, USB headset revive service.
- GPU driver / `modprobe.d/nvidia.conf`, fan control, microcode.
- VPN / transparent proxy (sing-box, nftables, tproxy routing) — separate subsystem.
