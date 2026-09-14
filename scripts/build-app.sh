#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="Ethernet Menu Bar"
APP_DIR="$PROJECT_DIR/dist/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"

cd "$PROJECT_DIR"
swift build -c release

mkdir -p "$CONTENTS_DIR/MacOS" "$CONTENTS_DIR/Resources"
cp "$PROJECT_DIR/.build/release/EthernetMenuBar" "$CONTENTS_DIR/MacOS/EthernetMenuBar"
cp "$PROJECT_DIR/App/Info.plist" "$CONTENTS_DIR/Info.plist"
cp "$PROJECT_DIR/App/AppIcon.icns" "$CONTENTS_DIR/Resources/AppIcon.icns"

SIGN_IDENTITY="${CODESIGN_IDENTITY:-}"
if [[ -z "$SIGN_IDENTITY" ]]; then
    SIGN_IDENTITY="$(security find-identity -v -p codesigning | sed -n 's/.*"\(.*\)"/\1/p' | head -n 1)"
fi
if [[ -n "$SIGN_IDENTITY" ]]; then
    codesign --force --deep --options runtime --timestamp --sign "$SIGN_IDENTITY" "$APP_DIR"
else
    SIGN_IDENTITY="-"
    codesign --force --deep --options runtime --timestamp=none --sign "$SIGN_IDENTITY" "$APP_DIR"
fi
echo "Signed with: $SIGN_IDENTITY"
echo "$APP_DIR"
