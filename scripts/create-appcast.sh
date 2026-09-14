#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
UPDATES_DIR="$PROJECT_DIR/dist/updates"
SPARKLE_TOOLS="$PROJECT_DIR/.build/artifacts/sparkle/Sparkle/bin"
TAG="${GITHUB_REF_NAME:?GITHUB_REF_NAME is required}"
PRIVATE_KEY="${SPARKLE_PRIVATE_KEY:?SPARKLE_PRIVATE_KEY is required}"

mkdir -p "$UPDATES_DIR"
cp "$PROJECT_DIR/dist/Ethernet-Menu-Bar.zip" "$UPDATES_DIR/Ethernet-Menu-Bar-$TAG.zip"

# Reuse the prior feed and archives so generate_appcast can retain history and
# create binary deltas from the versions users may still have installed.
if ! curl --fail --location --silent --show-error \
    "https://github.com/Allen-Jacob/Ethernet-Menu-Bar/releases/latest/download/appcast.xml" \
    --output "$UPDATES_DIR/appcast.xml"; then
    rm -f "$UPDATES_DIR/appcast.xml"
fi

gh api "repos/Allen-Jacob/Ethernet-Menu-Bar/releases?per_page=5" \
    --jq '.[] | [.tag_name, (.assets[] | select(.name == "Ethernet-Menu-Bar.zip") | .browser_download_url)] | @tsv' |
while IFS=$'\t' read -r old_tag archive_url; do
    [[ -n "$archive_url" ]] || continue
    curl --fail --location --silent --show-error "$archive_url" \
        --output "$UPDATES_DIR/Ethernet-Menu-Bar-$old_tag.zip"
done

printf '%s' "$PRIVATE_KEY" | "$SPARKLE_TOOLS/generate_appcast" \
    --ed-key-file - \
    --account ca.jacoballen.EthernetMenuBar \
    --download-url-prefix "https://github.com/Allen-Jacob/Ethernet-Menu-Bar/releases/download/$TAG/" \
    --link "https://github.com/Allen-Jacob/Ethernet-Menu-Bar" \
    --maximum-versions 5 \
    --maximum-deltas 5 \
    "$UPDATES_DIR"
