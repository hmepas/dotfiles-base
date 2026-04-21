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

# 5. TPM for tmux plugins
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
# Inside tmux: prefix + I
```

### Any GUI host (Mac or Linux desktop)

Adds cross-platform GUI terminal configs (WezTerm, Ghostty).
Skip on headless / remote-SSH hosts.

```bash
stow -t ~ -d stow term-gui
```

### Any Mac

```bash
stow -t ~ -d stow macos-common
```

### Personal Mac (on top of base)

```bash
brew bundle --file=packages/Brewfile.personal
stow -t ~ -d stow macos-personal
```

### Work Mac (on top of base)

```bash
brew bundle --file=packages/Brewfile.work
stow -t ~ -d stow macos-work
```

### Arch Linux

```bash
# TODO: packages/arch/pkglist.txt and stow/linux/
```

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
| `stow/term/` | `.tmux.conf`, `starship.toml` |
| `stow/term-gui/` | Cross-platform GUI terminals (WezTerm, Ghostty) — any Mac or Linux desktop |
| `stow/git/` | `.gitconfig`, global `git/ignore` |
| `stow/bin/` | cross-platform scripts |
| `stow/macos-common/` | Any Mac: iTerm2 integration, macfeh, pgcli, neovide, mac-only bin scripts |
| `stow/macos-personal/` | Personal Mac: yc, gemini, ass aliases |
| `stow/macos-work/` | Work Mac (currently empty) |
| `stow/linux/` | Arch (coming later) |
| `scripts/` | helper utilities |
| `.gitleaks.toml` | secret scanner rules |
| `.pre-commit-config.yaml` | pre-commit hooks |
