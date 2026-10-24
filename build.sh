#!/bin/bash
# Builds BookAndQuill.app in this folder.
set -euo pipefail
cd "$(dirname "$0")"

swift build -c release
BIN="$(swift build -c release --show-bin-path)"
APP="BookAndQuill.app"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN/BookAndQuill" "$APP/Contents/MacOS/"
cp Support/Info.plist "$APP/Contents/"
# The font goes straight into Contents/Resources (MC.registerFont looks there first).
cp Sources/BookAndQuill/Resources/Monocraft.ttf Sources/BookAndQuill/Resources/Monocraft-OFL.txt "$APP/Contents/Resources/"

# App icon, rendered from the app's own pixel sprites.
BOOKANDQUILL_EXPORT_ICON="$WORK/icon.png" "$BIN/BookAndQuill"
ICONSET="$WORK/AppIcon.iconset"
mkdir -p "$ICONSET"
for size in 16 32 128 256 512; do
    sips -z $size $size "$WORK/icon.png" --out "$ICONSET/icon_${size}x${size}.png" >/dev/null
    sips -z $((size * 2)) $((size * 2)) "$WORK/icon.png" --out "$ICONSET/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"

codesign --force --sign - "$APP"
echo "Built $APP"
