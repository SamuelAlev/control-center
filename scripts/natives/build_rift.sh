#!/usr/bin/env bash
#
# Builds librift_ffi (CoW worktrees; REQUIRED off Windows). Cargo first-party.
# Usage: scripts/natives/build_rift.sh [DEST_DIR]
#
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$REPO_ROOT/scripts/natives/lib/natives_common.sh"

# Pins come from scripts/lib/native_pins.env (the only place a SHA lives; an
# env override still wins, for one-off bisects).
load_native_pins
DEST="${1:-}"

native_detect_platform
require_cmd cargo "Install Rust via https://rustup.rs/ and re-run."

LIB="librift_ffi.$NATIVE_EXT"

# Shallow-clone the pinned commit into a temp dir.
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
log "Cloning $RIFT_REPO @ $RIFT_REF"
git_clone_pinned "$RIFT_REPO" "$RIFT_REF" "$WORK/rift"
[ -f "$WORK/rift/crates/ffi/Cargo.toml" ] \
  || die "rift FFI crate not found at: $WORK/rift/crates/ffi/Cargo.toml"

log "Building rift-ffi (release)"
( cd "$WORK/rift" && cargo build --release -p rift-ffi --locked )

BUILT="$WORK/rift/target/release/$LIB"
[ -f "$BUILT" ] || die "expected built library not found: $BUILT"

# Install to: the app-support root (the single dev / runtime location) and the
# optional explicit DEST (CI staging — the macOS/Linux release packaging copies
# it from there into the app bundle). No repo-local macos/Frameworks copy.
dests=("$(native_support_root)")
[ -n "$DEST" ] && dests+=("$DEST")

for d in "${dests[@]}"; do
  mkdir -p "$d"
  cp -f "$BUILT" "$d/$LIB"
  native_adhoc_sign "$d/$LIB"
  echo "  - $d/$LIB"
done

log "Done. Installed $LIB to ${#dests[@]} location(s)."
