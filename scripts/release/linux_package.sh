#!/usr/bin/env bash
#
# Packages the Linux desktop app with embedded cc_server + staged natives.
# Verifies REQUIRED natives before archive.
# Usage: scripts/release/linux_package.sh <version>
#
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
ZSYNC="$(release_asset_name appimage-zsync "$VERSION")"
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

# 1d. Legal notices, written into the bundle so BOTH the tarball below and the
# AppDir copied from it carry them.
install -m644 LICENSE "$BUNDLE/LICENSE"
bash scripts/release/gen_third_party_licenses.sh desktop \
  "$BUNDLE/THIRD-PARTY-LICENSES.txt"

# 1e. The libraries a stock desktop may lack, and RUNPATHs that find them: a
# plugin's RUNPATH is the build tree's, so a library beside it is invisible.
# After this and the notices, since it appends the bundled licenses to them.
bash scripts/release/bundle_linux_deps.sh "$BUNDLE"

# 2. Raw tarball (for users who prefer not to use AppImage).
tar czf "$TARBALL" -C "build/linux/x64/release" bundle

# 3. AppDir + AppImage. The bundle stays whole under usr/bin (the desktop finds
# data/, lib/ and cc_server/ beside its executable); usr/share carries the
# freedesktop metadata AppStream and AppImageHub read. The top-level desktop
# entry is named after the app id: appimagetool looks for the AppStream file by
# that name, and `appstreamcli validate-tree` matches the two.
APP_ID="com.alev.control-center"
APPDIR="$RUNNER_TEMP/AppDir"
rm -rf "$APPDIR"; mkdir -p "$APPDIR/usr/bin"
cp -r "$BUNDLE/." "$APPDIR/usr/bin/"
install -Dm644 "linux/$APP_ID.desktop" "$APPDIR/usr/share/applications/$APP_ID.desktop"
install -Dm644 "linux/$APP_ID.desktop" "$APPDIR/$APP_ID.desktop"
for icon in linux/icons/hicolor/*/apps/control_center.*; do
  install -Dm644 "$icon" "$APPDIR/usr/share/${icon#linux/}"
done
install -Dm644 linux/icons/hicolor/256x256/apps/control_center.png "$APPDIR/control_center.png"
mkdir -p "$APPDIR/usr/share/metainfo"
sed -e "s/@VERSION@/$VERSION/" -e "s/@DATE@/$(date -u +%Y-%m-%d)/" \
  "linux/$APP_ID.appdata.xml.in" >"$APPDIR/usr/share/metainfo/$APP_ID.appdata.xml"
cat > "$APPDIR/AppRun" <<'EOF'
#!/bin/sh
HERE="$(dirname "$(readlink -f "$0")")"
exec "$HERE/usr/bin/control_center" "$@"
EOF
chmod +x "$APPDIR/AppRun"

# What AppImageHub tests, checked here where a failure names the file: the
# layout, desktop entry and AppStream metadata, and that every ELF loads on the
# oldest supported Ubuntu LTS with only its stock libraries.
bash scripts/release/lint_appdir.sh "$APPDIR"

# appimagetool is pinned by URL + SHA-256 in scripts/lib/native_pins.env, like
# every other third-party source here. It used to be pulled from the mutable
# `continuous` tag with no checksum, so the tool that assembles the artifact
# could change under a release with no commit in this repo.
fetch_pinned "$APPIMAGETOOL_URL" "$APPIMAGETOOL_SHA256" "$RUNNER_TEMP/appimagetool"
chmod +x "$RUNNER_TEMP/appimagetool"
# Left to itself appimagetool downloads the runtime from type2-runtime's
# `continuous` release; this is the pinned build.
RUNTIME="$RUNNER_TEMP/runtime-$ARCH"
fetch_pinned "$APPIMAGE_RUNTIME_URL" "$APPIMAGE_RUNTIME_SHA256" "$RUNTIME"

# Update information for AppImageUpdate and appimaged: the newest release's
# .zsync. appimagetool embeds it and runs zsyncmake, which writes $ZSYNC here;
# without zsyncmake it only warns, hence the checks.
REPO_SLUG="${GITHUB_REPOSITORY:-SamuelAlev/control-center}"
UPDATE_INFO="gh-releases-zsync|${REPO_SLUG%/*}|${REPO_SLUG#*/}|latest|$(release_asset_name appimage-zsync '*')"
require_cmd zsyncmake "apt-get install zsync"
rm -f "$ZSYNC"

# --no-appstream: lint_appdir.sh validated the metadata offline above.
# appimagetool's own `appstreamcli validate-tree` fetches every screenshot,
# which build-linux's blocked egress turns into warnings and a failed build.
ARCH="$ARCH" "$RUNNER_TEMP/appimagetool" --appimage-extract-and-run --no-appstream \
  --runtime-file "$RUNTIME" --updateinformation "$UPDATE_INFO" \
  "$APPDIR" "$APPIMAGE"
[ -f "$APPIMAGE" ] || die "appimagetool produced no $APPIMAGE"
[ -f "$ZSYNC" ] || die "appimagetool produced no $ZSYNC"

# 4. Checksums.
for f in "$APPIMAGE" "$ZSYNC" "$TARBALL"; do
  sha256_sidecar "$f"
done
log "Done: $APPIMAGE + $ZSYNC + $TARBALL"
