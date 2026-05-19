#!/usr/bin/env bash
#
# Runs the Control Center desktop app locally WITH a bundled cc_server backend,
# the same way a packaged release does — so the thin-client local mode works
# from a dev build without depending on the working directory or a hand-built
# `dart build cli` in the source tree.
#
# The desktop is a thin client: at boot it spawns `cc_server` (which owns the
# database) and talks to it over loopback RPC. `CcServerLauncher.resolve` looks
# for the server FIRST beside the app executable:
#   * macOS: <App>.app/Contents/Resources/cc_server/bin/cc_server
#   * Linux: <bundle>/cc_server/bin/cc_server
# and only then falls back to the source tree (`apps/cc_server/build/cli/...`,
# which requires the right CWD). This script builds the server bundle and embeds
# it at that exe-relative location — exactly what scripts/release/{macos,linux}_
# package.sh do — so the local mode resolves the server regardless of CWD.
#
# Prefer the remote mode instead? Just run the app normally and choose
# "Connect to a remote server" on the setup screen — no bundled server needed.
#
# Environment / flags:
#   MODE            debug | profile | release   (default: debug)
#   SKIP_APP_BUILD  1 → reuse the already-built desktop app, only (re)embed
#   REBUILD_SERVER  1 → force a fresh `dart build cli` even if a bundle exists
#   NO_RUN          1 → build + embed only, do not launch the app
#
# Usage:
#   scripts/run_desktop.sh                 # debug build, embed, launch
#   MODE=release scripts/run_desktop.sh    # release build, embed, launch
#   SKIP_APP_BUILD=1 scripts/run_desktop.sh
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

MODE="${MODE:-debug}"
case "$MODE" in
  debug | profile | release) ;;
  *) echo "MODE must be debug|profile|release (got '$MODE')" >&2; exit 2 ;;
esac

# Prefer the repo's fvm-pinned SDK (per CLAUDE.md); fall back to PATH tools.
DART_BIN="$REPO_ROOT/.fvm/flutter_sdk/bin/dart"
FLUTTER_BIN="$REPO_ROOT/.fvm/flutter_sdk/bin/flutter"
[ -x "$DART_BIN" ] || DART_BIN="$(command -v fvm >/dev/null 2>&1 && echo "fvm dart" || command -v dart)"
[ -x "$FLUTTER_BIN" ] || FLUTTER_BIN="$(command -v fvm >/dev/null 2>&1 && echo "fvm flutter" || command -v flutter)"

OS="$(uname -s)"
NATIVES="${NATIVES:-build/natives}"

# 1. Build the cc_server `dart build cli` bundle (Dart-native executable, no
#    Flutter engine). Reused if already present unless REBUILD_SERVER=1.
case "$OS" in
  Darwin) ARCH_DIR="macos_arm64" ;;
  Linux)  ARCH_DIR="linux_x64" ;;
  *) echo "Unsupported OS '$OS' (macOS/Linux only)" >&2; exit 2 ;;
esac
CC_SERVER_BUNDLE="apps/cc_server/build/cli/$ARCH_DIR/bundle"
if [ "${REBUILD_SERVER:-0}" = "1" ] || [ ! -x "$CC_SERVER_BUNDLE/bin/cc_server" ]; then
  echo "==> Building cc_server cli bundle ($ARCH_DIR)"
  ( cd apps/cc_server && $DART_BIN build cli )
fi
[ -x "$CC_SERVER_BUNDLE/bin/cc_server" ] || {
  echo "cc_server bundle missing after build: $CC_SERVER_BUNDLE/bin/cc_server" >&2
  exit 1
}

# 2. Build the desktop app (unless reusing an existing build).
if [ "${SKIP_APP_BUILD:-0}" != "1" ]; then
  echo "==> Building desktop app ($MODE)"
  $FLUTTER_BIN build "$([ "$OS" = Darwin ] && echo macos || echo linux)" "--$MODE"
fi

# 3. Embed the server beside the app executable. The layout MUST match what
#    CcServerLauncher.resolve probes and what the release packagers produce.
if [ "$OS" = "Darwin" ]; then
  MODE_DIR="$(tr '[:lower:]' '[:upper:]' <<<"${MODE:0:1}")${MODE:1}" # Debug/Profile/Release
  APP="$(ls -d "build/macos/Build/Products/$MODE_DIR"/*.app 2>/dev/null | head -1 || true)"
  [ -n "$APP" ] && [ -d "$APP" ] || { echo "No built .app under build/macos/Build/Products/$MODE_DIR" >&2; exit 1; }
  echo "==> Embedding cc_server into $APP"
  rm -rf "$APP/Contents/Resources/cc_server"
  mkdir -p "$APP/Contents/Resources/cc_server/Frameworks"
  cp -R "$CC_SERVER_BUNDLE/." "$APP/Contents/Resources/cc_server/"
  # The server is a SEPARATE executable; stage its native dylibs so its
  # @executable_path/../Frameworks loader finds them (best-effort — present
  # only after scripts/natives/build_natives.sh has staged them).
  shopt -s nullglob
  for f in "$NATIVES"/*.dylib; do cp -f "$f" "$APP/Contents/Resources/cc_server/Frameworks/"; done
  LAUNCH=(open "$APP")
else
  BUNDLE="build/linux/x64/$MODE/bundle"
  [ -d "$BUNDLE" ] || { echo "No built bundle at $BUNDLE" >&2; exit 1; }
  echo "==> Embedding cc_server into $BUNDLE"
  rm -rf "$BUNDLE/cc_server"
  mkdir -p "$BUNDLE/cc_server/lib"
  cp -r "$CC_SERVER_BUNDLE/." "$BUNDLE/cc_server/"
  shopt -s nullglob
  for f in "$NATIVES"/*.so; do cp -f "$f" "$BUNDLE/cc_server/lib/"; done
  # The app binary is the only top-level executable file (shared libs live under
  # lib/, data under data/), so this picks it without hardcoding the app name.
  EXE="$(find "$BUNDLE" -maxdepth 1 -type f -perm -u+x 2>/dev/null | head -1 || true)"
  [ -n "${EXE:-}" ] && [ -x "$EXE" ] || { echo "Could not find the app executable in $BUNDLE" >&2; exit 1; }
  LAUNCH=("$EXE")
fi

if [ "${NO_RUN:-0}" = "1" ]; then
  echo "==> Built and embedded; skipping launch (NO_RUN=1)."
  exit 0
fi
echo "==> Launching: ${LAUNCH[*]}"
exec "${LAUNCH[@]}"
