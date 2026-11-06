#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
export XDG_CONFIG_HOME="$PWD/.tooling/config"
export PUB_CACHE="$PWD/.tooling/pub-cache"
export CI=true
export FLUTTER_SUPPRESS_ANALYTICS=true
if [ -x "$PWD/.tooling/flutter/bin/flutter" ]; then
  exec "$PWD/.tooling/flutter/bin/flutter" "$@"
fi
exec flutter "$@"
