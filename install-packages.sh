#!/bin/bash
# install-packages.sh — distro-aware package installer for dotfiles_v2.
# Standalone: ./install-packages.sh [--stow-only]
# Called from setup.sh (which skips this when --stow-only is passed there).
#
# Package lists live here (merged from setup.sh + old package.txt, names fixed):
#   - "disks"            -> gnome-disk-utility
#   - "calibre"          -> calibre (repo build; AUR alt: calibre-bin)
#   - "mullvad-browser"  -> mullvad-browser-bin (AUR)
#   - "stremio-enhanced" -> stremio-enhanced-bin (AUR)
# Not in Debian/Fedora default repos (installed on Arch, skipped elsewhere):
#   bitwarden (use .deb/.rpm from bitwarden.com), mullvad-vpn, tailscale,
#   veracrypt, tensaku, localsend, tixati, *-bin AUR packages, vlc-plugin-ffmpeg,
#   vlc-plugins-all (Debian/Fedora ship these inside vlc).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STOW_ONLY=0
for arg in "$@"; do
  case "$arg" in
    --stow-only) STOW_ONLY=1 ;;
    -h|--help) echo "Usage: ./install-packages.sh [--stow-only]"; exit 0 ;;
    *) echo "Unknown arg: $arg (see --help)" >&2; exit 1 ;;
  esac
done

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }

detect_pm() {
  if command -v pacman >/dev/null; then echo pacman
  elif command -v apt-get >/dev/null; then echo apt
  elif command -v dnf >/dev/null; then echo dnf
  else echo none; fi
}

# --- package lists -----------------------------------------------------------
PACMAN_PKGS=(
  stow git curl zsh tmux neovim fzf fd bat eza zoxide
  ripgrep wl-clipboard hyprland mako brightnessctl ddcutil playerctl
  pavucontrol grim slurp polkit-gnome ttf-jetbrains-mono-nerd alacritty
  yazi imv lazygit github-cli base-devel
  # merged from package.txt (names fixed)
  bitwarden chafa firefox htop gnome-disk-utility mullvad-vpn ncdu
  tailscale veracrypt gnome-calculator calibre vlc vlc-plugin-ffmpeg
  vlc-plugins-all gedit nautilus tensaku localsend
)

# Arch-only: need an AUR helper (yay/paru); skipped with a warning otherwise.
AUR_PKGS=(
  visual-studio-code-bin mullvad-browser-bin stremio-enhanced-bin tixati
)

APT_PKGS=(
  stow git curl zsh tmux neovim fzf fd-find bat exa zoxide ripgrep
  wl-clipboard hyprland mako brightnessctl ddcutil playerctl pavucontrol
  grim slurp policykit-1-gnome alacritty yazi imv lazygit gh build-essential
  # merged from package.txt (only what exists in Debian/Ubuntu default repos)
  chafa firefox htop gnome-disk-utility ncdu gnome-calculator calibre
  vlc gedit nautilus
)

DNF_PKGS=(
  stow git curl zsh tmux neovim fzf fd-find bat eza zoxide ripgrep
  wl-clipboard hyprland mako brightnessctl ddcutil playerctl pavucontrol
  grim slurp polkit-gnome jetbrains-mono-fonts alacritty yazi imv lazygit
  gh gcc make
  # merged from package.txt (only what exists in Fedora default repos)
  chafa firefox htop gnome-disk-utility ncdu gnome-calculator calibre
  vlc gedit nautilus
)

# --- installers --------------------------------------------------------------
install_aur() {
  (( ${#AUR_PKGS[@]} )) || return 0
  local helper=""
  if command -v yay >/dev/null; then helper="yay"
  elif command -v paru >/dev/null; then helper="paru"
  fi
  if [[ -z "$helper" ]]; then
    warn "no AUR helper (yay/paru); skipping AUR packages: ${AUR_PKGS[*]}"
    return 0
  fi
  log "Installing AUR packages via $helper..."
  "$helper" -S --needed --noconfirm "${AUR_PKGS[@]}" \
    || warn "some AUR packages failed"
}

fix_debian_names() {
  # fd/bat binary name fixes on Debian/Ubuntu
  command -v fdfind >/dev/null && mkdir -p ~/.local/bin && ln -sf "$(command -v fdfind)" ~/.local/bin/fd 2>/dev/null || true
  command -v batcat >/dev/null && mkdir -p ~/.local/bin && ln -sf "$(command -v batcat)" ~/.local/bin/bat 2>/dev/null || true
}

install_pkgs() {
  local pm="$1"
  log "Package manager: $pm"
  case "$pm" in
    pacman)
      sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}" \
        || warn "some pacman packages failed (AUR-only ones skipped)"
      install_aur
      ;;
    apt)
      sudo apt-get update
      sudo apt-get install -y "${APT_PKGS[@]}" || warn "some apt packages failed"
      fix_debian_names
      ;;
    dnf)
      sudo dnf install -y "${DNF_PKGS[@]}" || warn "some dnf packages failed"
      ;;
    none) warn "No supported package manager; install packages manually (see README)." ;;
  esac
}

install_font() {
  if fc-list 2>/dev/null | grep -qi "JetBrainsMono Nerd"; then log "JetBrainsMono Nerd Font present"; return 0; fi
  log "Installing JetBrainsMono Nerd Font..."
  mkdir -p ~/.local/share/fonts
  tmp="$(mktemp -d)"
  ver="v3.5.1"
  curl -fsSL -o "$tmp/JetBrainsMono.zip" "https://github.com/ryanoasis/nerd-fonts/releases/download/${ver}/JetBrainsMono.zip"
  unzip -oq "$tmp/JetBrainsMono.zip" -d ~/.local/share/fonts
  rm -rf "$tmp"
  fc-cache -f ~/.local/share/fonts >/dev/null 2>&1 || true
}

install_cursor() {
  if [[ -d ~/.local/share/icons/Bibata-Modern-Ice || -d ~/.icons/Bibata-Modern-Ice ]]; then log "Bibata cursor present"; return 0; fi
  log "Installing Bibata-Modern-Ice cursor..."
  mkdir -p ~/.local/share/icons
  tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/bibata.tar.gz" "https://github.com/ful1e5/Bibata_Cursor/releases/download/v2.0.7/Bibata-Modern-Ice.tar.gz"
  tar -xzf "$tmp/bibata.tar.gz" -C ~/.local/share/icons
  rm -rf "$tmp"
}

main() {
  if [[ "$STOW_ONLY" == 1 ]]; then log "Skipping package installs (--stow-only)"; return 0; fi
  install_pkgs "$(detect_pm)"
  install_font
  install_cursor
}

main "$@"
