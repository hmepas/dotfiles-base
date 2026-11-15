# hmepas / dotfiles-base

Base dotfiles needed everywhere: Mac, Linux (desktop and remote SSH).
Context/platform-specific dotfiles are in other repos.
Neovim has its own repo as well.

## Design

- **GNU Stow** for symlinks. No profile autodetection.
- **Shell modules** (`.zshrc.local/*.zsh`) are distributed across stow packages and automatically collected into a single directory in `~` via stow-folding.
- **Secrets — never in the repo.** `.gitignore` + `gitleaks` + pre-commit hook. Automation via Bitwarden is a separate iteration.

---

## Installation

### Base (required everywhere)

```bash
# 1. brew + stow
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install stow gitleaks git

# 2. Clone
git clone https://github.com/hmepas/dotfiles-base.git
cd dotfiles-base

# 3. Packages
brew bundle --file=packages/Brewfile

# 4. Base symlinking
stow -t ~ -d stow shell term git bin-common

# 5. Shared agent skills (Claude, Codex, Pi)
./scripts/setup-agent-skills.sh

# 6. TPM for tmux plugins
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
# Inside tmux: prefix + I
```

`setup-agent-skills.sh` clones the xlsx skill into `~/.agents/skills/xlsx` and
links it into Claude, Codex, and Pi. Override its personal local source when
needed: `SKILL_REPO=<repository-url-or-path> ./scripts/setup-agent-skills.sh`.

When stowing the `claude` package, use `--no-folding` so `~/.claude` remains a
directory and skills are not written into this repository:

```bash
stow --no-folding -t ~ -d stow claude
```

### Any GUI host (Mac or Linux desktop)

Adds cross-platform GUI terminal configs (WezTerm, Ghostty).
Skip on headless / remote-SSH hosts.

```bash
stow -t ~ -d stow term-gui
```

Ghostty config is split: `term-gui` ships the shared `~/.config/ghostty/config`,
which optionally includes `macos.conf` (from `macos-common`) and `linux.conf`
(from `linux-desktop`). Without an OS package Ghostty still works with the
shared part only.

Ghostty renders Cyrillic with a bold Hack face so latin `c` and cyrillic `с` never
look alike (iTerm2 did this via "Non-ASCII font"). Ghostty matches fonts by family
name only, so the bold face has to exist as its own family. Generate it once per Mac
(needs the `font-hack-nerd-font` cask and `uv`; writes `~/Library/Fonts/HackNFMBold-Regular.ttf`):

```bash
./scripts/make-hack-nfm-bold-family.py
```

### Any Mac

```bash
defaults write -g NSWindowShouldDragOnGesture -bool true # to move windows with ctrl-cmd
stow -t ~ -d stow macos-common
```

Existing Macs after the Ghostty split: `stow -R -t ~ -d stow term-gui macos-common`
(adds `~/.config/ghostty/macos.conf`; without it Ghostty loses the Mac bits).

### Personal Mac (on top of base)

```bash
brew bundle --file=packages/Brewfile.personal
./scripts/set-iina-defaults.sh # set IINA as the default video player
stow -t ~ -d stow macos-personal macos-yabai-scripts
touch ~/.sip_disabled   # personal mac runs with SIP off + yabai SA loaded
```

`set-iina-defaults.sh` changes video file associations for the current user.
Run it manually after installing IINA and duti; it does not run at shell startup.
It also assigns `.ts` files to IINA, including TypeScript files with that extension.

`macos-personal` ships the SA-enabled `~/.yabairc`. `macos-yabai-scripts`
provides `~/.config/yabai/` helper scripts (shared with the work mac).
`~/.sip_disabled` tells Hammerspoon to enable SA-only bindings (sticky,
scratchpads).

`macos-personal` also ships `~/Library/LaunchAgents/com.hmepas.simple-bar-server.plist`
(simple-bar-server for the Übersicht simple-bar widget; expects a clone at
`~/.config/yabai/simple-bar-server` and brew `node`). First time after stow:

```bash
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.hmepas.simple-bar-server.plist
```

### Work Mac (on top of base)

```bash
brew bundle --file=packages/Brewfile.work
stow -t ~ -d stow macos-work macos-yabai-scripts
```

`macos-work` ships the no-SA `~/.yabairc` (works with SIP enabled).
Do **not** create `~/.sip_disabled` here — Hammerspoon will then skip
SA-only bindings that would otherwise no-op against the daemon.

### Arch Linux (base, any host incl. SSH)

```bash
sed 's/#.*//' packages/arch/pkglist.txt | xargs sudo pacman -S --needed
stow -t ~ -d stow shell term git bin-common
```

### Linux desktop — Arch + Hyprland (on top of Arch base + term-gui)

Skip on headless / remote-SSH hosts. Shares `shell`, `term`, `git`,
`bin-common` with SSH Linuxes, so anything desktop-only (Wayland, Bitwarden
agent, linuxbrew, GUI) goes to `linux-desktop`, never to base packages.

```bash
# Packages
sed 's/#.*//' packages/arch/pkglist.desktop.txt     | xargs sudo pacman -S --needed
sed 's/#.*//' packages/arch/pkglist.desktop.aur.txt | xargs paru -S --needed
sed 's/#.*//' packages/flatpak.linux-desktop.txt    | xargs flatpak install -y flathub
brew bundle --file=packages/Brewfile.linux-desktop   # linuxbrew, optional

# Dotfiles. --no-folding: apps write extra files into their config dirs,
# keep those out of the repo.
stow -t ~ -d stow term-gui
stow --no-folding -t ~ -d stow linux-desktop

# Post-steps
systemctl --user enable --now elephant.service   # walker backend
./scripts/set-mpv-defaults.sh                    # mpv for all video/*
git clone https://github.com/familyfriendlymikey/mpv-cut ~/.config/mpv/scripts/mpv-cut
```

Don't run `gh auth setup-git` (it writes into the stowed `~/.gitconfig`, i.e.
into this repo). Put the helper into `~/.gitconfig-local` instead:

```ini
[credential "https://github.com"]
	helper =
	helper = !/usr/bin/gh auth git-credential
```

Root-owned parts (SDDM greeter, keyd Super+C/V) — see
[`system/linux-desktop/README.md`](system/linux-desktop/README.md).

**What lives where**

| Thing | Where |
|---|---|
| Hyprland (`~/.config/hypr`, Lua config, cheatsheet scripts) | own git repo, not here |
| Neovim | `dotfiles-nvim` repo |
| waybar, walker + elephant, rofi, swaync, snappy-switcher, yazi, fontconfig, portals | `stow/linux-desktop/.config` |
| Ghostty Linux overlay (`linux.conf`, `ctrl-ru.conf` Ctrl+cyrillic fix) | `stow/linux-desktop/.config/ghostty` |
| `~/bin`: screenshot-edit (hyprshot → satty), lvsk-calendar-popup (waybar clock), watch-pb, find_cp, smart-mpv | `stow/linux-desktop/bin` |
| zsh: linuxbrew, fnm, Bitwarden SSH agent | `stow/linux-desktop/.zshrc.local` |

**Principles (not stored as files)**

- Theming: dark everywhere, Catppuccin Mocha. GTK via `nwg-look`
  (`catppuccin-mocha-lavender-standard+default`, Adwaita icons/cursor, Adwaita
  Sans 11, hintslight + rgb); it writes gtk-3/4 `settings.ini`, `.gtkrc-2.0`,
  `xsettingsd.conf` itself. Qt via `qt6ct`: Fusion + `darker` palette +
  `fusion-fixes.qss`, Papirus-Dark icons, Roboto 9 / Hack Nerd Font Mono 9,
  native dialogs through `xdgdesktopportal`.
- Fonts: Hack Nerd Font Mono for terminals, Symbols Nerd Font as fallback.
- SSH agent on desktop = Bitwarden (flatpak); base `.zshrc` never sets
  `SSH_AUTH_SOCK`, so SSH hosts keep the forwarded agent.
- Steam games run on Proton-GE (`proton-ge-custom-bin`); per-game launch
  options/HDR notes live with the Hyprland repo (`GAMERUN.md`).
- Generated or app-owned files are not stored: `mimeapps.list` (use
  `set-mpv-defaults.sh`), `btop.conf`, superfile themes, elephant docs,
  `brew services` units, completion dumps.
- Machine-specific stuff (audio device tuning, GPU, VPN, local LLM scripts,
  games) stays out of this repo.

### Secrets

See `SECRETS.md` (to be created as part of BW.md PRD). In the first iteration — manually place keys in `~`, mode `600`.

---

## Update

```bash
cd dotfiles-base
git pull
# stow links are already in place, changes are visible immediately
```

When adding new files to a stow package — repeat `stow -t ~ -d stow <package>`.

## Unstow

```bash
stow -D -t ~ -d stow <package>
```

## Risk-free testing

```bash
stow -n -v -t ~ -d stow shell   # dry-run, shows what will be symlinked
```

---

## Structure

| Path | Description |
|---|---|
| `packages/Brewfile` | Common for any Mac |
| `packages/Brewfile.personal` | Personal Mac |
| `packages/Brewfile.work` | Work Mac |
| `packages/arch/` | Arch Linux — pacman + paru |
| `stow/shell/` | `.zshrc`, `.profile`, common zsh modules |
| `stow/term/` | `.tmux.conf`, `starship.toml`, `tuios/config.toml` |
| `stow/term-gui/` | Cross-platform GUI terminals (WezTerm, Ghostty) — any Mac or Linux desktop |
| `stow/linux-desktop/` | Linux-only desktop utilities, including `smart-mpv`; skip on SSH/headless hosts |
| `stow/git/` | `.gitconfig`, global `git/ignore` |
| `stow/bin/` | cross-platform scripts |
| `stow/macos-common/` | Any Mac: macfeh, pgcli, neovide, mac-only bin scripts |
| `stow/macos-personal/` | Personal Mac: SA-enabled `.yabairc`, yc, gemini, ass aliases |
| `stow/macos-work/` | Work Mac: no-SA `.yabairc` (SIP-safe variant) |
| `stow/macos-yabai-scripts/` | Yabai helper scripts → `~/.config/yabai/`. Stow on any yabai mac (personal + work) |
| `stow/hammerspoon/` | Hammerspoon config — three modes (yabai+SA / yabai no-SA / no-yabai), see its README |
| `stow/linux/` | Arch (coming later) |
| `scripts/` | helper utilities |
| `.gitleaks.toml` | secret scanner rules |
| `.pre-commit-config.yaml` | pre-commit hooks |
