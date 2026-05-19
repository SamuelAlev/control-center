#!/usr/bin/env bash
#
# Runs the FULL release pipeline for one platform locally, in the order CI runs
# it, and reports which release artifacts came out.
#
# This exists because the procedure used to live in RELEASING.md as prose, and
# the prose was wrong: it omitted a native staging step (so verify_natives.sh,
# which the package scripts call internally, failed on missing onnxruntime and
# sherpa) and gen_build_info.dart (so the artifact self-reported 0.0.1/dev).
# A runnable script cannot drift from itself.
#
# Usage:
#   scripts/release/dry_run.sh [--os macos|linux|windows] [--version X.Y.Z]
#                              [--skip-natives] [--skip-sign]
#
#   --os             default: the host
#   --version        default: 0.0.0-dry
#   --skip-natives   reuse whatever is already staged in build/natives (the slow
#                    part; safe once you have built them at least once)
#   --skip-sign      macOS only — package without Developer ID + notarization.
#                    Refused in CI: see the ALLOW_UNSIGNED guard below.
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"
source "$REPO_ROOT/scripts/lib/common.sh"
source "$REPO_ROOT/scripts/lib/artifact_names.sh"

OS="$(cc_platform)"
VERSION="0.0.0-dry"
SKIP_NATIVES=0
SKIP_SIGN=0
while [ $# -gt 0 ]; do
  case "$1" in
    --os)           OS="${2:?--os needs a value}"; shift 2 ;;
    --version)      VERSION="${2:?--version needs a value}"; shift 2 ;;
    --skip-natives) SKIP_NATIVES=1; shift ;;
    --skip-sign)    SKIP_SIGN=1; shift ;;
    -h|--help)      sed -n '2,22p' "$0"; exit 0 ;;
    *) die "unknown argument '$1' (see --help)" ;;
  esac
done
case "$OS" in macos|linux|windows) ;; *) die "--os must be macos|linux|windows" ;; esac

FLUTTER="$(resolve_flutter)"
DART="$(resolve_dart)"

log "Dry run: $OS $VERSION"

# 1. Natives. One script builds every library the verify gate requires.
if [ "$SKIP_NATIVES" = "1" ]; then
  log "--skip-natives: reusing build/natives"
else
  if [ "$OS" = "windows" ]; then
    bash scripts/release/windows_natives.sh
  else
    bash scripts/natives/build_natives.sh build/natives
  fi
fi

# 2. Built-in credentials, then the build identity stamp. Both must precede any
# build: the credentials are compiled into cc_server as source constants, and
# BuildInfo is compiled into every client.
if [ -n "${CC_BUILTIN_GOOGLE_CLIENT_ID:-}${CC_BUILTIN_KLIPY_APP_KEY:-}" ]; then
  # inject rewrites a TRACKED file; restore it when this script exits however it
  # exits, so a dry run never leaves real credentials in the working tree.
  bash scripts/release/builtin_credentials.sh inject
  trap 'bash scripts/release/builtin_credentials.sh restore' EXIT
fi
# shellcheck disable=SC2086  # `fvm dart` must word-split into two argv entries.
$DART run tool/gen_build_info.dart --version "$VERSION"

# 3. Flutter build.
log "Building the $OS app"
# shellcheck disable=SC2086
$FLUTTER build "$OS" --release --build-name="$VERSION" --build-number=0

# 4. Package the desktop artifact, then the standalone server.
if [ "$SKIP_SIGN" = "1" ]; then
  export ALLOW_UNSIGNED=1
fi
bash "scripts/release/${OS}_package.sh" "$VERSION"
bash scripts/release/cc_server_package.sh "$VERSION" "$OS"

# 5. Report against the canonical name table, so a rename shows up here rather
# than as a missing asset in make_release.sh during a real release.
log "Artifacts produced (expected names from scripts/lib/artifact_names.sh):"
case "$OS" in
  macos)   kinds=(dmg server-macos) ;;
  linux)   kinds=(appimage linux-tarball server-linux) ;;
  windows) kinds=(win-setup win-portable server-windows) ;;
esac
missing=0
for kind in "${kinds[@]}"; do
  name="$(release_asset_name "$kind" "$VERSION")"
  if [ -f "$name" ] || [ -f "dist/$name" ]; then
    printf '  ok      %s\n' "$name"
  else
    printf '  MISSING %s\n' "$name"
    missing=1
  fi
done
[ "$missing" -eq 0 ] || die "the dry run did not produce every expected artifact for $OS"
log "Dry run complete."
