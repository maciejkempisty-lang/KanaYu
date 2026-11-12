#!/bin/sh
set -eu
cd "$(dirname "$0")/../godot"
if [ -n "${GODOT_BIN:-}" ]; then
  exec "$GODOT_BIN" --path . "$@"
elif command -v godot >/dev/null 2>&1; then
  exec godot --path . "$@"
elif [ -x /Users/bartoszzajac/Desktop/godot/Godot.app/Contents/MacOS/Godot ]; then
  exec /Users/bartoszzajac/Desktop/godot/Godot.app/Contents/MacOS/Godot --path . "$@"
fi
printf '%s\n' 'Ustaw GODOT_BIN na plik wykonywalny Godot 4.7.2.' >&2
exit 1
