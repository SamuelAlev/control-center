#!/usr/bin/env bash
#
# Packages the Windows desktop app (Inno + portable zip) with embedded
# cc_server and staged natives. Verifies REQUIRED natives before archive.
# Usage: scripts/release/windows_package.sh <version>
#
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

# 3b. Legal notices beside the executable, so both the installer (which copies
# this tree) and the portable zip carry them.
install -m644 LICENSE "$OUT/LICENSE"
bash scripts/release/gen_third_party_licenses.sh desktop \
  "$OUT/THIRD-PARTY-LICENSES.txt"

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
