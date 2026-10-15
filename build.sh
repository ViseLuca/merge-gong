#!/bin/sh
# Builds build/Merge Gong.app (universal, macOS 13+).
#   ./build.sh          build only
#   ./build.sh install  build and copy into ~/Applications
#   ./build.sh dist 1.2.0  build version 1.2.0 and zip it into build/MergeGong.zip, ready for a release
#   ./build.sh test     run the tests
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
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" -c "Set :CFBundleVersion $VERSION" "$APP/Contents/Info.plist"
codesign --force --sign - "$APP"
echo "Built $APP $VERSION"

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
    echo "Publish it with: gh release create $VERSION build/MergeGong.zip"
    ;;
esac
