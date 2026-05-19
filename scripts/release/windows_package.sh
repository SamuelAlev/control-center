#!/usr/bin/env bash
#
# Packages the built Windows app into a distributable installer + portable zip:
#   1. bundles the staged native DLLs (and the tree-sitter .scm queries) beside
#      the executable,
#   2. embeds the cc_server thin-client backend with its own native set,
#   3. verifies both native sets,
#   4. builds the Inno Setup installer and Authenticode-signs it when a cert is
#      present, and
#   5. writes the portable zip + SHA-256 sidecars.
#
# This is the Windows half of the macos_package.sh / linux_package.sh pair. It
# used to be ~80 lines inlined in release.yml, which meant Windows was the one
# platform whose packaging could not be run or reviewed outside GitHub Actions —
# and RELEASING.md restated it in prose as a fourth copy for exactly that reason.
#
# Expects `flutter build windows --release` to have run and the natives to be
# staged in build/natives (scripts/release/windows_natives.sh, or the verify
# gate fails).
#
# Environment:
#   VERSION           release version, e.g. 1.0.0 (required; or pass as $1)
#   NATIVES           staged natives dir (default: build/natives)
#   SKIP_INSTALLER    1 → skip Inno Setup (lets a box without ISCC still exercise
#                     staging + verify + zip, which is the reviewable 80%)
#   SKIP_ZIP          1 → skip the portable zip
#   WINDOWS_CERT      base64 Authenticode .pfx (absent ⇒ unsigned, as today)
#   WINDOWS_CERT_PWD  password for that .pfx
#
# Usage:
#   VERSION=1.0.0 scripts/release/windows_package.sh
#   SKIP_INSTALLER=1 VERSION=1.0.0 scripts/release/windows_package.sh
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"
source "$REPO_ROOT/scripts/lib/common.sh"
source "$REPO_ROOT/scripts/lib/artifact_names.sh"

VERSION="${1:-${VERSION:?VERSION is required}}"
NATIVES="${NATIVES:-build/natives}"
OUT="build/windows/x64/runner/Release"
SETUP="dist/$(release_asset_name win-setup "$VERSION")"
ZIP="dist/$(release_asset_name win-portable "$VERSION")"

[ -d "$OUT" ] || die "no Windows build at $OUT — run 'flutter build windows --release' first."
mkdir -p dist

# 1. Native DLLs beside the executable. (stage_natives also copies the
# tree-sitter .scm queries, which GrammarManager resolves from the same dir as
# each grammar lib.)
stage_natives "$NATIVES" "$OUT" dll

# 2. Embed the cc_server thin-client backend. The desktop spawns it at boot
# (CcServerLauncher resolves <exeDir>/cc_server/bin/cc_server.exe) and talks to
# it over loopback RPC — it owns the database. The installer's recursive [Files]
# glob over the Release dir picks it up.
#
# Whatever `builtin_credentials.sh inject` wrote is compiled in here, so that
# step has to precede this one (a bundle built earlier is reused as-is).
CC_SERVER_BUNDLE="$(ensure_cc_server_bundle windows)"
log "Embedding cc_server backend"
rm -rf "$OUT/cc_server"
mkdir -p "$OUT/cc_server"
cp -r "$CC_SERVER_BUNDLE/." "$OUT/cc_server/"
# Windows resolves a DLL beside the loading executable, so the server's natives
# go next to cc_server.exe rather than in a lib/ dir.
stage_natives "$NATIVES" "$OUT/cc_server/bin" dll

# 3. Verify both native sets before building an installer that would otherwise
# fail on the user's machine. The matrix lives in scripts/lib/natives.sh, pinned
# to the runtime table by test/tooling/native_matrix_test.dart.
bash scripts/release/verify_natives.sh "$OUT" windows desktop
bash scripts/release/verify_natives.sh "$OUT/cc_server/bin" windows server

# 4. Inno Setup installer.
if [ "${SKIP_INSTALLER:-0}" = "1" ]; then
  log "SKIP_INSTALLER=1 — not building the installer"
else
  ISCC="${ISCC:-C:/Program Files (x86)/Inno Setup 6/ISCC.exe}"
  if [ ! -f "$ISCC" ]; then
    log "Inno Setup not found — installing via choco"
    choco install innosetup -y --no-progress
  fi
  log "Building installer $SETUP"
  # //D, not /D: Git Bash converts a leading-slash argument into a Windows
  # path ("/DAppVersion=…" became "C:/Program Files/Git/DAppVersion=…"),
  # which ISCC reads as a SECOND script filename and refuses:
  #   You may not specify more than one script filename.
  # // collapses to a single slash because the remainder is slash-free — the
  # same convention as windows_natives.sh's MSVC calls.
  "$ISCC" "//DAppVersion=$VERSION" "windows/installer/control_center.iss"
  [ -f "$SETUP" ] || die "ISCC produced no $SETUP"

  # 4b. Authenticode signing — inside the script, like macOS signs inside
  # macos_package.sh. Optional by design: without a cert the installer ships
  # unsigned and SmartScreen warns (documented in RELEASING.md).
  if [ -n "${WINDOWS_CERT:-}" ]; then
    scratch_dir
    SECRETS_DIR="$SCRATCH_DIR"   # always removed on exit
    printf '%s' "$WINDOWS_CERT" | base64 --decode > "$SECRETS_DIR/cert.pfx"
    log "Authenticode signing $SETUP"
    signtool sign -f "$SECRETS_DIR/cert.pfx" -p "${WINDOWS_CERT_PWD:-}" \
      -tr http://timestamp.digicert.com -td sha256 -fd sha256 "$SETUP"
  else
    warn "No Authenticode cert — installer ships unsigned (SmartScreen will warn)."
  fi
  sha256_sidecar "$SETUP"
fi

# 5. Portable zip of the app directory (exe + DLLs + embedded cc_server), for
# users who want no installer. It is NOT the update payload: WinSparkle applies
# an update by LAUNCHING the enclosure, so the appcast points at the Inno
# setup.exe instead (see gen_appcast.sh).
if [ "${SKIP_ZIP:-0}" = "1" ]; then
  log "SKIP_ZIP=1 — not building the portable zip"
else
  log "Building portable zip $ZIP"
  make_zip "$OUT" "$REPO_ROOT/$ZIP"
  sha256_sidecar "$ZIP"
fi

log "Done: ${SETUP} + ${ZIP}"
