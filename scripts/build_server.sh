#!/usr/bin/env bash
# Build a runnable server bundle, including managed media executables and data.
# Usage: scripts/build_server.sh [cc_server|cc_demo_server] [x64|arm64 (Windows)]
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO_ROOT/scripts/lib/common.sh"
source "$REPO_ROOT/scripts/lib/media.sh"

APP="${1:-cc_server}"
case "$APP" in
  cc_server|cc_demo_server) ;;
  -h|--help)
    printf 'Usage: scripts/build_server.sh [cc_server|cc_demo_server] [x64|arm64 (Windows)]\n'
    exit 0 ;;
  *) die "unknown server '$APP' (expected cc_server|cc_demo_server)" ;;
esac
[ "$#" -le 2 ] || die "too many arguments; use --help"

OS="$(cc_platform)"
ARCH="${2:-}"
if [ "$OS" = windows ]; then
  ARCH="$(cc_windows_arch "${ARCH:-${VSCMD_ARG_TGT_ARCH:-x64}}")"
elif [ -n "$ARCH" ]; then
  die "an architecture argument is only meaningful for Windows"
fi

cd "$REPO_ROOT/apps/$APP"
# Match hook/build.dart's staging-directory selection. Hooks do not receive
# arbitrary environment variables; the repo-root pointer is authoritative.
NATIVES="$REPO_ROOT/build/natives"
if [ -f "$REPO_ROOT/.cc_natives_prebuilt_dir" ]; then
  PREBUILT="$(cat "$REPO_ROOT/.cc_natives_prebuilt_dir")"
  PREBUILT="${PREBUILT#"${PREBUILT%%[![:space:]]*}"}"
  PREBUILT="${PREBUILT%"${PREBUILT##*[![:space:]]}"}"
  [ -z "$PREBUILT" ] || NATIVES="$PREBUILT"
fi

# Fail before Dart deletes the previous CLI output if media was not staged.
[ -d "$NATIVES/media" ] \
  || die "managed media missing in $NATIVES/media; run scripts/natives/build_natives.sh (Windows: scripts/release/windows_natives.sh) first"
cc_media_verify "$NATIVES/media" "$OS" "$ARCH"

DART="$(resolve_dart)"
log "Building $APP CLI bundle ($OS${ARCH:+ $ARCH})"
# shellcheck disable=SC2086  # resolve_dart may return the two-word `fvm dart`.
$DART build cli

BUNDLE="$REPO_ROOT/apps/$APP/build/cli/$(cc_cli_dir "$OS" "$ARCH")/bundle"
# Dart code assets include shared libraries, not subprocess executables, fonts
# or notices. Keep the complete media tree together, just like release bundles.
cc_media_stage "$NATIVES" "$BUNDLE/bin/media" "$OS" "$ARCH"
log "Built $APP → $BUNDLE"
