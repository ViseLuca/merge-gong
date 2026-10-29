#!/bin/sh
# Builds build/Merge Gong.app (universal, macOS 13+).
#   ./build.sh          build only
#   ./build.sh install  build, copy into /Applications and relaunch
#   ./build.sh dist 1.2.0  build version 1.2.0 and zip it into build/MergeGong.zip, ready for a release
#   ./build.sh test     run the tests
#   ./build.sh icon     redraw Resources/AppIcon.icns from scripts/make-icon.swift
set -eu
cd "$(dirname "$0")"

# SwiftPM's default build system needs a full Xcode; the native one works with the Command Line Tools alone.
SWIFT_BUILD="swift build -c release --build-system native"

if [ "${1:-}" = test ]; then
  # With only the Command Line Tools, swift-testing lives outside the default search paths.
  FW=/Library/Developer/CommandLineTools/Library/Developer/Frameworks
  LIB=/Library/Developer/CommandLineTools/Library/Developer/usr/lib
  exec swift test --build-system native \
    -Xswiftc -F -Xswiftc "$FW" -Xlinker -F -Xlinker "$FW" \
    -Xlinker -rpath -Xlinker "$FW" -Xlinker -rpath -Xlinker "$LIB"
fi

if [ "${1:-}" = icon ]; then
  SET="$(mktemp -d)/AppIcon.iconset"
  mkdir -p "$SET" Resources
  swift scripts/make-icon.swift "$SET/icon_512x512@2x.png"
  for PX in 16 32 128 256 512; do
    sips -z "$PX" "$PX" "$SET/icon_512x512@2x.png" --out "$SET/icon_${PX}x${PX}.png" >/dev/null
    [ "$PX" = 512 ] || sips -z $((PX * 2)) $((PX * 2)) "$SET/icon_512x512@2x.png" --out "$SET/icon_${PX}x${PX}@2x.png" >/dev/null
  done
  iconutil -c icns "$SET" -o Resources/AppIcon.icns
  echo "Drawn Resources/AppIcon.icns"
  exit
fi

# The version the app reports, which the updater compares with the GitHub release tags.
# Local builds take the latest tag; a release names its own, as its tag does not exist yet.
if [ "${1:-}" = dist ]; then
  VERSION="${2:?usage: ./build.sh dist <version>, e.g. ./build.sh dist 1.0.4}"
else
  VERSION="$(git describe --tags --abbrev=0 2>/dev/null || echo 0.0.0)"
fi
VERSION="${VERSION#v}"

APP="build/Merge Gong.app"
BIN="$APP/Contents/MacOS/MergeGong"
mkdir -p "$APP/Contents/MacOS"

# Without an explicit target the build is for the host macOS only, so older Macs could not open it.
for ARCH in arm64 x86_64; do
  $SWIFT_BUILD --product MergeGong --triple "$ARCH-apple-macosx13.0"
done
lipo -create \
  "$($SWIFT_BUILD --triple arm64-apple-macosx13.0 --show-bin-path)/MergeGong" \
  "$($SWIFT_BUILD --triple x86_64-apple-macosx13.0 --show-bin-path)/MergeGong" \
  -output "$BIN"

cp Info.plist "$APP/Contents/Info.plist"
mkdir -p "$APP/Contents/Resources"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" -c "Set :CFBundleVersion $VERSION" "$APP/Contents/Info.plist"
codesign --force --sign - "$APP"
# The bundle folder keeps the date it was first created, and Finder caches the icon by it.
touch "$APP"
echo "Built $APP $VERSION"

case "${1:-}" in
  install)
    # The same place the downloaded app goes, so there is only ever one copy; quit it so the new build runs.
    osascript -e 'quit app id "io.github.viseluca.merge-gong"' 2>/dev/null || true
    ditto "$APP" "/Applications/Merge Gong.app"
    echo "Installed in /Applications/Merge Gong.app"
    open "/Applications/Merge Gong.app"
    ;;
  dist)
    ditto -c -k --keepParent "$APP" build/MergeGong.zip
    echo "Ready to share: build/MergeGong.zip"
    echo "Publish it with: gh release create $VERSION build/MergeGong.zip"
    ;;
esac
