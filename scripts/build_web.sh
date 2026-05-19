#!/usr/bin/env bash
#
# The canonical local web build — what CI actually does, in the order it does it.
#
# It used to be one line (`flutter build web --release --wasm`) claiming to be
# "the canonical local build command so local verification matches CI", while
# deploy-webapp.yml additionally stamped the build identity, regenerated the Web
# Workers, wrote deploy.json and enforced the asset budget. Three of four steps
# were missing, so a local build could not reproduce a deploy — the exact drift
# the claim was there to prevent.
#
# A Wasm build carries SkWasm for modern browsers and the generated CanvasKit
# JavaScript fallback for browsers without WasmGC.
#
# Usage:
#   scripts/build_web.sh                      # the root web client
#   scripts/build_web.sh --target remote      # the phone PWA (apps/cc_remote)
#   scripts/build_web.sh --target gallery     # the design-system gallery
#   scripts/build_web.sh -- --dump-info       # extra args go to `flutter build`
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"
source "$REPO_ROOT/scripts/lib/common.sh"

TARGET=client
while [ $# -gt 0 ]; do
  case "$1" in
    --target) TARGET="${2:?--target needs a value}"; shift 2 ;;
    --) shift; break ;;
    -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
    *) break ;;
  esac
done

case "$TARGET" in
  client)  DIR="." ;;
  remote)  DIR="apps/cc_remote" ;;
  gallery) DIR="apps/cc_gallery" ;;
  *) die "--target must be client|remote|gallery (got '$TARGET')" ;;
esac

FLUTTER="$(resolve_flutter)"
DART="$(resolve_dart)"

# 1. Build identity. Compiled in as BuildInfo and the source deploy.json quotes.
# shellcheck disable=SC2086  # `fvm dart` must word-split into two argv entries.
$DART run tool/gen_build_info.dart

# 2. Web Workers. Only the root app has annotated workers; regenerating
# guarantees the shipped bundle carries current off-main-thread web/*.js.
if [ "$TARGET" = "client" ]; then
  ./tool/gen_workers.sh
fi

# 3. The build itself.
# shellcheck disable=SC2086
( cd "$DIR" && $FLUTTER build web --release --wasm "$@" )

BUILD_DIR="$DIR/build/web"

# 4. The deploy manifest the clients poll to offer a consent-driven refresh.
# deploy.json, NOT version.json: `flutter build web` writes its own
# build/web/version.json (app_name/build_number, no git sha).
# shellcheck disable=SC2086
$DART run tool/gen_deploy_manifest.dart "$BUILD_DIR"

# 5. The same per-file ceiling the deploy workflows enforce.
assert_asset_budget "$BUILD_DIR" 24

log "Built $TARGET → $BUILD_DIR"
