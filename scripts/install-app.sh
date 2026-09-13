#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_APP="$PROJECT_DIR/dist/Ethernet Menu Bar.app"
INSTALLED_APP="/Applications/Ethernet Menu Bar.app"

"$PROJECT_DIR/scripts/build-app.sh"

pkill -x EthernetMenuBar 2>/dev/null || true
ditto "$SOURCE_APP" "$INSTALLED_APP"
codesign --verify --deep --strict "$INSTALLED_APP"
open "$INSTALLED_APP"

for _ in 1 2 3 4 5; do
    if pgrep -x EthernetMenuBar >/dev/null; then
        VERSION="$(defaults read "$INSTALLED_APP/Contents/Info" CFBundleShortVersionString)"
        echo "Installation réussie — Ethernet Menu Bar $VERSION est active."
        exit 0
    fi
    sleep 1
done

echo "L’installation est terminée, mais l’app ne semble pas être active." >&2
exit 1
