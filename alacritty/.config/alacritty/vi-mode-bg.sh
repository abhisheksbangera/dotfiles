#!/bin/sh
# Tint the Alacritty window background while Alacritty's own vi mode is active.
#
# Alacritty has no native "vi mode background" option, so the Ctrl+Shift+Space
# binding runs this right after ToggleViMode and flips a runtime config override
# over the IPC socket.
#
# Alacritty exports ALACRITTY_SOCKET in its own environment, and `alacritty msg`
# picks it up automatically. It is inherited by processes spawned this way, even
# though they are re-parented by the daemon fork.

VI_TINT='#2a1b3f'

# Optional explicit socket path as $1 (used for manual testing).
[ -n "$1" ] && ALACRITTY_SOCKET=$1

# Fallback for the unlikely case ALACRITTY_SOCKET is missing: a single instance.
if [ -z "$ALACRITTY_SOCKET" ]; then
    count=0
    for candidate in "$XDG_RUNTIME_DIR"/Alacritty-*.sock; do
        [ -S "$candidate" ] || continue
        count=$((count + 1))
        only=$candidate
    done
    [ "$count" -eq 1 ] && ALACRITTY_SOCKET=$only
fi
[ -n "$ALACRITTY_SOCKET" ] || exit 0

# The override is applied after the toggle, so the config still reflects the
# state *before* this key press: tint present => we just left vi mode.
if alacritty msg get-config 2>/dev/null | grep -q "$VI_TINT"; then
    alacritty msg config -r
else
    alacritty msg config "colors.primary.background=\"$VI_TINT\""
fi
