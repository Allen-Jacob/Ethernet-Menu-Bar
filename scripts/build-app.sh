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

codesign --force --deep --sign - "$APP_DIR"
echo "$APP_DIR"
