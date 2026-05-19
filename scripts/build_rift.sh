#!/usr/bin/env bash
#
# Builds the rift FFI shared library (librift_ffi) and installs it where
# RiftFfiBindings looks for it (see core/storage/control_center_paths.dart ->
# riftDylibCandidatePaths):
#   1. the app-support root (next to control_center.db) — runtime / local dev,
#   2. macos/Frameworks/ in this repo — the macOS `flutter run` dev candidate, and
#   3. an optional explicit DEST ($1) — CI stages the lib there before embedding
#      it into Runner.app/Contents/Frameworks/ (macOS) or bundle/lib/ (Linux).
#
# rift provides the copy-on-write worktree engine (APFS clonefile / reflink) we
# use to isolate repos per conversation without touching the original. The app
# degrades gracefully to plain `git worktree` (RiftRepoIsolationAdapter) when
# the native lib is absent. rift is skipped on Windows (no MSVC CoW backend).
#
# Source/refs (override to iterate or bump; keep RIFT_REF in sync with CI):
#   RIFT_REPO  default github.com/anomalyco/rift
#   RIFT_REF   default v0.0.10 (Renovate-managed; pin a SHA in CI)
#
# Requirements: git, a Rust toolchain (cargo).
#
# Usage:
#   scripts/build_rift.sh [DEST_DIR]
#   RIFT_REF=<sha> scripts/build_rift.sh ./build/natives
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO_ROOT/scripts/lib/natives_common.sh"

RIFT_REPO="${RIFT_REPO:-https://github.com/anomalyco/rift.git}"
RIFT_REF="${RIFT_REF:-18ca9d199cfa0033e1adf63b1eb6625fab89478a}" # v0.0.10 (Renovate-managed)
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

# Install to: app-support (runtime / local dev), the repo's macos/Frameworks/
# (the macOS dev candidate), and the optional explicit DEST (CI staging).
dests=("$(native_support_root)")
[ "$NATIVE_OS" = "Darwin" ] && dests+=("$REPO_ROOT/macos/Frameworks")
[ -n "$DEST" ] && dests+=("$DEST")

for d in "${dests[@]}"; do
  mkdir -p "$d"
  cp -f "$BUILT" "$d/$LIB"
  native_adhoc_sign "$d/$LIB"
  echo "  - $d/$LIB"
done

log "Done. Installed $LIB to ${#dests[@]} location(s)."
