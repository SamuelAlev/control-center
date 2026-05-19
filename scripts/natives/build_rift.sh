#!/usr/bin/env bash
#
# Builds the rift FFI shared library (librift_ffi) and installs it where
# RiftFfiBindings looks for it (see core/storage/control_center_paths.dart ->
# riftDylibCandidatePaths):
#   1. the app-support root (next to control_center.db) — the single dev /
#      runtime location and
#   2. an optional explicit DEST ($1) — CI stages the lib there before embedding
#      it into Runner.app/Contents/Frameworks/ (macOS) or bundle/lib/ (Linux).
#
# rift provides the copy-on-write worktree engine (APFS clonefile / reflink) we
# use to isolate repos per conversation without touching the original.
#
# REQUIRED on macOS/Linux: cc_server's boot preflight refuses to start without
# librift_ffi and RiftRepoIsolationAdapter throws rather than silently
# provisioning a `git worktree`, so a missing dylib can never hide as a slower
# working path. `git worktree` remains a legitimate BACKEND for two things that
# are not install failures: a filesystem with no copy-on-write support
# (`cow_unavailable`) and Windows — no MSVC CoW backend exists, so rift is
# deliberately not built there (see scripts/release/windows_natives.sh).
#
# Source/refs (override to iterate or bump; keep RIFT_REF in sync with CI):
#   RIFT_REPO  default github.com/anomalyco/rift
#   RIFT_REF   default v0.0.10 (Renovate-managed; pin a SHA in CI)
#
# Requirements: git, a Rust toolchain (cargo).
#
# Usage:
#   scripts/natives/build_rift.sh [DEST_DIR]
#   RIFT_REF=<sha> scripts/natives/build_rift.sh ./build/natives
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
