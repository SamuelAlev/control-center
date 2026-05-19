#!/usr/bin/env bash
#
# Packages the STANDALONE, self-hostable cc_server — the pure-Dart backend the
# web/phone thin clients dial — into a downloadable archive for one OS:
#
#   1. ensures the `dart build cli` bundle exists (builds it if absent),
#   2. copies it to a friendly-named dist dir and stages EVERY runtime native
#      (rift / fff / tree-sitter / pty / aec + sherpa-onnx + onnxruntime) into the
#      directory the resolver looks in for THIS OS, so a server no Flutter app
#      spawned can still load them (meeting transcription, code graph, agent PTY),
#   3. macOS only: Developer-ID signs every Mach-O inside-out + notarizes the zip
#      (stapling a loose CLI isn't supported, so first run uses online Gatekeeper),
#   4. archives (tar.gz on macOS/Linux, zip on Windows) + writes a SHA-256.
#
# This is the server counterpart to macos_package.sh / linux_package.sh, which
# EMBED a copy of cc_server inside the desktop app. Those leave the original
# `dart build cli` bundle untouched (they stage natives into their own copy), so
# this script copies the clean bundle and stages into the copy too.
#
# Where natives must land (matches packages/cc_natives/.../native_library.dart's
# `bundledLibraryCandidates` + sherpa_bindings.dart's `resolveSherpaLibraryDir`,
# both relative to the cc_server binary at `<bundle>/bin/cc_server`):
#   * macOS   — `<bundle>/Frameworks/`     (`@executable_path/../Frameworks`)
#   * Linux   — `<bundle>/bin/lib/`        (`<exeDir>/lib`)
#   * Windows — `<bundle>/bin/`            (beside the .exe)
# sherpa-onnx-c-api finds its onnxruntime sibling via its own @loader_path/rpath,
# so both MUST share that one directory.
#
# Environment (macOS signing/notarization — all optional; absent ⇒ unsigned):
#   MACOS_CERTIFICATE / MACOS_CERTIFICATE_PWD   base64 Developer ID .p12 (CI)
#   NOTARY_PROFILE                              stored notarytool profile (local)
#   APPLE_ID / APPLE_TEAM_ID / APPLE_APP_PASSWORD   notarytool credentials (CI)
#   NATIVES                                     staged-natives dir (default build/natives)
#
# Usage:
#   scripts/release/cc_server_package.sh <version> [macos|linux|windows]
#   (OS defaults to the host's `uname`.)
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

VERSION="${1:?usage: cc_server_package.sh <version> [os]}"

# Resolve the target OS (arg 2, else the host).
OS="${2:-}"
if [ -z "$OS" ]; then
  case "$(uname -s)" in
    Darwin) OS=macos ;;
    Linux)  OS=linux ;;
    *)      OS=windows ;;
  esac
fi

# Per-OS layout: the `dart build cli` arch dir, the native file extension, the
# resolver-relative dir natives are staged into, and the archive format.
case "$OS" in
  macos)   ARCH=arm64; CLI_DIR=macos_arm64;   LIBEXT=dylib; STAGE_REL=Frameworks; FMT=tar ;;
  linux)   ARCH=x64;   CLI_DIR=linux_x64;     LIBEXT=so;    STAGE_REL=bin/lib;    FMT=tar ;;
  windows) ARCH=x64;   CLI_DIR=windows_x64;   LIBEXT=dll;   STAGE_REL=bin;        FMT=zip ;;
  *) echo "ERROR: unknown OS '$OS' (expected macos|linux|windows)"; exit 2 ;;
esac

NATIVES="${NATIVES:-build/natives}"
BUNDLE="apps/cc_server/build/cli/$CLI_DIR/bundle"
NAME="cc_server-${VERSION}-${OS}-${ARCH}"
DIST="dist/$NAME"

echo "==> Packaging standalone cc_server: $NAME"

# 1. Ensure the `dart build cli` bundle exists. macos_package.sh / linux_package.sh
# / the Windows job already built it; this guard covers a standalone run.
if [ ! -e "$BUNDLE/bin/cc_server" ] && [ ! -e "$BUNDLE/bin/cc_server.exe" ]; then
  echo "==> Building cc_server cli bundle"
  # Prefer the repo's fvm SDK (local), fall back to PATH `dart` (CI's flutter-action SDK).
  DART_BIN="$REPO_ROOT/.fvm/flutter_sdk/bin/dart"
  [ -x "$DART_BIN" ] || DART_BIN="$(command -v dart)"
  ( cd apps/cc_server && "$DART_BIN" build cli )
fi
test -d "$BUNDLE" || { echo "ERROR: cc_server bundle not found at $BUNDLE"; exit 1; }

# 2. Copy the clean bundle to the dist dir, then stage natives into the resolver
# dir so the original `dart build cli` output stays pristine for any later reuse.
rm -rf "$DIST"
mkdir -p "$DIST"
cp -R "$BUNDLE/." "$DIST/"

STAGE="$DIST/$STAGE_REL"
mkdir -p "$STAGE"
echo "==> Staging natives into $STAGE_REL/"
shopt -s nullglob
copied=0
for f in "$NATIVES"/*."$LIBEXT"; do
  echo "  + $(basename "$f")"
  cp -f "$f" "$STAGE/"
  copied=$((copied + 1))
done
[ "$copied" -gt 0 ] || echo "::warning::no *.$LIBEXT natives in $NATIVES — code graph / PTY / AEC degrade on this server"
# Tree-sitter `.scm` queries travel with the grammar libs — GrammarManager
# resolves a language's query from the same dir as its lib (see loadQuery), so
# stage them beside the natives or the standalone server can't index code.
for q in "$NATIVES"/*.scm; do
  echo "  + $(basename "$q")"
  cp -f "$q" "$STAGE/"
done
# sherpa-onnx + onnxruntime (prebuilt, pulled from the pub-cache plugin) into the
# SAME dir, so the c-api finds onnxruntime via its rpath and meeting transcription
# works on the standalone server. Best-effort (warns + skips if unavailable).
bash scripts/natives/bundle_sherpa_onnx.sh "$STAGE" || \
  echo "::warning::sherpa/onnx staging failed — meeting transcription unavailable on this server"

# 3. macOS: Developer-ID sign every Mach-O inside-out, then notarize the zip.
# Best-effort: with no identity (a fork / dry-run without secrets) ship unsigned —
# matches the Windows installer's conditional signing.
if [ "$OS" = macos ]; then
  RUNNER_TEMP="${RUNNER_TEMP:-$(mktemp -d)}"
  # Resolve a Developer ID Application identity. In the release job macos_package.sh
  # already imported the cert into a keychain on the search list, so find-identity
  # sees it; otherwise (standalone, with MACOS_CERTIFICATE) import it ourselves.
  IDENTITY="$(security find-identity -v -p codesigning 2>/dev/null | grep "Developer ID Application" | head -1 | awk '{print $2}' || true)"
  if [ -z "$IDENTITY" ] && [ -n "${MACOS_CERTIFICATE:-}" ]; then
    KEYCHAIN="$RUNNER_TEMP/cc_server.keychain"
    echo "$MACOS_CERTIFICATE" | base64 --decode > "$RUNNER_TEMP/cc_server_cert.p12"
    security create-keychain -p actions "$KEYCHAIN" 2>/dev/null || true
    security set-keychain-settings -lut 21600 "$KEYCHAIN"
    security unlock-keychain -p actions "$KEYCHAIN"
    security import "$RUNNER_TEMP/cc_server_cert.p12" -k "$KEYCHAIN" -P "${MACOS_CERTIFICATE_PWD:-}" -T /usr/bin/codesign
    # Intentional word-splitting: prepend our keychain to the existing search
    # list, each path a separate arg (mirrors macos_package.sh).
    # shellcheck disable=SC2046
    security list-keychains -d user -s "$KEYCHAIN" $(security list-keychains -d user | sed s/\"//g)
    security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k actions "$KEYCHAIN" >/dev/null 2>&1 || true
    IDENTITY="$(security find-identity -v -p codesigning "$KEYCHAIN" | grep "Developer ID Application" | head -1 | awk '{print $2}' || true)"
  fi

  if [ -n "$IDENTITY" ]; then
    echo "==> Signing cc_server with $IDENTITY (hardened runtime, inside-out)"
    sign() { codesign --force --options runtime --timestamp -s "$IDENTITY" "$@"; }
    # Dylibs first (Frameworks/ natives + sherpa/onnx, and the bundled libsqlite3
    # under lib/), the executable last — notarization rejects any unsigned Mach-O.
    for f in "$DIST/Frameworks/"*.dylib "$DIST/lib/"*.dylib; do
      [ -e "$f" ] || continue
      echo "  sign $(basename "$f")"; sign "$f"
    done
    echo "  sign bin/cc_server"; sign "$DIST/bin/cc_server"

    # Notarize the zipped bundle. Prefer a stored notarytool keychain profile,
    # else Apple-ID credentials. Skip (with a warning) when neither is present.
    ZIP="$RUNNER_TEMP/$NAME.zip"
    ( cd "$DIST" && zip -qry "$ZIP" . )
    if [ -n "${NOTARY_PROFILE:-}" ]; then
      echo "==> Notarizing (keychain profile)"
      xcrun notarytool submit "$ZIP" --keychain-profile "$NOTARY_PROFILE" --wait
    elif [ -n "${APPLE_ID:-}" ]; then
      echo "==> Notarizing (apple-id)"
      xcrun notarytool submit "$ZIP" \
        --apple-id "$APPLE_ID" --team-id "${APPLE_TEAM_ID:?}" --password "${APPLE_APP_PASSWORD:?}" --wait
    else
      echo "::warning::no NOTARY_PROFILE/APPLE_ID — cc_server signed but NOT notarized (first run needs a Gatekeeper override)"
    fi
    # A loose CLI / its zip cannot be stapled (stapler only handles .app/.dmg/.pkg),
    # so notarization is verified online at first launch — documented in release notes.
  else
    echo "::warning::no Developer ID identity (and no MACOS_CERTIFICATE) — shipping cc_server UNSIGNED"
  fi
fi

# 4. Archive + checksum.
mkdir -p dist
if [ "$FMT" = tar ]; then
  ARCHIVE="$NAME.tar.gz"
  tar czf "$ARCHIVE" -C dist "$NAME"
else
  ARCHIVE="$NAME.zip"
  rm -f "$ARCHIVE"
  # windows-latest ships 7-Zip; fall back to PowerShell, then `zip`.
  if command -v 7z >/dev/null 2>&1; then
    ( cd dist && 7z a -tzip -bso0 "../$ARCHIVE" "./$NAME" >/dev/null )
  elif command -v powershell >/dev/null 2>&1; then
    powershell -NoProfile -Command "Compress-Archive -Path 'dist/$NAME/*' -DestinationPath '$ARCHIVE' -Force"
  else
    ( cd dist && zip -qry "../$ARCHIVE" "$NAME" )
  fi
fi

if command -v sha256sum >/dev/null 2>&1; then
  sha256sum "$ARCHIVE" | tee "$ARCHIVE.sha256"
else
  shasum -a 256 "$ARCHIVE" | tee "$ARCHIVE.sha256"
fi
echo "==> Done: $ARCHIVE"
