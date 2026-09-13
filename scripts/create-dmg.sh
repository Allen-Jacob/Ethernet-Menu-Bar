#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_PATH="$PROJECT_DIR/dist/Ethernet Menu Bar.app"
VERSION="$(defaults read "$PROJECT_DIR/App/Info" CFBundleShortVersionString)"
DMG_PATH="$PROJECT_DIR/dist/Ethernet-Menu-Bar-$VERSION.dmg"
STAGING_DIR="$(mktemp -d)"
trap 'rm -rf "$STAGING_DIR"' EXIT

"$PROJECT_DIR/scripts/build-app.sh"
ditto "$APP_PATH" "$STAGING_DIR/Ethernet Menu Bar.app"
ln -s /Applications "$STAGING_DIR/Applications"

hdiutil create \
    -volname "Ethernet Menu Bar" \
    -srcfolder "$STAGING_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

echo "$DMG_PATH"
