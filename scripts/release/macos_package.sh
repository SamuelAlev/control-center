#!/usr/bin/env bash
#
# Packages the built macOS app into a distributable, Developer-ID-signed,
# notarized DMG:
#   1. embeds the staged native dylibs into the .app's Contents/Frameworks/,
#   2. signs the bundle inside-out (every nested framework/dylib first, the app
#      last) with Developer ID + hardened runtime + a secure timestamp, applying
#      the Release entitlements to the app itself,
#   3. builds a drag-to-Applications DMG (create-dmg, hdiutil fallback) + signs it,
#   4. notarizes the DMG with notarytool and staples the ticket, and
#   5. writes a SHA-256 checksum next to the DMG.
#
# Signing + notarization are REQUIRED — there is no unsigned fallback. Expects
# `flutter build macos --release` to have run and the native libs to be staged
# in build/natives/ (see scripts/natives/build_natives.sh).
#
# Environment:
#   VERSION                 release version, e.g. 1.0.0 (required; or pass as $1)
#   MACOS_CERTIFICATE       base64 Developer ID Application .p12 (required)
#   MACOS_CERTIFICATE_PWD   password for the .p12
#   APPLE_ID / APPLE_TEAM_ID / APPLE_APP_PASSWORD   notarytool credentials (required)
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
APP_NAME="$(basename "$APP" .app)"
echo "==> App bundle: $APP"

# 1. Embed the staged native dylibs.
mkdir -p "$APP/Contents/Frameworks"
shopt -s nullglob
for f in "$NATIVES"/*.dylib; do
  echo "  embedding $(basename "$f")"
  cp -f "$f" "$APP/Contents/Frameworks/"
done

# 2. Sign — Developer ID + hardened runtime, inside-out.
#
# Notarization requires EVERY embedded Mach-O to be Developer-ID signed with a
# secure timestamp under the hardened runtime; ad-hoc nested code is rejected.
# So sign nested code first (frameworks, dylibs, helper binaries), then the app
# last with the entitlements. No --deep — it mis-applies entitlements and skips
# secure timestamps on nested code.
: "${MACOS_CERTIFICATE:?MACOS_CERTIFICATE is required (base64 Developer ID .p12)}"
KEYCHAIN="$RUNNER_TEMP/build.keychain"
echo "$MACOS_CERTIFICATE" | base64 --decode > "$RUNNER_TEMP/cert.p12"
security create-keychain -p actions "$KEYCHAIN"
security set-keychain-settings -lut 21600 "$KEYCHAIN"
security unlock-keychain -p actions "$KEYCHAIN"
security import "$RUNNER_TEMP/cert.p12" -k "$KEYCHAIN" -P "${MACOS_CERTIFICATE_PWD:-}" -T /usr/bin/codesign
security list-keychains -d user -s "$KEYCHAIN" $(security list-keychains -d user | sed s/\"//g)
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k actions "$KEYCHAIN"
IDENTITY="$(security find-identity -v -p codesigning "$KEYCHAIN" | grep "Developer ID Application" | head -1 | awk '{print $2}')"
test -n "$IDENTITY" || { echo "ERROR: no 'Developer ID Application' identity in the imported cert."; exit 1; }
echo "==> Signing with $IDENTITY (hardened runtime, inside-out)"

sign() { codesign --force --options runtime --timestamp -s "$IDENTITY" "$@"; }

# 2a. Standalone dylibs in Frameworks/ (embedded natives + e.g. onnxruntime / sherpa-onnx).
for f in "$APP/Contents/Frameworks/"*.dylib; do echo "  sign $(basename "$f")"; sign "$f"; done
# 2b. Nested .framework bundles (FlutterMacOS, App, Sentry, sqlite3, plugins, …).
for fw in "$APP/Contents/Frameworks/"*.framework; do echo "  sign $(basename "$fw")"; sign "$fw"; done
# 2c. Helper executables alongside the main binary (defensive — none today).
for f in "$APP/Contents/MacOS/"*; do
  [ "$f" = "$APP/Contents/MacOS/$APP_NAME" ] && continue
  [ -f "$f" ] && { echo "  sign $(basename "$f")"; sign "$f"; }
done
# 2d. The app bundle last, carrying the Release entitlements.
codesign --force --options runtime --timestamp \
  --entitlements macos/Runner/Release.entitlements -s "$IDENTITY" "$APP"

# Strict verification (fatal — a bad signature must fail the release).
codesign --verify --deep --strict --verbose=2 "$APP"

# 3. Build the DMG, then sign it.
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
codesign --force --timestamp -s "$IDENTITY" "$DMG"

# 4. Notarize + staple (required).
: "${APPLE_ID:?APPLE_ID is required for notarization}"
echo "==> Notarizing $DMG"
xcrun notarytool submit "$DMG" \
  --apple-id "$APPLE_ID" --team-id "${APPLE_TEAM_ID:?}" --password "${APPLE_APP_PASSWORD:?}" --wait
xcrun stapler staple "$DMG"
xcrun stapler validate "$DMG"

# 5. Checksum.
shasum -a 256 "$DMG" | tee "$DMG.sha256"
echo "==> Done: $DMG (signed + notarized + stapled)"
