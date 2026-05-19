#!/usr/bin/env bash
#
# Packages the built Linux app into a portable AppImage (+ a raw .tar.gz):
#   1. copies the staged native .so files into the bundle's lib/ (matches the
#      $ORIGIN/lib RPATH + the loaders' <exeDir>/lib candidate),
#   2. tars the raw bundle as a fallback artifact,
#   3. assembles a Type-2 AppDir and runs appimagetool, and
#   4. writes SHA-256 checksums.
#
# Expects `flutter build linux --release` to have run and the native libs to be
# staged in build/natives/ (see scripts/natives/build_natives.sh).
#
# Environment:
#   VERSION   release version, e.g. 1.0.0 (required; or pass as $1)
#   ARCH      AppImage arch tag (default: x86_64)
#
# Usage:
#   VERSION=1.0.0 scripts/release/linux_package.sh
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

VERSION="${1:-${VERSION:?VERSION is required}}"
ARCH="${ARCH:-x86_64}"
RUNNER_TEMP="${RUNNER_TEMP:-$(mktemp -d)}"
NATIVES="${NATIVES:-build/natives}"
BUNDLE="build/linux/x64/release/bundle"
APPIMAGE="Control-Center-${VERSION}-${ARCH}.AppImage"
TARBALL="Control-Center-${VERSION}-linux-x64.tar.gz"

# 1. Bundle native libraries under lib/.
mkdir -p "$BUNDLE/lib"
shopt -s nullglob
for f in "$NATIVES"/*.so; do
  echo "  bundling $(basename "$f")"
  cp -f "$f" "$BUNDLE/lib/"
done
# Tree-sitter `.scm` queries beside the grammar .so libs — GrammarManager
# resolves each language's query from the same dir as its lib (see loadQuery).
for q in "$NATIVES"/*.scm; do
  echo "  bundling $(basename "$q")"
  cp -f "$q" "$BUNDLE/lib/"
done

# 1b. Bundle the cc_server thin-client backend. The desktop spawns it at boot
# (CcServerLauncher resolves <exeDir>/cc_server/bin/cc_server) and talks to it
# over loopback RPC — it owns the database. Build the `dart build cli` bundle if
# absent, copy it beside the exe, and stage the server's native .so deps
# (libccpty for the agent PTY, rift/tree-sitter/…) under the server bundle's
# lib/ so its <exeDir>/lib loader finds them.
CC_SERVER_BUNDLE="apps/cc_server/build/cli/linux_x64/bundle"
if [ ! -x "$CC_SERVER_BUNDLE/bin/cc_server" ]; then
  echo "==> Building cc_server cli bundle"
  DART_BIN="$REPO_ROOT/.fvm/flutter_sdk/bin/dart"
  [ -x "$DART_BIN" ] || DART_BIN="$(command -v dart)"
  ( cd apps/cc_server && "$DART_BIN" build cli )
fi
echo "  bundling cc_server backend"
rm -rf "$BUNDLE/cc_server"
mkdir -p "$BUNDLE/cc_server/lib"
cp -r "$CC_SERVER_BUNDLE/." "$BUNDLE/cc_server/"
for f in "$NATIVES"/*.so; do
  cp -f "$f" "$BUNDLE/cc_server/lib/"
done
for q in "$NATIVES"/*.scm; do
  cp -f "$q" "$BUNDLE/cc_server/lib/"
done

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

curl -fsSL -o "$RUNNER_TEMP/appimagetool" \
  https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage
chmod +x "$RUNNER_TEMP/appimagetool"
ARCH="$ARCH" "$RUNNER_TEMP/appimagetool" --appimage-extract-and-run "$APPDIR" "$APPIMAGE"
test -f "$APPIMAGE"

# 4. Checksums.
for f in "$APPIMAGE" "$TARBALL"; do
  sha256sum "$f" | tee "$f.sha256"
done
echo "==> Done: $APPIMAGE + $TARBALL"
