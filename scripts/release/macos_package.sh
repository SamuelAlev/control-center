#!/usr/bin/env bash
#
# Packages the built macOS app into a distributable, ad-hoc-signed DMG:
#   1. embeds the staged native dylibs into the .app's Contents/Frameworks/,
#   2. signs (Developer ID + hardened runtime when secrets are present, else
#      ad-hoc, re-sealing WITH the Release entitlements),
#   3. builds a drag-to-Applications DMG (create-dmg, hdiutil fallback),
#   4. notarizes + staples when Apple secrets are present, and
#   5. writes a SHA-256 checksum next to the DMG.
#
# Expects `flutter build macos --release` to have run and the native libs to be
# staged in build/natives/ (see scripts/build_natives.sh).
#
# Environment:
#   VERSION                 release version, e.g. 1.0.0 (required; or pass as $1)
#   MACOS_CERTIFICATE       base64 Developer ID .p12 (optional → ad-hoc signing)
#   MACOS_CERTIFICATE_PWD   password for the .p12
#   APPLE_ID / APPLE_TEAM_ID / APPLE_APP_PASSWORD   notarytool credentials
#
# Usage:
#   VERSION=1.0.0 scripts/release/macos_package.sh
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

VERSION="${1:-${VERSION:?VERSION is required}}"
RUNNER_TEMP="${RUNNER_TEMP:-$(mktemp -d)}"
NATIVES="${NATIVES:-build/natives}"
DMG="Control-Center-${VERSION}-arm64.dmg"

APP="$(ls -d build/macos/Build/Products/Release/*.app | head -1)"
echo "==> App bundle: $APP"

# 1. Embed the staged native dylibs.
mkdir -p "$APP/Contents/Frameworks"
shopt -s nullglob
for f in "$NATIVES"/*.dylib; do
  echo "  embedding $(basename "$f")"
  cp -f "$f" "$APP/Contents/Frameworks/"
done

# 2. Sign.
if [ -n "${MACOS_CERTIFICATE:-}" ]; then
  echo "==> Developer ID secrets present — signing with hardened runtime."
  KEYCHAIN="$RUNNER_TEMP/build.keychain"
  echo "$MACOS_CERTIFICATE" | base64 --decode > "$RUNNER_TEMP/cert.p12"
  security create-keychain -p actions "$KEYCHAIN"
  security set-keychain-settings -lut 21600 "$KEYCHAIN"
  security unlock-keychain -p actions "$KEYCHAIN"
  security import "$RUNNER_TEMP/cert.p12" -k "$KEYCHAIN" -P "${MACOS_CERTIFICATE_PWD:-}" -T /usr/bin/codesign
  security list-keychains -d user -s "$KEYCHAIN" $(security list-keychains -d user | sed s/\"//g)
  security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k actions "$KEYCHAIN"
  IDENTITY=$(security find-identity -v -p codesigning "$KEYCHAIN" | grep "Developer ID Application" | head -1 | awk '{print $2}')
  for f in "$APP/Contents/Frameworks/"*.dylib; do
    codesign --force --options runtime --timestamp -s "$IDENTITY" "$f"
  done
  codesign --force --options runtime --timestamp \
    --entitlements macos/Runner/Release.entitlements -s "$IDENTITY" "$APP"
else
  echo "==> No Developer ID secrets — ad-hoc signing (Gatekeeper will warn; right-click → Open)."
  for f in "$APP/Contents/Frameworks/"*.dylib; do
    codesign --force -s - "$f"
  done
  # Re-seal WITH entitlements (no --deep — that would strip the sandbox/keychain/network entitlements).
  codesign --force -s - --entitlements macos/Runner/Release.entitlements "$APP"
fi
codesign --verify --verbose=2 "$APP" || true

# 3. Build the DMG.
echo "==> Building $DMG"
rm -rf dist/dmg-src && mkdir -p dist/dmg-src
cp -R "$APP" dist/dmg-src/
create-dmg \
  --volname "Control Center" \
  --window-size 660 420 \
  --icon-size 120 \
  --icon "$(basename "$APP")" 165 200 \
  --app-drop-link 495 200 \
  "$DMG" "dist/dmg-src" || true
if [ ! -f "$DMG" ]; then
  echo "create-dmg did not produce a DMG — falling back to hdiutil."
  ln -sf /Applications dist/dmg-src/Applications
  hdiutil create -volname "Control Center" -srcfolder dist/dmg-src -ov -format UDZO "$DMG"
fi
test -f "$DMG"

# 4. Notarize + staple (only when Apple secrets are present).
if [ -n "${MACOS_CERTIFICATE:-}" ] && [ -n "${APPLE_ID:-}" ]; then
  echo "==> Notarizing $DMG"
  xcrun notarytool submit "$DMG" \
    --apple-id "$APPLE_ID" --team-id "${APPLE_TEAM_ID:?}" --password "${APPLE_APP_PASSWORD:?}" --wait
  xcrun stapler staple "$DMG"
else
  echo "==> No Apple notarization secrets — DMG ships ad-hoc/unsigned by design."
fi

# 5. Checksum.
shasum -a 256 "$DMG" | tee "$DMG.sha256"
echo "==> Done: $DMG"
