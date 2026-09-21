#!/usr/bin/env bash
#
# Builds libfff_c (fast file finder; REQUIRED). Cargo, pinned upstream.
# Usage: scripts/natives/build_fff.sh [DEST_DIR]
#
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$REPO_ROOT/scripts/natives/lib/natives_common.sh"

# Pins come from scripts/lib/native_pins.env (the only place a SHA lives; an
# env override still wins, for one-off bisects).
load_native_pins

native_detect_platform
require_cmd cargo "Install Rust via https://rustup.rs/ and re-run."

LIB="libfff_c.$NATIVE_EXT"
# Explicit DEST wins (CI staging); otherwise install next to control_center.db.
DEST="${1:-$(native_support_root)}"
log "Installing $LIB into: $DEST"
mkdir -p "$DEST"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
log "Cloning $FFF_REPO @ $FFF_REF"
git_clone_pinned "$FFF_REPO" "$FFF_REF" "$WORK/fff"

log "Building crates/fff-c (release)"
( cd "$WORK/fff/crates/fff-c" && cargo build --release )

BUILT="$WORK/fff/target/release/$LIB"
[ -f "$BUILT" ] || die "expected artifact not found: $BUILT (see cargo output above)"

cp -f "$BUILT" "$DEST/$LIB"
native_adhoc_sign "$DEST/$LIB"

log "Done. Installed:"
ls -la "$DEST/$LIB"
echo "Restart Control Center — FffFileSearch will load fff from $DEST/$LIB."
