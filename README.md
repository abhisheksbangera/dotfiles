# dotfiles_v2 — portable, stow-managed

Port of the daily-driver setup to any Linux distro. Plain `hyprland.conf`,
static Catppuccin Mocha colours in alacritty (no theme daemon).

## Layout (each top-level dir is a `stow` package)

| Package | Provides |
|---|---|
| `zsh` | `~/.zshrc`, `~/.p10k.zsh` (Powerlevel10k lean) |
| `tmux` | `~/.config/tmux/tmux.conf`, sessionizer conf + `~/.local/bin/tmux-sessionizer` |
| `hypr` | reference only, **not** stowed — `~/.config/hypr` is managed outside this repo |
| `alacritty` | terminal config, Catppuccin Mocha inlined |
| `nvim` | LazyVim-based config, Catppuccin Mocha default |
| `yazi` | file manager config |
| `imv` | image viewer binds (`~/.config/imv/config`) |

## Quick start

```bash
git clone <repo> ~/dotfiles_v2 && cd ~/dotfiles_v2
./setup.sh                 # packages + fonts + cursor + tpm + stow + chsh
./setup.sh --stow-only      # just (re)stow symlinks
./setup.sh --no-chsh        # skip default-shell change
```

`install-packages.sh` holds the per-distro package lists (`PACMAN_PKGS` /
`APT_PKGS` / `DNF_PKGS` plus `AUR_PKGS` via yay/paru) together with the
JetBrainsMono Nerd Font and Bibata cursor installers. `setup.sh` delegates to
it, installs tmux `tpm`, then `stow -R` each package onto `$HOME`.

Manual follow-ups: set Firefox as default browser when asked,
`ddcutil` needs i2c access (`sudo usermod -aG i2c $USER` + re-login on some
distros), Mullvad/Stremio/Tailscale/Docker installed separately per distro.

## Keybindings (Hyprland)

Same muscle memory as before, translated to stock Hyprland:

- `Super+B` Firefox · `Super+Shift+B` private window
- `Super+Q` close · `Super+M` Mullvad browser · `Super+Y` Stremio · `Super+A` terminal + opencode
- No app launcher or bar bound — add your own in hyprland.conf (`Super+/` shows current binds)
- `Super+H/J/K/L` focus · `Super+Shift+H/J/K/L` swap · `Super+Up` toggle split · `Super+Alt+F` fullscreen
- `Super+1..9` workspaces · `F7` Mullvad toggle · `Ctrl+vol-knob` brightness · `Print` / `Super+Shift+S` region screenshot to clipboard

Deviations from the old setup: the scrolling-layout toggle is `togglesplit`
(stock Hyprland has no scrolling layout without the plugin).

## Terminals

Alacritty with JetBrainsMono Nerd Font 11pt and CSI-u `Shift+Enter` bindings so
tmux `M-S-Enter` horizontal splits work.

## Shell

- zsh + zinit (`powerlevel10k`, `completions`, `fzf-tab`, `autosuggestions`,
  `history-substring-search`, `syntax-highlighting` last)
- `zoxide --cmd cd`, `fzf --zsh`
- eza aliases (`ls/lsa/lt/lta/l/ll/la`), `vi=nvim`, `cp/mv -i`, `rm -I`
- git: `gs/g/ga/gd/gc/gcm/gcam/gcad/gp/gl/lg`
- `ff/eff/sff/open/n`, agents `c/cx/cy`, `d=docker`
- tmux: `ta/tls/tn`, `Ctrl-f` sessionizer (`~/Projects ~/Work ~/esp32`)
- tmux auto-attach on interactive shells (`ZSH_NO_TMUX=1` opts out)
- history 20k shared, case-insensitive fzf-tab previews

## Unstow / move machines

```bash
cd ~/dotfiles_v2
stow -d . -t ~ -D tmux   # remove one package
./setup.sh --stow-only   # re-apply after pull
```
