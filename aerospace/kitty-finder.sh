#!/bin/zsh

TARGET=$(osascript -e 'tell application "Finder" to get POSIX path of (insertion location as alias)' 2>/dev/null)

if [[ -z "$TARGET" ]]; then
    TARGET="$HOME"
fi

exec kitty --single-instance --directory "$TARGET"
