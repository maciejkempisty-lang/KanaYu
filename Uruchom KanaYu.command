#!/bin/sh
set -eu
cd "$(dirname "$0")"
if [ ! -d build/macos/Build/Products/Debug/KanaYu.app ]; then
  ./scripts/flutter.sh build macos --debug
fi
open "$PWD/build/macos/Build/Products/Debug/KanaYu.app"
