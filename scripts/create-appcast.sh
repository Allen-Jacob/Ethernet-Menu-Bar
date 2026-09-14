#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
UPDATES_DIR="$PROJECT_DIR/dist/updates"
SPARKLE_TOOLS="$PROJECT_DIR/.build/artifacts/sparkle/Sparkle/bin"
TAG="${GITHUB_REF_NAME:?GITHUB_REF_NAME is required}"
PRIVATE_KEY="${SPARKLE_PRIVATE_KEY:?SPARKLE_PRIVATE_KEY is required}"
RELEASE_NOTES="$PROJECT_DIR/dist/release-notes.md"

mkdir -p "$UPDATES_DIR"
cp "$PROJECT_DIR/dist/Ethernet-Menu-Bar.zip" "$UPDATES_DIR/Ethernet-Menu-Bar-$TAG.zip"

# Generate one set of notes for GitHub/Latest and Sparkle. Matching the archive
# basename lets generate_appcast attach the Markdown notes to this update.
gh api --method POST "repos/Allen-Jacob/Ethernet-Menu-Bar/releases/generate-notes" \
    -f tag_name="$TAG" \
    -f target_commitish="${GITHUB_SHA:?GITHUB_SHA is required}" \
    --jq '.body' > "$RELEASE_NOTES"
cp "$RELEASE_NOTES" "$UPDATES_DIR/Ethernet-Menu-Bar-$TAG.md"

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
    --release-notes-url-prefix "https://github.com/Allen-Jacob/Ethernet-Menu-Bar/releases/download/$TAG/" \
    --link "https://github.com/Allen-Jacob/Ethernet-Menu-Bar" \
    --maximum-versions 5 \
    --maximum-deltas 5 \
    "$UPDATES_DIR"

# Every Release exposes the full archive under the stable name used by the
# workflow. generate_appcast sees versioned local copies, so normalize those
# URLs back to the real asset belonging to each tag.
perl -0pi -e '
    s{https://github\.com/Allen-Jacob/Ethernet-Menu-Bar/releases/download/v[^/]+/Ethernet-Menu-Bar-v([0-9.]+)\.zip}{https://github.com/Allen-Jacob/Ethernet-Menu-Bar/releases/download/v$1/Ethernet-Menu-Bar.zip}g;
    s{Ethernet%20Menu%20Bar}{Ethernet-Menu-Bar}g;
' "$UPDATES_DIR/appcast.xml"

# GitHub rewrites spaces in uploaded asset names. Rename deltas ourselves so
# their filenames remain predictable and exactly match the normalized appcast.
find "$UPDATES_DIR" -maxdepth 1 -name 'Ethernet Menu Bar*.delta' -print0 |
while IFS= read -r -d '' delta; do
    renamed="${delta//Ethernet Menu Bar/Ethernet-Menu-Bar}"
    mv "$delta" "$renamed"
done
