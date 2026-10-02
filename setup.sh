#!/bin/bash
# dotfiles_v2 setup: multi-distro (Arch/Debian-Fedora), stow-based, no distro-specific helpers.
# Usage:
#   git clone <repo> ~/dotfiles_v2 && cd ~/dotfiles_v2 && ./setup.sh
#   ./setup.sh --stow-only        # only (re)stow, skip package installs
#   ./setup.sh --no-chsh          # skip default-shell change
#
# Package installation lives in ./install-packages.sh (package lists + fonts +
# cursor). setup.sh delegates to it unless --stow-only is given.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STOW_ONLY=0
DO_CHSH=1
for arg in "$@"; do
  case "$arg" in
    --stow-only) STOW_ONLY=1 ;;
    --no-chsh) DO_CHSH=0 ;;
    -h|--help) echo "Usage: ./setup.sh [--stow-only] [--no-chsh]"; exit 0 ;;
  esac
done

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }

install_packages() {
  if [[ "$STOW_ONLY" == 1 ]]; then log "Skipping package installs (--stow-only)"; return 0; fi
  bash "$DOTFILES_DIR/install-packages.sh"
}

install_tpm() {
  if [[ -d ~/.tmux/plugins/tpm ]]; then log "tpm present"; return 0; fi
  log "Installing tmux plugin manager (optional, only if you add plugins)..."
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm 2>/dev/null || warn "tpm clone failed (offline?)"
}

stow_all() {
  command -v stow >/dev/null || { echo "stow not installed" >&2; exit 1; }
  log "Stowing packages..."
  # --dotfiles would map dot-* to dotfiles; we store real dot names, so plain stow.
  # --restow to refresh, adopt only on explicit request to avoid surprises.
  # note: hypr/ kept in repo as reference only, not stowed (hyprland.conf is managed outside this repo).
  pkgs=(zsh tmux alacritty nvim yazi imv)
  for pkg in "${pkgs[@]}"; do
    [[ -d "$DOTFILES_DIR/$pkg" ]] || continue
    stow -d "$DOTFILES_DIR" -t "$HOME" -R "$pkg"
    log "stowed $pkg"
  done
  # chmod +x ~/.config/hypr/scripts/*.sh 2>/dev/null || true
  chmod +x ~/.local/bin/tmux-sessionizer 2>/dev/null || true
}

set_shell() {
  [[ "$DO_CHSH" == 1 && "$STOW_ONLY" == 0 ]] || return 0
  if [[ "${SHELL:-}" == *zsh ]]; then log "zsh already default"; return 0; fi
  if command -v zsh >/dev/null; then
    chsh -s "$(command -v zsh)" && log "default shell -> zsh (re-login to take effect)" || warn "chsh failed; run: chsh -s \$(which zsh)"
  fi
}

set_defaults() {
  # Best-effort desktop defaults (portable equivalents of default browser/terminal/editor)
  if command -v xdg-settings >/dev/null && [[ -f ~/.local/share/applications/firefox.desktop || -f /usr/share/applications/firefox.desktop ]]; then
    xdg-settings set default-web-browser firefox.desktop 2>/dev/null || true
  fi
  log "If Firefox prompts, set it as default browser. Terminal: \$TERMINAL not standardized; Hyprland uses \$terminal=alacritty (edit hyprland.conf). Editor: \$EDITOR=nvim (set in .zshrc)."
}

main() {
  install_packages
  install_tpm
  stow_all
  set_shell
  set_defaults
  log "Done. Next: 1) re-login, 2) tmux prefix is C-Space. See README for per-distro notes."
}

main "$@"
