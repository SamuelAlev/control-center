#!/usr/bin/env bash
#
# Builds the Flutter web client and stamps deploy.json.
# Usage: scripts/build_web.sh
#
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

# 2. Generate the target's web build inputs.
if [ "$TARGET" = "client" ]; then
  ./tool/gen_workers.sh
elif [ "$TARGET" = "gallery" ]; then
  # shellcheck disable=SC2086
  ( cd "$DIR" && $DART run build_runner build )
fi

# 3. Honor deferred grammar packs in Wasm as well as the JavaScript fallback.
# shellcheck disable=SC2086
( cd "$DIR" && $FLUTTER build web --release --wasm --enable-wasm-deferred-loading "$@" )

BUILD_DIR="$DIR/build/web"
if [ "$TARGET" = "client" ] || [ "$TARGET" = "remote" ]; then
  node tool/stage_resource_assets.mjs "$BUILD_DIR"
fi

# 4. The deploy manifest the clients poll to offer a consent-driven refresh.
# deploy.json, NOT version.json: `flutter build web` writes its own
# build/web/version.json (app_name/build_number, no git sha).
# shellcheck disable=SC2086
$DART run tool/gen_deploy_manifest.dart "$BUILD_DIR"

# 5. The same per-file ceiling the deploy workflows enforce.
assert_asset_budget "$BUILD_DIR" 24

log "Built $TARGET → $BUILD_DIR"
