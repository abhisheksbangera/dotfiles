#!/bin/bash
# Toggle Mullvad VPN: connected/connecting -> disconnect, else connect.
set -euo pipefail

if ! command -v mullvad >/dev/null; then
  notify-send -u critical "Mullvad" "mullvad CLI not installed" 2>/dev/null || true
  exit 1
fi

status="$(mullvad status 2>&1 || true)"

if echo "$status" | grep -qiE "^(Connected|Connecting)"; then
  mullvad disconnect
  notify-send -u low "Mullvad" "Disconnected" 2>/dev/null || true
else
  mullvad connect
  notify-send -u low "Mullvad" "Connected" 2>/dev/null || true
fi
