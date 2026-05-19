#!/usr/bin/env bash
#
# Packages the built macOS app into a distributable, Developer-ID-signed,
# notarized DMG:
#   1. embeds the staged native dylibs into the .app's Contents/Frameworks/,
#   2. signs the bundle inside-out (every nested framework/dylib first, the app
#      last) with Developer ID + hardened runtime + a secure timestamp, applying
#      the Release entitlements to the app itself,
#   3. builds a drag-to-Applications DMG (create-dmg, hdiutil fallback) + signs it,
#   4. notarizes the DMG with notarytool and staples the ticket and
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
source "$REPO_ROOT/scripts/lib/common.sh"
source "$REPO_ROOT/scripts/lib/artifact_names.sh"

VERSION="${1:-${VERSION:?VERSION is required}}"
RUNNER_TEMP="${RUNNER_TEMP:-$(mktemp -d)}"
# Decoded signing material goes in scratch, which is ALWAYS removed on exit.
# RUNNER_TEMP is a throwaway on CI but a real /tmp dir locally and this script
# used to leave a decoded Developer ID .p12 and provisioning profile in it.
scratch_dir
SECRETS_DIR="$SCRATCH_DIR"
NATIVES="${NATIVES:-build/natives}"
DMG="$(release_asset_name dmg "$VERSION")"

APP="$(ls -d build/macos/Build/Products/Release/*.app | head -1)"
APP_NAME="$(basename "$APP" .app)"
echo "==> App bundle: $APP"

# 1. Embed the staged native dylibs.
#
# `no-queries`: unlike every other destination this dir gets the dylibs ONLY.
# codesign's default rules treat an app bundle's Contents/Frameworks/ as a
# nested-code location, so a tree-sitter .scm sitting beside the grammar libs
# fails the whole bundle signature with "code object is not signed at all ...
# In subcomponent: .../Contents/Frameworks/dart.scm" — after every nested
# framework has already been signed. The desktop reads the queries compiled
# into `embeddedTreeSitterQueries` instead; the cc_server bundle below, which is
# where indexing actually runs, still carries the on-disk copies.
mkdir -p "$APP/Contents/Frameworks"
shopt -s nullglob
stage_natives "$NATIVES" "$APP/Contents/Frameworks" dylib no-queries

# 1b. Embed the cc_server thin-client backend. The desktop is a thin client: at
# boot it spawns this binary (CcServerLauncher resolves
# Contents/Resources/cc_server/bin/cc_server, relative to the desktop exe) and
# talks to it over loopback RPC — it owns the database. Build the `dart build
# cli` bundle if absent, copy it under Resources and stage the native dylibs
# the server loads (libccpty for the agent PTY, rift/tree-sitter/etc.) into the
# server bundle's Frameworks so its @executable_path/../Frameworks loader finds
# them (the server is a SEPARATE executable from the desktop app).
#
# Whatever `builtin_credentials.sh inject` wrote is compiled in here, so that step
# has to precede this one (a bundle built earlier is reused as-is).
CC_SERVER_BUNDLE="$(ensure_cc_server_bundle macos)"
log "Embedding cc_server backend"
rm -rf "$APP/Contents/Resources/cc_server"
mkdir -p "$APP/Contents/Resources/cc_server"
cp -R "$CC_SERVER_BUNDLE/." "$APP/Contents/Resources/cc_server/"
stage_natives "$NATIVES" "$APP/Contents/Resources/cc_server/Frameworks" dylib

# 1c. Verify both native sets before signing. Every native is required (there is
# no degraded mode), so a bundle that is missing one either crashes the desktop's
# meeting recorder or refuses to boot its server — catch it here rather than
# shipping a notarized DMG that dies on first launch. The matrix lives in
# scripts/lib/natives.sh, pinned to the runtime table by
# test/tooling/native_matrix_test.dart.
bash scripts/release/verify_natives.sh "$APP/Contents/Frameworks" macos desktop
bash scripts/release/verify_natives.sh "$APP/Contents/Resources/cc_server/Frameworks" macos server

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
  KEYCHAIN="$SECRETS_DIR/build.keychain"
  echo "$MACOS_CERTIFICATE" | base64 --decode > "$SECRETS_DIR/cert.p12"
  security create-keychain -p actions "$KEYCHAIN"
  security set-keychain-settings -lut 21600 "$KEYCHAIN"
  security unlock-keychain -p actions "$KEYCHAIN"
  security import "$SECRETS_DIR/cert.p12" -k "$KEYCHAIN" -P "${MACOS_CERTIFICATE_PWD:-}" -T /usr/bin/codesign
  # shellcheck disable=SC2046  # deliberate: each existing keychain is its own arg.
  security list-keychains -d user -s "$KEYCHAIN" $(security list-keychains -d user | sed s/\"//g)
  security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k actions "$KEYCHAIN"
  # `|| true`: with no matching identity `grep` exits 1 and under `pipefail`
  # that aborts the script with NO message at all — swallowing the actionable
  # error immediately below.
  IDENTITY="$(security find-identity -v -p codesigning "$KEYCHAIN" | grep "Developer ID Application" | head -1 | awk '{print $2}' || true)"
  test -n "$IDENTITY" || { echo "ERROR: no 'Developer ID Application' identity in the imported cert."; exit 1; }
else
  # See the `|| true` note above: an empty result must reach the checks below,
  # not kill the script silently.
  IDENTITY="$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -1 | awk '{print $2}' || true)"
  # ALLOW_UNSIGNED is a LOCAL dry-run escape hatch (scripts/release/dry_run.sh
  # --skip-sign), never a release path: refuse it under GitHub Actions so it can
  # never quietly turn a real release unsigned. This is the only way to package
  # without a Developer ID and it produces an artifact nothing will notarize.
  if [ -z "$IDENTITY" ] && [ -n "${ALLOW_UNSIGNED:-}" ]; then
    [ -z "${GITHUB_ACTIONS:-}" ] \
      || die "ALLOW_UNSIGNED is a local dry-run flag; a CI release is never unsigned."
    warn "ALLOW_UNSIGNED=1 — packaging without Developer ID. The DMG will NOT be signed, notarized, or stapled and Gatekeeper will block it. Local verification only."
    SKIP_SIGNING=1
  fi
  test -n "$IDENTITY" || [ "${SKIP_SIGNING:-0}" = "1" ] || { echo "ERROR: MACOS_CERTIFICATE unset and no 'Developer ID Application' identity in your keychain. Add one in Xcode > Settings > Accounts, or set MACOS_CERTIFICATE."; exit 1; }
fi
echo "==> Signing with $IDENTITY (hardened runtime, inside-out)"

# Under ALLOW_UNSIGNED (local dry run only — see the guard above) every signing
# call becomes a no-op, so the staging/verify/DMG path can still be exercised.
sign() {
  [ "${SKIP_SIGNING:-0}" = "1" ] && return 0
  codesign --force --options runtime --timestamp -s "$IDENTITY" "$@"
}

# 2a. Standalone dylibs in Frameworks/ (embedded natives + e.g. onnxruntime / sherpa-onnx).
for f in "$APP/Contents/Frameworks/"*.dylib; do echo "  sign $(basename "$f")"; sign "$f"; done
# 2b. Nested .framework bundles (FlutterMacOS, App, Sentry, sqlite3, plugins, …).
#
# A framework can carry code of its own and signing the framework does NOT
# reach inside it. Sparkle 2 ships four such payloads —
# Sparkle.framework/Versions/B/{Autoupdate,Updater.app,XPCServices/*.xpc} — and
# the CocoaPods build leaves every one of them AD-HOC signed. That combination
# is invisible locally: `codesign --verify --deep --strict` (step 2e) accepts an
# ad-hoc signature, so the bundle verifies, the DMG builds and only the notary
# service objects — 15 minutes later, as a bare `status: Invalid` naming no file.
#
# So sign a framework's own code first, deepest path first (`find -depth` emits
# a nested bundle before the one containing it), then the framework itself.
sign_nested_code() { # framework
  local fw="$1" fw_name target rel
  fw_name="$(basename "$fw" .framework)"

  # Loose helper Mach-Os (Sparkle's `Autoupdate`). Skips anything inside a
  # nested bundle — signing that bundle covers its executable — and the
  # framework's own binary, which signing the framework covers.
  while IFS= read -r target; do
    rel="${target#"$fw"/}"
    case "$rel" in *.app/*|*.xpc/*|*.framework/*) continue ;; esac
    [ "$(basename "$target")" = "$fw_name" ] && continue
    file -b "$target" | grep -q 'Mach-O' || continue
    echo "  sign $fw_name/$rel"
    sign "$target"
  done < <(find "$fw" -type f \( -perm -u+x -o -name '*.dylib' \))

  # Nested bundles (.app / .xpc / a framework inside a framework), innermost
  # first. `-depth` is what orders them; the framework itself is excluded
  # because the caller signs it immediately after.
  while IFS= read -r target; do
    [ "$target" = "$fw" ] && continue
    echo "  sign $fw_name/${target#"$fw"/}"
    sign "$target"
  done < <(find "$fw" -depth -type d \( -name '*.app' -o -name '*.xpc' -o -name '*.framework' \))
}
for fw in "$APP/Contents/Frameworks/"*.framework; do
  sign_nested_code "$fw"
  echo "  sign $(basename "$fw")"; sign "$fw"
done
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
# The Dart AOT executable maps its embedded snapshot as executable memory, so
# under the hardened runtime it MUST carry the allow-unsigned-executable-memory
# exception. Signed bare it notarizes fine and is then SIGKILLed (CODESIGNING:
# Invalid Page) on every launch — which presents as the desktop sitting in the
# Dock with no window, waiting forever on a server that can never start. See
# scripts/release/entitlements/cc_server.entitlements.
if [ -f "$APP/Contents/Resources/cc_server/bin/cc_server" ]; then
  echo "  sign cc_server/bin/cc_server (dart-aot entitlements)"
  [ "${SKIP_SIGNING:-0}" = "1" ] || codesign --force --options runtime --timestamp \
    --entitlements scripts/release/entitlements/cc_server.entitlements \
    -s "$IDENTITY" "$APP/Contents/Resources/cc_server/bin/cc_server"
fi
# 2d. Embed the Developer ID provisioning profile so the app's restricted
# entitlements (keychain-access-groups) are authorized. Without it, MDM-managed
# Macs refuse to launch the app: taskgated/ManagedClient logs "Unsatisfied
# entitlements: keychain-access-groups -> Disallowing". MUST land before the app
# is signed so codesign seals it into the bundle. Source order: explicit path,
# base64 secret (CI), then the committed default.
PROFILE_SRC="${MACOS_PROVISIONING_PROFILE:-}"
if [ -z "$PROFILE_SRC" ] && [ -n "${MACOS_PROVISIONING_PROFILE_BASE64:-}" ]; then
  echo "$MACOS_PROVISIONING_PROFILE_BASE64" | base64 --decode > "$SECRETS_DIR/embedded.provisionprofile"
  PROFILE_SRC="$SECRETS_DIR/embedded.provisionprofile"
fi
[ -z "$PROFILE_SRC" ] && PROFILE_SRC="macos/Control_Center__macOS.provisionprofile"
if [ "${SKIP_SIGNING:-0}" = "1" ]; then PROFILE_SRC=""; fi
if [ -n "$PROFILE_SRC" ]; then
  test -f "$PROFILE_SRC" || { echo "ERROR: provisioning profile not found at '$PROFILE_SRC' (set MACOS_PROVISIONING_PROFILE or MACOS_PROVISIONING_PROFILE_BASE64)."; exit 1; }
  echo "==> Embedding provisioning profile: $PROFILE_SRC"
  cp "$PROFILE_SRC" "$APP/Contents/embedded.provisionprofile"
fi

# 2e. The app bundle last, carrying the Release entitlements.
if [ "${SKIP_SIGNING:-0}" != "1" ]; then
  codesign --force --options runtime --timestamp \
    --entitlements macos/Runner/Release.entitlements -s "$IDENTITY" "$APP"

  # Strict verification (fatal — a bad signature must fail the release).
  codesign --verify --deep --strict --verbose=2 "$APP"

  # 2f. What --verify does NOT catch. It accepts an ad-hoc signature and says
  # nothing about the hardened runtime, so a bundle can pass every check above
  # and still come back from the notary service as `status: Invalid` — the exact
  # failure Sparkle's four ad-hoc payloads produced. Enumerate every Mach-O the
  # notary service will look at and hold it to the rule it applies: signed with
  # our Developer ID (never ad-hoc), hardened runtime on. Fails in a second here
  # instead of after a 15-minute round trip and names the file, which the
  # notary summary does not.
  echo "==> Verifying every embedded Mach-O is Developer-ID signed + hardened"
  BAD_CODE=""
  while IFS= read -r macho; do
    file -b "$macho" | grep -q 'Mach-O' || continue
    # `|| true`: an UNSIGNED binary — the loudest thing this check exists to
    # find — makes `codesign -d` exit 1 and under pipefail that would abort the
    # script here with no output at all instead of reaching the report below.
    FLAGS="$(codesign -d --verbose=2 "$macho" 2>&1 |
      sed -n 's/^CodeDirectory .*flags=[^(]*(\([^)]*\)).*/\1/p' | head -1 || true)"
    case ",$FLAGS," in
      *,adhoc,*) BAD_CODE="$BAD_CODE
  ad-hoc signed:        ${macho#"$APP"/}" ;;
      *runtime*) ;;
      *) BAD_CODE="$BAD_CODE
  no hardened runtime:  ${macho#"$APP"/} (flags: ${FLAGS:-unsigned})" ;;
    esac
  done < <(find "$APP" -type f \( -perm -u+x -o -name '*.dylib' \))
  [ -z "$BAD_CODE" ] || die "the notary service will reject this bundle:$BAD_CODE

Every nested Mach-O must be signed with the Developer ID identity under the
hardened runtime. Something is embedding code the signing pass above does not
reach — extend it rather than relaxing this check."
  log "All embedded Mach-Os are Developer-ID signed + hardened"
fi

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
[ "${SKIP_SIGNING:-0}" = "1" ] || codesign --force --timestamp -s "$IDENTITY" "$DMG"

# 4. Notarize + staple (required). Prefer a stored notarytool keychain profile
# (NOTARY_PROFILE) — keeps the app-specific password out of the environment —
# otherwise fall back to Apple-ID credentials (CI).
if [ "${SKIP_SIGNING:-0}" = "1" ]; then
  warn "ALLOW_UNSIGNED — skipping notarization + stapling; this DMG is not distributable."
else
  echo "==> Notarizing $DMG"
  if [ -n "${NOTARY_PROFILE:-}" ]; then
    NOTARY_AUTH=(--keychain-profile "$NOTARY_PROFILE")
  else
    : "${APPLE_ID:?APPLE_ID (or NOTARY_PROFILE) is required for notarization}"
    NOTARY_AUTH=(--apple-id "$APPLE_ID" --team-id "${APPLE_TEAM_ID:?}" --password "${APPLE_APP_PASSWORD:?}")
  fi

  # `notarytool submit --wait` EXITS 0 on `status: Invalid` — it reports that the
  # submission completed, not that it passed. Unchecked, the script walked on to
  # `stapler staple`, which failed with the thoroughly misleading
  #   CloudKit query for … failed due to "Record not found"
  #   The staple and validate action failed! Error 65.
  # for a DMG that had simply been rejected. Read the status and on anything
  # but Accepted print the notary log — the ONLY place that names the offending
  # binary and the reason.
  NOTARY_OUT="$SCRATCH_DIR/notarytool.txt"
  NOTARY_OK=1
  xcrun notarytool submit "$DMG" "${NOTARY_AUTH[@]}" --wait 2>&1 | tee "$NOTARY_OUT" || NOTARY_OK=0
  grep -q 'status: Accepted' "$NOTARY_OUT" || NOTARY_OK=0
  if [ "$NOTARY_OK" != 1 ]; then
    SUBMISSION_ID="$(sed -n 's/^ *id: *\([0-9a-fA-F-]\{36\}\) *$/\1/p' "$NOTARY_OUT" | head -1)"
    if [ -n "$SUBMISSION_ID" ]; then
      echo "==> Notary log for $SUBMISSION_ID"
      xcrun notarytool log "$SUBMISSION_ID" "${NOTARY_AUTH[@]}" || true
    fi
    die "notarization failed — see the notary log above (the DMG was NOT stapled)"
  fi

  xcrun stapler staple "$DMG"
  xcrun stapler validate "$DMG"
fi

# 5. Checksum.
sha256_sidecar "$DMG"
if [ "${SKIP_SIGNING:-0}" = "1" ]; then
  log "Done: $DMG (UNSIGNED — local verification only, not distributable)"
else
  log "Done: $DMG (signed + notarized + stapled)"
fi
