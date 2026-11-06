#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
./scripts/flutter.sh build web --release --no-web-resources-cdn --dart-define=RIVE_NATIVE_WASM_HOST=rive/
exec python3 -m http.server 4175 --bind 127.0.0.1 --directory build/web
