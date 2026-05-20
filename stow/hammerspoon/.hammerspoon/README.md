# Deploying Hammerspoon config

```sh
brew install --cask hammerspoon # install hammerspoon itself
stow --dotfiles -t ~ dot-hammerspoon
```

If you use yabai:
```sh
touch ~/.is_yabai
```

# Setup
1. Open Hammerspoon - grant Accessibility access.
2. Menu Hammerspoon -> Install Command Line Tool (provides the `hs` CLI).
3. Menu Hammerspoon -> Preferences -> Launch on Login [check].

Check:
```sh
hs -c "print(require('config').IS_YABAI)"
```


# Modules

| File                             | Description                              | Host       |
|----------------------------------|------------------------------------------|------------|
| `init.lua`                       | main                                     | both       |
| `config.lua`                     | is-yabai logic                           | both       |
| `modules/keybind.lua`            | `hs.hotkey.bind` wrapper + disableAll    | both       |
| `modules/yabai.lua`              | yabai calls / helper scripts             | both (no-op without yabai) |
| `modules/system.lua`             | block cmd-h/m, AppleScripts (alt-d/i)    | both (AS yabai only) |
| `modules/apps.lua`               | alt-o/w/g/s/r/m/f                        | both, different |
| `modules/spaces.lua`             | alt-1..9 / alt-tab / window→space        | both, different |
| `modules/windows.lua`            | focus/swap/warp/resize/display           | both, different |
| `modules/modes/app_launch.lua`   | alt-a → ...                              | both       |
| `modules/modes/scratchpad.lua`   | hyper-0 / hyper-1..9                     | yabai      |
| `modules/modes/service.lua`      | hyper-`;` mode                           | yabai      |
| `modules/media_keys.lua`         | hyper+Fxx → media keys (opt-in)          | non-yabai  |
