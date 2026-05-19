#!/usr/bin/env bash
#
# Packages the built Linux app into a portable AppImage (+ a raw .tar.gz):
#   1. copies the staged native .so files into the bundle's lib/ (matches the
#      $ORIGIN/lib RPATH + the loaders' <exeDir>/lib candidate),
#   2. tars the raw bundle as a fallback artifact,
#   3. assembles a Type-2 AppDir and runs appimagetool and
#   4. writes SHA-256 checksums.
#
# Expects `flutter build linux --release` to have run and the native libs to be
# staged in build/natives/ (see scripts/natives/build_natives.sh, or the verify
# gate fails).
#
# Environment:
#   VERSION   release version, e.g. 1.0.0 (required; or pass as $1)
#   ARCH      AppImage arch tag (default: x86_64)
#   NATIVES   staged natives dir (default: build/natives)
#
# Usage:
#   VERSION=1.0.0 scripts/release/linux_package.sh
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"
source "$REPO_ROOT/scripts/lib/common.sh"
source "$REPO_ROOT/scripts/lib/artifact_names.sh"
load_native_pins

VERSION="${1:-${VERSION:?VERSION is required}}"
ARCH="${ARCH:-x86_64}"
RUNNER_TEMP="${RUNNER_TEMP:-$(mktemp -d)}"
NATIVES="${NATIVES:-build/natives}"
BUNDLE="build/linux/x64/release/bundle"
APPIMAGE="$(release_asset_name appimage "$VERSION")"
TARBALL="$(release_asset_name linux-tarball "$VERSION")"

# 1. Bundle native libraries (and the tree-sitter .scm queries GrammarManager
# resolves from the same dir) under lib/.
stage_natives "$NATIVES" "$BUNDLE/lib" so

# 1b. Bundle the cc_server thin-client backend. The desktop spawns it at boot
# (CcServerLauncher resolves <exeDir>/cc_server/bin/cc_server) and talks to it
# over loopback RPC — it owns the database. Stage the server's own native deps
# under the server bundle's lib/ so its <exeDir>/lib loader finds them.
#
# Whatever `builtin_credentials.sh inject` wrote is compiled in here, so that
# step has to precede this one (a bundle built earlier is reused as-is).
CC_SERVER_BUNDLE="$(ensure_cc_server_bundle linux)"
log "bundling cc_server backend"
rm -rf "$BUNDLE/cc_server"
mkdir -p "$BUNDLE/cc_server"
cp -r "$CC_SERVER_BUNDLE/." "$BUNDLE/cc_server/"
stage_natives "$NATIVES" "$BUNDLE/cc_server/lib" so

# 1c. Verify both native sets before packaging. Every native is required (there
# is no degraded mode), so a bundle missing one either crashes the desktop's
# meeting recorder or refuses to boot its server — catch it here rather than
# shipping an AppImage that dies on first launch. The matrix lives in
# scripts/lib/natives.sh, pinned to the runtime table by
# test/tooling/native_matrix_test.dart.
bash scripts/release/verify_natives.sh "$BUNDLE/lib" linux desktop
bash scripts/release/verify_natives.sh "$BUNDLE/cc_server/lib" linux server

# 2. Raw tarball (for users who prefer not to use AppImage).
tar czf "$TARBALL" -C "build/linux/x64/release" bundle

# 3. AppDir + AppImage.
APPDIR="$RUNNER_TEMP/AppDir"
rm -rf "$APPDIR"; mkdir -p "$APPDIR/usr/bin"
cp -r "$BUNDLE/." "$APPDIR/usr/bin/"
install -Dm644 linux/icons/hicolor/256x256/apps/control_center.png "$APPDIR/control_center.png"
install -Dm644 linux/com.alev.control-center.desktop "$APPDIR/control_center.desktop"
cat > "$APPDIR/AppRun" <<'EOF'
#!/bin/sh
HERE="$(dirname "$(readlink -f "$0")")"
exec "$HERE/usr/bin/control_center" "$@"
EOF
chmod +x "$APPDIR/AppRun"

# appimagetool is pinned by URL + SHA-256 in scripts/lib/native_pins.env, like
# every other third-party source here. It used to be pulled from the mutable
# `continuous` tag with no checksum, so the tool that assembles the artifact
# could change under a release with no commit in this repo.
fetch_pinned "$APPIMAGETOOL_URL" "$APPIMAGETOOL_SHA256" "$RUNNER_TEMP/appimagetool"
chmod +x "$RUNNER_TEMP/appimagetool"
ARCH="$ARCH" "$RUNNER_TEMP/appimagetool" --appimage-extract-and-run "$APPDIR" "$APPIMAGE"
[ -f "$APPIMAGE" ] || die "appimagetool produced no $APPIMAGE"

# 4. Checksums.
for f in "$APPIMAGE" "$TARBALL"; do
  sha256_sidecar "$f"
done
log "Done: $APPIMAGE + $TARBALL"
