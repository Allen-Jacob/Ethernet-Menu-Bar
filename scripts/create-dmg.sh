#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_PATH="$PROJECT_DIR/dist/Ethernet Menu Bar.app"
VERSION="$(defaults read "$PROJECT_DIR/App/Info" CFBundleShortVersionString)"
DMG_PATH="$PROJECT_DIR/dist/Ethernet-Menu-Bar-$VERSION.dmg"
STAGING_DIR="$(mktemp -d)"
RW_DMG="$STAGING_DIR/installer-rw.dmg"
BACKGROUND_DIR="$STAGING_DIR/source/.background"
VOLUME_NAME="Ethernet Menu Bar $VERSION"
MOUNT_DIR="/Volumes/$VOLUME_NAME"
DEVICE=""

cleanup() {
    if [[ -n "$DEVICE" ]]; then
        hdiutil detach "$DEVICE" -quiet 2>/dev/null || true
    fi
    rm -rf "$STAGING_DIR"
}
trap cleanup EXIT

"$PROJECT_DIR/scripts/build-app.sh"
swift "$PROJECT_DIR/scripts/create-dmg-background.swift" >/dev/null
mkdir -p "$STAGING_DIR/source" "$BACKGROUND_DIR"
ditto "$APP_PATH" "$STAGING_DIR/source/Ethernet Menu Bar.app"
ln -s /Applications "$STAGING_DIR/source/Applications"
sips -z 413 660 "$PROJECT_DIR/App/DMG/background.png" --out "$BACKGROUND_DIR/background.png" >/dev/null

hdiutil create \
    -volname "$VOLUME_NAME" \
    -srcfolder "$STAGING_DIR/source" \
    -fs HFS+ \
    -format UDRW \
    "$RW_DMG" >/dev/null

DEVICE="$(hdiutil attach -readwrite -noverify -noautoopen "$RW_DMG" | awk '/Apple_HFS/ {print $1; exit}')"
SetFile -a V "$MOUNT_DIR/.background"

osascript <<APPLESCRIPT
tell application "Finder"
    tell disk "$VOLUME_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set pathbar visible of container window to false
        set sidebar width of container window to 0
        set bounds of container window to {120, 120, 780, 533}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 96
        set text size of viewOptions to 13
        set background picture of viewOptions to file ".background:background.png"
        set position of item "Ethernet Menu Bar.app" of container window to {165, 205}
        set position of item "Applications" of container window to {495, 205}
        update without registering applications
        delay 2
        close
    end tell
end tell
APPLESCRIPT

sync
hdiutil detach "$DEVICE" -quiet
DEVICE=""
hdiutil convert "$RW_DMG" -format UDZO -imagekey zlib-level=9 -o "$DMG_PATH" -ov >/dev/null

echo "$DMG_PATH"
