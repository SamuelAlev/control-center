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
# it at that exe-relative location — the same `ensure_cc_server_bundle` +
# `stage_natives` pair scripts/release/{macos,linux}_package.sh use — so the
# local mode resolves the server regardless of CWD.
#
# Prefer the remote mode instead? Just run the app normally and choose
# "Connect to a remote server" on the setup screen — no bundled server needed.
#
# Environment / flags:
#   MODE            debug | profile | release   (default: debug)
#   SKIP_APP_BUILD  1 → reuse the already-built desktop app, only (re)embed
#   REBUILD_SERVER  1 → force a fresh `dart build cli` even if a bundle exists
#   NO_RUN          1 → build + embed only, do not launch the app
#   SKIP_VERIFY     1 → skip the required-natives gate (a partial dev tree)
#   NATIVES         staged natives dir (default: build/natives)
#
# Usage:
#   scripts/run_desktop.sh                 # debug build, embed, launch
#   MODE=release scripts/run_desktop.sh    # release build, embed, launch
#   SKIP_APP_BUILD=1 scripts/run_desktop.sh
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"
source "$REPO_ROOT/scripts/lib/common.sh"

MODE="${MODE:-debug}"
case "$MODE" in
  debug | profile | release) ;;
  *) die "MODE must be debug|profile|release (got '$MODE')" ;;
esac

FLUTTER_BIN="$(resolve_flutter)"
OS="$(cc_platform)"
NATIVES="${NATIVES:-build/natives}"
case "$OS" in
  macos|linux) ;;
  *) die "run_desktop.sh supports macOS and Linux only (got $OS)." ;;
esac

# 1. Build the cc_server `dart build cli` bundle (Dart-native executable, no
#    Flutter engine). Reused if already present unless REBUILD_SERVER=1.
if [ "${REBUILD_SERVER:-0}" = "1" ]; then
  rm -rf "apps/cc_server/build/cli/$(cc_cli_dir "$OS")/bundle"
fi
CC_SERVER_BUNDLE="$(ensure_cc_server_bundle "$OS")"

# 2. Build the desktop app (unless reusing an existing build).
if [ "${SKIP_APP_BUILD:-0}" != "1" ]; then
  log "Building desktop app ($MODE)"
  # shellcheck disable=SC2086  # `fvm flutter` must word-split into two argv entries.
  $FLUTTER_BIN build "$OS" "--$MODE"
fi

# 3. Embed the server beside the app executable. The layout MUST match what
#    CcServerLauncher.resolve probes and what the release packagers produce.
#
# stage_natives (rather than the hand-rolled dylib loop this used to carry) is
# what keeps that promise honest: it also copies the tree-sitter .scm queries,
# which this script silently omitted, so a local run exercised the compiled-in
# query fallback while a release ran the on-disk files.
if [ "$OS" = "macos" ]; then
  MODE_DIR="$(tr '[:lower:]' '[:upper:]' <<<"${MODE:0:1}")${MODE:1}" # Debug/Profile/Release
  APP="$(ls -d "build/macos/Build/Products/$MODE_DIR"/*.app 2>/dev/null | head -1 || true)"
  [ -n "$APP" ] && [ -d "$APP" ] || die "No built .app under build/macos/Build/Products/$MODE_DIR"
  log "Embedding cc_server into $APP"
  rm -rf "$APP/Contents/Resources/cc_server"
  mkdir -p "$APP/Contents/Resources/cc_server"
  cp -R "$CC_SERVER_BUNDLE/." "$APP/Contents/Resources/cc_server/"
  SERVER_LIBS="$APP/Contents/Resources/cc_server/Frameworks"
  stage_natives "$NATIVES" "$SERVER_LIBS" dylib
  LAUNCH=(open "$APP")
else
  BUNDLE="build/linux/x64/$MODE/bundle"
  [ -d "$BUNDLE" ] || die "No built bundle at $BUNDLE"
  log "Embedding cc_server into $BUNDLE"
  rm -rf "$BUNDLE/cc_server"
  mkdir -p "$BUNDLE/cc_server"
  cp -r "$CC_SERVER_BUNDLE/." "$BUNDLE/cc_server/"
  SERVER_LIBS="$BUNDLE/cc_server/lib"
  stage_natives "$NATIVES" "$SERVER_LIBS" so
  # The app binary is the only top-level executable file (shared libs live under
  # lib/, data under data/), so this picks it without hardcoding the app name.
  EXE="$(find "$BUNDLE" -maxdepth 1 -type f -perm -u+x 2>/dev/null | head -1 || true)"
  [ -n "${EXE:-}" ] && [ -x "$EXE" ] || die "Could not find the app executable in $BUNDLE"
  LAUNCH=("$EXE")
fi

# 4. Same gate the release packagers run. A dev tree that has not staged every
#    native gets the server's boot preflight failure HERE, with the build command
#    to fix it, instead of an app that starts and then drops to an error screen.
if [ "${SKIP_VERIFY:-0}" != "1" ]; then
  bash scripts/release/verify_natives.sh "$SERVER_LIBS" "$OS" server
fi

if [ "${NO_RUN:-0}" = "1" ]; then
  log "Built and embedded; skipping launch (NO_RUN=1)."
  exit 0
fi
log "Launching: ${LAUNCH[*]}"
exec "${LAUNCH[@]}"
