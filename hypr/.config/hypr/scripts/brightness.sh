#!/bin/bash
# Portable brightness control: internal panel via brightnessctl,
# external monitors via ddcutil. Notifies with notify-send.
# Usage: brightness.sh +10% | 10%- | +1% | 1%- | 50%
set -euo pipefail

step="${1:-}"
[[ -n "$step" ]] || { echo "Usage: brightness.sh +10%|10%-|50%" >&2; exit 1; }

notify() {
  if command -v notify-send >/dev/null; then
    notify-send -u low -t 1200 "Brightness" "$1" 2>/dev/null || true
  fi
}

# Internal display (laptop panel) if present
internal="$(brightnessctl -l 2>/dev/null | grep -oP "Device '\K[^']+" | head -n1 || true)"

if [[ -n "$internal" ]]; then
  brightnessctl -d "$internal" set "$step" >/dev/null 2>&1 || brightnessctl set "$step" >/dev/null
  cur="$(brightnessctl -d "$internal" -m 2>/dev/null | awk -F, '{gsub("%","",$4); print $4}' || echo "?")"
  notify "${cur}%"
  exit 0
fi

# External: ddcutil (needs i2c group / ddcutil rules from setup.sh)
if ! command -v ddcutil >/dev/null; then
  echo "No brightness device found (install brightnessctl/ddcutil)" >&2
  exit 1
fi

get_ddc() { ddcutil getvcp 10 2>/dev/null | grep -oP 'current value =\s*\K[0-9]+' | head -n1; }

if [[ "$step" =~ ^\+([0-9]+)%$ ]]; then
  delta="${BASH_REMATCH[1]}"
  cur="$(get_ddc || echo 50)"
  target=$((cur + delta))
elif [[ "$step" =~ ^([0-9]+)%-$ ]]; then
  delta="${BASH_REMATCH[1]}"
  cur="$(get_ddc || echo 50)"
  target=$((cur - delta))
elif [[ "$step" =~ ^([0-9]+)%$ ]]; then
  target="${BASH_REMATCH[1]}"
else
  echo "Bad step: $step" >&2; exit 1
fi
(( target < 1 )) && target=1
(( target > 100 )) && target=100
ddcutil setvcp 10 "$target" >/dev/null 2>&1
notify "${target}%"
