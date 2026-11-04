#!/usr/bin/env bash
# Installs (or updates) Merge Gong from the latest GitHub release:
#   curl -fsSL https://raw.githubusercontent.com/ViseLuca/merge-gong/main/scripts/install.sh | bash
# Files downloaded with curl carry no quarantine flag, so Gatekeeper does not block the unnotarized app.
# Installs into /Applications, or ~/Applications when /Applications is not writable.
set -euo pipefail

REPO="ViseLuca/merge-gong"
ASSET="MergeGong.zip"
APP_NAME="Merge Gong.app"
BUNDLE_ID="io.github.viseluca.merge-gong"
MIN_MACOS=13

fail() { printf '\n❌ %s\n' "$1" >&2; exit 1; }

# Everything runs from main(), called on the last line: if the download of this script stops halfway, bash runs nothing.
main() {
  [[ "$(uname -s)" == Darwin ]] || fail "Merge Gong funziona solo su macOS."
  local macos
  macos="$(sw_vers -productVersion)"
  (( ${macos%%.*} >= MIN_MACOS )) || fail "Serve macOS $MIN_MACOS o successivo (questo Mac ha $macos)."

  # Global, not local: the EXIT trap runs after main() has returned.
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT

  echo "Cerco l'ultima versione…"
  curl -fsSL -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/$REPO/releases/latest" -o "$tmp/release.json" \
    || fail "Non riesco a contattare GitHub. Controlla la connessione e riprova."

  local version url="" digest="" count i
  version="$(plutil -extract tag_name raw -o - "$tmp/release.json")"
  count="$(plutil -extract assets raw -o - "$tmp/release.json")"
  for (( i = 0; i < count; i++ )); do
    if [[ "$(plutil -extract "assets.$i.name" raw -o - "$tmp/release.json")" == "$ASSET" ]]; then
      url="$(plutil -extract "assets.$i.browser_download_url" raw -o - "$tmp/release.json")"
      digest="$(plutil -extract "assets.$i.digest" raw -o - "$tmp/release.json" 2>/dev/null || true)"
      break
    fi
  done
  [[ -n "$url" ]] || fail "La release $version non contiene $ASSET."

  echo "Scarico Merge Gong ${version}…"
  curl -fL --progress-bar "$url" -o "$tmp/$ASSET" || fail "Download non riuscito."

  if [[ "$digest" == sha256:* ]]; then
    [[ "$(shasum -a 256 "$tmp/$ASSET" | cut -d' ' -f1)" == "${digest#sha256:}" ]] \
      || fail "Il file scaricato è corrotto (checksum diverso). Riprova."
  fi

  ditto -x -k "$tmp/$ASSET" "$tmp/unzipped"
  local app="$tmp/unzipped/$APP_NAME"
  [[ -d "$app" ]] || fail "Lo zip non contiene $APP_NAME."
  [[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app/Contents/Info.plist")" == "$BUNDLE_ID" ]] \
    || fail "Lo zip contiene un'altra app."
  codesign --verify --deep --strict "$app" 2>/dev/null || fail "La firma dell'app non è valida."

  local dir="/Applications"
  [[ -w "$dir" ]] || { dir="$HOME/Applications"; mkdir -p "$dir"; }
  local dest="$dir/$APP_NAME"

  osascript -e "quit app id \"$BUNDLE_ID\"" >/dev/null 2>&1 || true
  # The old copy goes into the temp folder, deleted on exit; the new one replaces it whole, with no leftover files.
  if [[ -e "$dest" ]]; then
    mv "$dest" "$tmp/old.app" || fail "Non riesco a sostituire $dest."
  fi
  if ! mv "$app" "$dest"; then
    [[ -e "$tmp/old.app" ]] && mv "$tmp/old.app" "$dest"
    fail "Non riesco a copiare l'app in $dir."
  fi
  xattr -dr com.apple.quarantine "$dest" 2>/dev/null || true
  # Finder caches the icon by the bundle folder's date.
  touch "$dest"

  echo "✅ Merge Gong $version installato in $dest"
  open "$dest"
  echo "Trovi la 🔔 nella barra dei menu, in alto a destra."
}

main "$@"
