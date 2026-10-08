#!/bin/sh
# Builds build/Merge Gong.app (universal, macOS 13+).
#   ./build.sh          build only
#   ./build.sh install  build and copy into ~/Applications
#   ./build.sh dist     build and zip into build/MergeGong.zip, ready to share
set -eu
cd "$(dirname "$0")"

APP="build/Merge Gong.app"
BIN="$APP/Contents/MacOS/MergeGong"
mkdir -p "$APP/Contents/MacOS"

# Without an explicit target swiftc builds for the host macOS only, so older Macs could not open it.
swiftc -O -swift-version 5 -target arm64-apple-macos13 -o build/MergeGong-arm64 Sources/main.swift
swiftc -O -swift-version 5 -target x86_64-apple-macos13 -o build/MergeGong-x86_64 Sources/main.swift
lipo -create build/MergeGong-arm64 build/MergeGong-x86_64 -output "$BIN"

cp Info.plist "$APP/Contents/Info.plist"
codesign --force --sign - "$APP"
echo "Built $APP"

case "${1:-}" in
  install)
    mkdir -p "$HOME/Applications"
    ditto "$APP" "$HOME/Applications/Merge Gong.app"
    echo "Installed in $HOME/Applications/Merge Gong.app"
    open "$HOME/Applications/Merge Gong.app"
    ;;
  dist)
    ditto -c -k --keepParent "$APP" build/MergeGong.zip
    echo "Ready to share: build/MergeGong.zip"
    ;;
esac
