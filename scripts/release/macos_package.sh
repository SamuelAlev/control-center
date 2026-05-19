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
#   MACOS_CERTIFICATE       base64 Developer ID Application .p12 (CI). If unset,
#                           the installed login-keychain identity is used (local).
#   MACOS_CERTIFICATE_PWD   password for the .p12
#   MACOS_PROVISIONING_PROFILE        path to the Developer ID .provisionprofile
#                           (defaults to macos/Control_Center__macOS.provisionprofile)
#   MACOS_PROVISIONING_PROFILE_BASE64 base64 of the profile (CI alternative)
#   NOTARY_PROFILE          stored notarytool keychain profile name (local), OR
#   APPLE_ID / APPLE_TEAM_ID / APPLE_APP_PASSWORD   notarytool credentials (CI)
#
# Usage:
#   CI:    VERSION=1.0.0 MACOS_CERTIFICATE=... APPLE_ID=... scripts/release/macos_package.sh
#   Local: VERSION=1.0.0 NOTARY_PROFILE=control-center scripts/release/macos_package.sh
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
# Tree-sitter `.scm` queries beside the grammar dylibs — GrammarManager resolves
# each language's query from the same dir as its lib (see loadQuery).
for q in "$NATIVES"/*.scm; do
  echo "  embedding $(basename "$q")"
  cp -f "$q" "$APP/Contents/Frameworks/"
done

# 1b. Embed the cc_server thin-client backend. The desktop is a thin client: at
# boot it spawns this binary (CcServerLauncher resolves
# Contents/Resources/cc_server/bin/cc_server, relative to the desktop exe) and
# talks to it over loopback RPC — it owns the database. Build the `dart build
# cli` bundle if absent, copy it under Resources, and stage the native dylibs
# the server loads (libccpty for the agent PTY, rift/tree-sitter/etc.) into the
# server bundle's Frameworks so its @executable_path/../Frameworks loader finds
# them (the server is a SEPARATE executable from the desktop app).
CC_SERVER_BUNDLE="apps/cc_server/build/cli/macos_arm64/bundle"
if [ ! -x "$CC_SERVER_BUNDLE/bin/cc_server" ]; then
  echo "==> Building cc_server cli bundle"
  # Prefer the repo's fvm SDK (local), fall back to PATH `dart` (CI uses the
  # flutter-action SDK, no .fvm checkout).
  DART_BIN="$REPO_ROOT/.fvm/flutter_sdk/bin/dart"
  [ -x "$DART_BIN" ] || DART_BIN="$(command -v dart)"
  ( cd apps/cc_server && "$DART_BIN" build cli )
fi
echo "==> Embedding cc_server backend"
rm -rf "$APP/Contents/Resources/cc_server"
mkdir -p "$APP/Contents/Resources/cc_server/Frameworks"
cp -R "$CC_SERVER_BUNDLE/." "$APP/Contents/Resources/cc_server/"
for f in "$NATIVES"/*.dylib; do
  cp -f "$f" "$APP/Contents/Resources/cc_server/Frameworks/"
done
for q in "$NATIVES"/*.scm; do
  cp -f "$q" "$APP/Contents/Resources/cc_server/Frameworks/"
done

# 2. Sign — Developer ID + hardened runtime, inside-out.
#
# Notarization requires EVERY embedded Mach-O to be Developer-ID signed with a
# secure timestamp under the hardened runtime; ad-hoc nested code is rejected.
# So sign nested code first (frameworks, dylibs, helper binaries), then the app
# last with the entitlements. No --deep — it mis-applies entitlements and skips
# secure timestamps on nested code.
# Obtain the Developer ID Application identity. CI path: import the base64 .p12
# into a throwaway keychain. Local path: if MACOS_CERTIFICATE is unset, use the
# identity already in the login keychain, so a developer can package locally
# without exporting their cert.
if [ -n "${MACOS_CERTIFICATE:-}" ]; then
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
else
  IDENTITY="$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -1 | awk '{print $2}')"
  test -n "$IDENTITY" || { echo "ERROR: MACOS_CERTIFICATE unset and no 'Developer ID Application' identity in your keychain. Add one in Xcode > Settings > Accounts, or set MACOS_CERTIFICATE."; exit 1; }
fi
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
# 2c'. The cc_server backend: its native dylibs + the executable itself. Every
# nested Mach-O must carry a Developer-ID signature + secure timestamp under the
# hardened runtime, or notarization rejects the app. Sign the dylibs first, the
# binary last.
for f in "$APP/Contents/Resources/cc_server/Frameworks/"*.dylib \
         "$APP/Contents/Resources/cc_server/lib/"*.dylib; do
  echo "  sign cc_server/$(basename "$f")"; sign "$f"
done
if [ -f "$APP/Contents/Resources/cc_server/bin/cc_server" ]; then
  echo "  sign cc_server/bin/cc_server"
  sign "$APP/Contents/Resources/cc_server/bin/cc_server"
fi
# 2d. Embed the Developer ID provisioning profile so the app's restricted
# entitlements (keychain-access-groups) are authorized. Without it, MDM-managed
# Macs refuse to launch the app: taskgated/ManagedClient logs "Unsatisfied
# entitlements: keychain-access-groups -> Disallowing". MUST land before the app
# is signed so codesign seals it into the bundle. Source order: explicit path,
# base64 secret (CI), then the committed default.
PROFILE_SRC="${MACOS_PROVISIONING_PROFILE:-}"
if [ -z "$PROFILE_SRC" ] && [ -n "${MACOS_PROVISIONING_PROFILE_BASE64:-}" ]; then
  echo "$MACOS_PROVISIONING_PROFILE_BASE64" | base64 --decode > "$RUNNER_TEMP/embedded.provisionprofile"
  PROFILE_SRC="$RUNNER_TEMP/embedded.provisionprofile"
fi
[ -z "$PROFILE_SRC" ] && PROFILE_SRC="macos/Control_Center__macOS.provisionprofile"
test -f "$PROFILE_SRC" || { echo "ERROR: provisioning profile not found at '$PROFILE_SRC' (set MACOS_PROVISIONING_PROFILE or MACOS_PROVISIONING_PROFILE_BASE64)."; exit 1; }
echo "==> Embedding provisioning profile: $PROFILE_SRC"
cp "$PROFILE_SRC" "$APP/Contents/embedded.provisionprofile"

# 2e. The app bundle last, carrying the Release entitlements.
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

# 4. Notarize + staple (required). Prefer a stored notarytool keychain profile
# (NOTARY_PROFILE) — keeps the app-specific password out of the environment —
# otherwise fall back to Apple-ID credentials (CI).
echo "==> Notarizing $DMG"
if [ -n "${NOTARY_PROFILE:-}" ]; then
  xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait
else
  : "${APPLE_ID:?APPLE_ID (or NOTARY_PROFILE) is required for notarization}"
  xcrun notarytool submit "$DMG" \
    --apple-id "$APPLE_ID" --team-id "${APPLE_TEAM_ID:?}" --password "${APPLE_APP_PASSWORD:?}" --wait
fi
xcrun stapler staple "$DMG"
xcrun stapler validate "$DMG"

# 5. Checksum.
shasum -a 256 "$DMG" | tee "$DMG.sha256"
echo "==> Done: $DMG (signed + notarized + stapled)"
