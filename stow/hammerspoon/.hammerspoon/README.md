# Deploying Hammerspoon config

```sh
brew install --cask hammerspoon # install hammerspoon itself
stow --dotfiles -t ~ dot-hammerspoon
```

# Mode detection

Host mode is auto-detected by presence of two files in `$HOME`:

| File              | Sets                | How it appears                                     |
|-------------------|---------------------|----------------------------------------------------|
| `~/.yabairc`      | `IS_YABAI = true`   | created by stowing `macos-personal` or `macos-work` (yabai's own config file) |
| `~/.sip_disabled` | `SIP_DISABLED = true` | manual `touch ~/.sip_disabled` on a host where SIP is actually off and yabai SA is loaded |

That gives three modes:

| Mode                  | `IS_YABAI` | `SIP_DISABLED` | Host                                  |
|-----------------------|:----------:|:--------------:|---------------------------------------|
| yabai + SA            | ✓          | ✓              | personal mac (after `touch ~/.sip_disabled`) |
| yabai (SIP enabled)   | ✓          | ✗              | work mac                              |
| no yabai              | ✗          | ✗              | anything else (Linux desktop, server) |

If `IS_YABAI` is false, all yabai modules (`yabai.lua`, `scratchpad`, `service`, yabai branches in `windows` / `spaces` / `apps` / `system`) become no-ops or fall back to pure-Hammerspoon alternatives.

If `IS_YABAI` is true but `SIP_DISABLED` is false, SA-only bindings are skipped:
- `hyper-s` window --toggle sticky
- `alt+shift-tab` space --move next
- `hyper-0..9` scratchpad mode (whole module not loaded)

# Setup
1. Open Hammerspoon - grant Accessibility access.
2. Menu Hammerspoon -> Install Command Line Tool (provides the `hs` CLI).
3. Menu Hammerspoon -> Preferences -> Launch on Login [check].

Check:
```sh
hs -c "print(require('config').IS_YABAI, require('config').SIP_DISABLED)"
```


# Modules

| File                             | Description                              | Host       |
|----------------------------------|------------------------------------------|------------|
| `init.lua`                       | main                                     | both       |
| `config.lua`                     | IS_YABAI / SIP_DISABLED detection        | both       |
| `modules/keybind.lua`            | `hs.hotkey.bind` wrapper + disableAll    | both       |
| `modules/yabai.lua`              | yabai calls / helper scripts             | both (no-op without yabai) |
| `modules/system.lua`             | block cmd-h/m, AppleScripts (alt-d/i)    | both (AS yabai only) |
| `modules/apps.lua`               | alt-o/w/g/s/r/m/f                        | both, different |
| `modules/spaces.lua`             | alt-1..9 / alt-tab / window→space        | both, different |
| `modules/windows.lua`            | focus/swap/warp/resize/display           | both, different |
| `modules/modes/app_launch.lua`   | alt-a → ...                              | both       |
| `modules/modes/scratchpad.lua`   | hyper-0 / hyper-1..9                     | yabai + SA |
| `modules/modes/service.lua`      | hyper-`;` mode                           | yabai      |
| `modules/media_keys.lua`         | hyper+Fxx → media keys (opt-in)          | non-yabai  |
